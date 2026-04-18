import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/household_model.dart';

class HouseholdsMapViewModel extends ChangeNotifier {
  String _mapType = 'y';
  String get mapType => _mapType;

  bool _isLocationLoading = false;
  bool get isLocationLoading => _isLocationLoading;

  double _currentZoom = 13.0;
  double get currentZoom => _currentZoom;

  HouseholdModel? _focusedHousehold;
  HouseholdModel? get focusedHousehold => _focusedHousehold;

  bool _mapReady = false;
  bool get mapReady => _mapReady;

  bool _isTransitioning = true;
  bool get isTransitioning => _isTransitioning;

  void init(HouseholdModel? focusHousehold) {
    if (focusHousehold != null) {
      _focusedHousehold = focusHousehold;
      _currentZoom = 17.0;
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      _isTransitioning = false;
      notifyListeners();
    });
  }

  void setMapReady() {
    _mapReady = true;
    notifyListeners();
  }

  void updateZoom(double newZoom) {
    if ((newZoom - _currentZoom).abs() > 0.4) {
      _currentZoom = newZoom;
      notifyListeners();
    }
  }

  void toggleMapType() {
    _mapType = _mapType == 'y'
        ? 'm'
        : _mapType == 'm'
        ? 's'
        : 'y';
    notifyListeners();
  }

  Future<LatLng?> getMyLocation(BuildContext context) async {
    _isLocationLoading = true;
    notifyListeners();

    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')),
          );
        }
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuvga ruxsat berilmadi')),
          );
        }
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
      return null;
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Map<String, List<HouseholdModel>> byDistrict(List<HouseholdModel> all) {
    final m = <String, List<HouseholdModel>>{};
    for (final h in all) {
      m.putIfAbsent(h.tumanName ?? 'Noma\'lum', () => []).add(h);
    }
    return m;
  }

  Map<String, List<HouseholdModel>> byMFY(List<HouseholdModel> all) {
    final m = <String, List<HouseholdModel>>{};
    for (final h in all) {
      m.putIfAbsent(h.mfyName ?? 'Noma\'lum MFY', () => []).add(h);
    }
    return m;
  }

  Map<String, List<HouseholdModel>> byStreet(List<HouseholdModel> all) {
    final m = <String, List<HouseholdModel>>{};
    for (final h in all) {
      m.putIfAbsent(h.streetName ?? 'Noma\'lum ko\'cha', () => []).add(h);
    }
    return m;
  }

  LatLng getCenter(List<HouseholdModel> list) {
    if (list.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final h in list) {
      lat += h.latitude;
      lng += h.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }

  Map<String, List<HouseholdModel>> buildingGroups(List<HouseholdModel> all) {
    final map = <String, List<HouseholdModel>>{};
    for (final h in all) {
      if (h.propertyType != kApartment) continue;
      final key = '${h.buildingNumber ?? "?"}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
      map.putIfAbsent(key, () => []).add(h);
    }
    return map;
  }
}
