import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = widget.initialPosition;
  }

  @override
  void didUpdateWidget(MapPreviewPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != oldWidget.initialPosition) {
      _currentPosition = widget.initialPosition;
      _mapController.move(_currentPosition, 16);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }


  Future<void> _openFullScreenMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenMapPicker(initialPosition: _currentPosition),
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
      mainAxisSize: MainAxisSize.min,
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
          height: 160,
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.pin_fill,
                        size: 38,
                        color: Colors.white,
                      ),
                      Icon(
                        CupertinoIcons.pin_fill,
                        size: 35,
                        color: AppColors.danger,
                      ),
                    ],
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
