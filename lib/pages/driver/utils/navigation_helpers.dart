import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/colors.dart';
import '../driver_map_page.dart';
import 'smooth_anim.dart';

// ─── PURE HELPERS (Top-level) ───────────────────────────────────

String translateManeuver(String type, String modifier) {
  if (type == 'turn') {
    if (modifier.contains('left')) return 'Chapga buriling';
    if (modifier.contains('right')) return 'O\'ngga buriling';
    if (modifier == 'uturn') return 'Orqaga qayting';
  } else if (type == 'new name' || type == 'continue') {
    return 'To\'g\'riga davom eting';
  } else if (type == 'merge') {
    return 'Qo\'shiling';
  } else if (type == 'roundabout') {
    return 'Aylanmadan harakatlaning';
  } else if (type == 'arrive') {
    return 'Manzilga yetib keldingiz';
  } else if (type == 'depart') {
    return 'Harakatni boshlang';
  } else if (type == 'fork') {
    if (modifier.contains('left')) return 'Chapga ajraling';
    if (modifier.contains('right')) return 'O\'ngga ajraling';
  } else if (type == 'end of road') {
    if (modifier.contains('left')) return 'Chapga buriling';
    if (modifier.contains('right')) return 'O\'ngga buriling';
  }
  return 'To\'g\'riga davom eting';
}

IconData getStepIcon(String type, String modifier) {
  if (type == 'arrive') return Icons.flag_rounded;
  if (type == 'depart') return Icons.play_arrow_rounded;
  if (modifier.contains('slight left')) return Icons.turn_slight_left;
  if (modifier.contains('slight right')) return Icons.turn_slight_right;
  if (modifier.contains('sharp left')) return Icons.turn_sharp_left;
  if (modifier.contains('sharp right')) return Icons.turn_sharp_right;
  if (modifier.contains('left')) return Icons.turn_left;
  if (modifier.contains('right')) return Icons.turn_right;
  if (modifier == 'uturn') return Icons.u_turn_left;
  if (type == 'roundabout') return Icons.roundabout_right;
  if (type == 'fork') return Icons.call_split;
  if (type == 'merge') return Icons.call_merge;
  return Icons.arrow_upward_rounded;
}

String formatDistance(num meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${meters.round()} m';
}

// ─── MIXIN FOR STATE-DEPENDENT LOGIC ─────────────────────────────

mixin NavigationHelpersMixin on State<DriverMapPage>, SmoothMapAnimationMixin<DriverMapPage> {
  // We expect these to be either provided by the mixin or the class
  // Accessing MapController usually from the class
  
  // Navigation State
  bool isNavigationStarted = false;
  bool followUser = true;
  List<LatLng> routePoints = [];
  List<List<LatLng>> alternativeRoutes = [];
  List<dynamic> turnSteps = [];
  bool isRouteLoading = false;
  String distance = '';
  String duration = '';

  // Calculation helpers
  double latLngDistance(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  double bearingBetween(LatLng a, LatLng b) {
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double calcRouteHeading(double rawHeading) {
    if (routePoints.length < 2 || displayPosition == null) return rawHeading;
    int nearestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < routePoints.length; i++) {
      final d = latLngDistance(displayPosition!, routePoints[i]);
      if (d < minDist) {
        minDist = d;
        nearestIdx = i;
      }
    }
    final nextIdx = (nearestIdx + 1).clamp(0, routePoints.length - 1);
    if (nearestIdx == nextIdx) return rawHeading;
    return bearingBetween(routePoints[nearestIdx], routePoints[nextIdx]);
  }

  void centerOnRoute({
    required MapController mapController,
    required bool isMapReady,
    required LatLng destination,
  }) {
    if (!isMapReady) return;
    if (routePoints.isEmpty && displayPosition == null) return;
    final points = routePoints.isNotEmpty ? routePoints : [displayPosition!, destination];
    final bounds = LatLngBounds.fromPoints(points);
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 80, left: 40, right: 40, bottom: 180),
      ),
    );
  }

  void startNavigation({
    required MapController mapController,
    required bool isMapReady,
    required double rawHeading,
    required Function(double) onHeadingUpdate,
  }) {
    final routeHeading = calcRouteHeading(rawHeading);
    onHeadingUpdate(routeHeading); // Update current rawHeading in state
    displayHeading = routeHeading;

    setState(() {
      isNavigationStarted = true;
      followUser = true;
    });
    if (displayPosition != null && isMapReady) {
      mapController.move(displayPosition!, 18.0);
      mapController.rotate(-routeHeading);
      displayMapRotation = -routeHeading;
    }
  }

  void stopNavigation({
    required MapController mapController,
    required bool isMapReady,
    required LatLng destination,
  }) {
    setState(() {
      isNavigationStarted = false;
      followUser = true;
      displayMapRotation = 0;
    });
    if (isMapReady) {
      mapController.rotate(0);
      if (routePoints.isNotEmpty) {
        centerOnRoute(mapController: mapController, isMapReady: isMapReady, destination: destination);
      }
    }
  }

  void focusOnUser({
    required MapController mapController,
    required bool isMapReady,
    required double rawHeading,
  }) {
    setState(() => followUser = true);
    if (displayPosition != null && isMapReady) {
      mapController.move(displayPosition!, 18.0);
      if (isNavigationStarted) {
        mapController.rotate(-rawHeading);
        displayMapRotation = -rawHeading;
      }
    }
  }

  void showExternalMaps(BuildContext context, LatLng destination) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tashqi ilovada ochish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.danger),
              title: const Text('Google Karta'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.amber),
              title: const Text('Yandex Navigator'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('yandexnavi://build_route_on_map?lat_to=${destination.latitude}&lon_to=${destination.longitude}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  final fallbackUrl = Uri.parse('https://yandex.com/maps/?rtext=~${destination.latitude},${destination.longitude}');
                  if (await canLaunchUrl(fallbackUrl)) await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
