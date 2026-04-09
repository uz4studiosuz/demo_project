import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _currentPosition);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 16.0,
              minZoom: 5,
              maxZoom: 18,
              onPositionChanged: (position, hasGesture) {
                _constrainMap(position);
                if (hasGesture) {
                  _currentPosition = position.center;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.demoproject',
                maxZoom: 20,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _ferganaBorder,
                    color: Colors.redAccent,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_pin, size: 50, color: Colors.pink),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              onPressed: _isLoading ? null : _getCurrentLocation,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context, _currentPosition);
              },
              child: const Text('Joylashuvni tasdiqlash'),
            ),
          ),
        ],
      ),
    );
  }

  // Farg'ona viloyati aniq chegaralari (Google Maps asosida o'lchangan)
  final List<LatLng> _ferganaBorder = const [
    LatLng(40.612, 70.435), // Beshariq West
    LatLng(40.678, 70.618), // Beshariq North
    LatLng(40.732, 70.825), // Dangara North
    LatLng(40.781, 71.014), // Buvayda North
    LatLng(40.854, 71.218), // Yazyavan North-West
    LatLng(40.902, 71.450), // Yazyavan North
    LatLng(40.835, 71.720), // Quva North-West
    LatLng(40.755, 71.950), // Quva North
    LatLng(40.686, 72.185), // Quva East
    LatLng(40.551, 72.368), // Quvasoy East
    LatLng(40.415, 72.215), // Quvasoy South
    LatLng(40.292, 71.954), // Farg'ona South-East
    LatLng(40.150, 71.850), // Vadil East
    LatLng(39.954, 71.848), // Shoximardon East
    LatLng(39.851, 71.745), // Shoximardon South
    LatLng(39.945, 71.650), // Shoximardon West
    LatLng(40.114, 71.642), // Vadil West
    LatLng(40.155, 71.450), // Rishton South-East
    LatLng(40.245, 71.285), // Rishton South
    LatLng(40.285, 71.120), // Bagdod South
    LatLng(40.315, 70.950), // Uchkuprik South
    LatLng(40.355, 70.785), // Yaypan South
    LatLng(40.415, 70.655), // Yaypan West
    LatLng(40.455, 70.515), // Beshariq South
    LatLng(40.525, 70.420), // Beshariq South-West
    LatLng(40.612, 70.435), // Close loop
  ];

  void _constrainMap(MapCamera camera) {
    if (_ferganaBorder.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_ferganaBorder);
    if (!bounds.contains(camera.center)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(
              const LatLng(40.3864, 71.7825), _mapController.camera.zoom);
        } catch (e) {
          debugPrint("Move error: $e");
        }
      });
    }
  }
}
