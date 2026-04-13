import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/colors.dart';
import '../../../additional/map_border.dart';
import '../full_screen_map_picker.dart';

class MapPreviewPicker extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng position) onPositionChanged;

  const MapPreviewPicker({
    super.key,
    required this.initialPosition,
    required this.onPositionChanged,
  });

  @override
  State<MapPreviewPicker> createState() => _MapPreviewPickerState();
}

class _MapPreviewPickerState extends State<MapPreviewPicker> {
  late final MapController _mapController;
  late LatLng _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentPosition, 16);
      });
      widget.onPositionChanged(_currentPosition);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _openFullScreenMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPicker(
          initialPosition: _currentPosition,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentPosition = result;
        _mapController.move(_currentPosition, 16);
      });
      widget.onPositionChanged(_currentPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Xaritadagi joy',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            TextButton.icon(
              onPressed: _openFullScreenMap,
              icon: const Icon(Icons.fullscreen, size: 20),
              label: const Text('To\'liq ekran'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 14.0,
                    minZoom: 5,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      // Prevyu holatda qulflangan
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                      userAgentPackageName: 'com.example.demoproject',
                      maxZoom: 20,
                    ),
                    if (kShowMapBorder)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: kFerganaBorder,
                            color: Colors.redAccent,
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                  ],
                ),
                GestureDetector(
                  // Xaritaga tekkanda ham to'liq ekranni ochib yuborish
                  onTap: _openFullScreenMap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
                const Center(
                  child: Icon(
                    Icons.location_pin,
                    size: 30,
                    color: AppColors.danger,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'dashboard_location_btn',
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
