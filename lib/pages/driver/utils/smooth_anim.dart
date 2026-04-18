import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

mixin SmoothMapAnimationMixin<T extends StatefulWidget> on State<T>, TickerProvider {
  // Animation state variables
  LatLng? displayPosition;
  double displayHeading = 0.0;
  double displayMapRotation = 0.0;

  AnimationController? _moveAnimController;
  AnimationController? _headingAnimController;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  Animation<double>? _headingAnim;
  Animation<double>? _mapRotationAnim;

  // Getters that the implementing class must provide if needed elsewhere
  // or we can just make them public in the mixin.

  double _shortestRotation(double from, double to) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void animateToNewPosition({
    required LatLng newPos,
    required double newHeading,
    required MapController mapController,
    required bool followUser,
    required bool isMapReady,
    required bool isNavigationStarted,
  }) {
    if (!mounted) return;

    _moveAnimController?.stop();
    _headingAnimController?.stop();
    _moveAnimController?.dispose();
    _headingAnimController?.dispose();

    final oldPos = displayPosition ?? newPos;
    final oldHeading = displayHeading;
    final oldMapRotation = displayMapRotation;

    // Position Animation — 800ms
    _moveAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _latAnim = Tween<double>(begin: oldPos.latitude, end: newPos.latitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));
    _lngAnim = Tween<double>(begin: oldPos.longitude, end: newPos.longitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));

    // Heading Animation — 500ms
    _headingAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final headingDiff = _shortestRotation(oldHeading, newHeading);
    _headingAnim = Tween<double>(begin: oldHeading, end: oldHeading + headingDiff)
        .animate(CurvedAnimation(parent: _headingAnimController!, curve: Curves.easeOut));

    final targetMapRotation = -newHeading;
    final mapRotDiff = _shortestRotation(oldMapRotation, targetMapRotation);
    _mapRotationAnim = Tween<double>(begin: oldMapRotation, end: oldMapRotation + mapRotDiff)
        .animate(CurvedAnimation(parent: _headingAnimController!, curve: Curves.easeOut));

    _moveAnimController!.addListener(() {
      if (!mounted) return;
      final animatedPos = LatLng(_latAnim!.value, _lngAnim!.value);
      setState(() => displayPosition = animatedPos);
      
      if (followUser && isMapReady) {
        if (isNavigationStarted) {
          // Navigatsiya paytida mashina pastda turishi uchun markazni oldinga suramiz
          final zoom = mapController.camera.zoom;
          final offsetDistance = 160000 / math.pow(2, zoom);
          
          final Distance distance = const Distance();
          final centerPos = distance.offset(animatedPos, offsetDistance, newHeading);
          
          mapController.move(centerPos, zoom);
        } else {
          mapController.move(animatedPos, mapController.camera.zoom);
        }
      }
    });

    _headingAnimController!.addListener(() {
      if (!mounted) return;
      setState(() {
        displayHeading = _headingAnim!.value;
        displayMapRotation = _mapRotationAnim!.value;
      });
      if (followUser && isNavigationStarted && isMapReady) {
        mapController.rotate(_mapRotationAnim!.value);
      }
    });

    _moveAnimController!.forward();
    _headingAnimController!.forward();
  }

  void disposeAnimations() {
    _moveAnimController?.dispose();
    _headingAnimController?.dispose();
  }
}
