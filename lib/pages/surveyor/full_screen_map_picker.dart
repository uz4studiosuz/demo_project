import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:remixicon/remixicon.dart';
import '../../additional/map_border.dart';
import '../../theme/colors.dart';

class FullScreenMapPicker extends StatefulWidget {
  final LatLng initialPosition;

  const FullScreenMapPicker({super.key, required this.initialPosition});

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  late LatLng _currentPosition;
  final MapController _mapController = MapController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

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
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newLatLng;
        _mapController.move(newLatLng, 17);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Joylashuvni tanlang'),
        backgroundColor: AppColors.surface,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 20.0,
              minZoom: 5,
              maxZoom: 22,
              onPositionChanged: (position, hasGesture) {
                constrainMap(position, _mapController);
                if (hasGesture) {
                  _currentPosition = position.center;
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.demoproject',
                maxZoom: 22,
                tileProvider: CachedTileProvider(
                  store: FileCacheStore(
                    "${Directory.systemTemp.path}/map_tiles_cache",
                  ),
                ),
              ),
              if (kShowMapBorder)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: kFerganaBorder,
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      strokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),
          Center(
            child: Icon(Remix.focus_3_line, size: 40, color: AppColors.error),
          ),
          // Hint Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Haritani maksimal yaqinlashtirib, o\'rtadagi qizil nuqtani xonadon ustiga aniq olib keling va joylashuvni tasdiqlang. (Xonadon manzili aniq belgilanganiga ishonch hosil qiling)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'my_location_btn_full',
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              onPressed: () {
                Navigator.pop(context, _currentPosition);
              },
              child: const Text(
                'Joylashuvni tasdiqlash',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
