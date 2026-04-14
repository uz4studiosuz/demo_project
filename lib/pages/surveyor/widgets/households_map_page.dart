import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../additional/map_border.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/household_info_sheet.dart';
import 'building_bottom_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  HouseholdsMapPage — Public wrapper (ro'yxatdan ham chaqiriladi)
// ═══════════════════════════════════════════════════════════════════════════

class HouseholdsMapPage extends StatelessWidget {
  final HouseholdModel? focusHousehold;
  const HouseholdsMapPage({super.key, this.focusHousehold});

  @override
  Widget build(BuildContext context) {
    return _HouseholdsMapPage(focusHousehold: focusHousehold);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _HouseholdsMapPage — Smart zoom-based rendering
//  zoom < 11  → Tuman aggregate badges
//  zoom 11-13 → MarkerCluster
//  zoom >= 14 → Individual house markers / Building markers (grouped apartments)
// ═══════════════════════════════════════════════════════════════════════════

class _HouseholdsMapPage extends StatefulWidget {
  /// Agar null bo'lmasa, xarita shu uyga fokus qiladi
  final HouseholdModel? focusHousehold;
  const _HouseholdsMapPage({this.focusHousehold});

  @override
  State<_HouseholdsMapPage> createState() => _HouseholdsMapPageState();
}

class _HouseholdsMapPageState extends State<_HouseholdsMapPage> {
  final MapController _mapController = MapController();
  String _mapType = 'y';
  bool _isLocationLoading = false;
  double _currentZoom = 13.0;
  HouseholdModel? _focusedHousehold;
  bool _mapReady = false;
  bool _isTransitioning = true;

  @override
  void initState() {
    super.initState();
    // Sahifa o'tish animatsiyasi stutterni oldini olish uchun delay
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isTransitioning = false);
    });

    if (widget.focusHousehold != null) {
      _focusedHousehold = widget.focusHousehold;
      _currentZoom = 17.0;
    }
  }

  void _toggleMapType() => setState(() {
        _mapType = _mapType == 'y'
            ? 'm'
            : _mapType == 'm'
                ? 's'
                : 'y';
      });

  Future<void> _goToMyLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuvga ruxsat berilmadi')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // Tuman bo'yicha guruhlash
  Map<String, List<HouseholdModel>> _byDistrict(List<HouseholdModel> all) {
    final m = <String, List<HouseholdModel>>{};
    for (final h in all) {
      m.putIfAbsent(h.tumanName ?? 'Noma\'lum', () => []).add(h);
    }
    return m;
  }

  // Tuman markazi (o'rtacha)
  LatLng _center(List<HouseholdModel> list) {
    double lat = 0, lng = 0;
    for (final h in list) {
      lat += h.latitude;
      lng += h.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }

  // Ko'p qavatli binolarni guruhlash
  Map<String, List<HouseholdModel>> _buildingGroups(List<HouseholdModel> all) {
    final map = <String, List<HouseholdModel>>{};
    for (final h in all) {
      if (h.propertyType != kApartment) continue;
      final key =
          '${h.buildingNumber ?? "?"}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
      map.putIfAbsent(key, () => []).add(h);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitioning) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: widget.focusHousehold != null
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.govNavy,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppColors.govNavy,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: AppColors.govNavy,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Xarita tayyorlanmoqda...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.govNavy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final households = provider.households;
        final groups = _byDistrict(households);

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _focusedHousehold != null
                      ? LatLng(
                          _focusedHousehold!.latitude,
                          _focusedHousehold!.longitude,
                        )
                      : const LatLng(40.3864, 71.7825),
                  initialZoom: _currentZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: () => setState(() => _mapReady = true),
                  onPositionChanged: (pos, _) {
                    if ((pos.zoom - _currentZoom).abs() > 0.4) {
                      setState(() => _currentZoom = pos.zoom);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=$_mapType&hl=uz&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.example.demoproject',
                    maxZoom: 20,
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

                  // ── ZOOM < 11 → Tuman badge ───────────────────────
                  if (_currentZoom < 11)
                    MarkerLayer(
                      markers: groups.entries.map((e) {
                        final c = _center(e.value);
                        return Marker(
                          point: c,
                          width: 84,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _mapController.move(c, 13),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.govNavy,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.govNavy.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_city,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${e.value.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // ── ZOOM 11–13 → MarkerCluster ────────────────────
                  if (_currentZoom >= 11 && _currentZoom < 14)
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 60,
                        size: const Size(48, 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 14,
                        markers: households
                            .map(
                              (h) => Marker(
                                point: LatLng(h.latitude, h.longitude),
                                width: 36,
                                height: 36,
                                child: GestureDetector(
                                  onTap: () =>
                                      showHouseholdInfoSheet(context, h),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.govNavy,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.home,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        builder: (context, markers) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppColors.govNavy,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.govNavy.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── ZOOM >= 14 → Individual markers ──────────────
                  if (_currentZoom >= 14)
                    MarkerLayer(
                      markers: [
                        // ── 1. Alohida uylar (HOUSE) ──────────────────
                        ...households
                            .where((h) => h.propertyType != kApartment)
                            .map((h) {
                              final isFocused = _focusedHousehold?.id == h.id;
                              return Marker(
                                point: LatLng(h.latitude, h.longitude),
                                width: isFocused ? 60 : 48,
                                height: isFocused ? 66 : 54,
                                child: GestureDetector(
                                  onTap: () =>
                                      showHouseholdInfoSheet(context, h),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFocused
                                              ? const Color(0xFFD32F2F)
                                              : AppColors.govNavy,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          boxShadow: isFocused
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          h.houseNumber ?? '?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isFocused ? 12 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.pin_fill,
                                        color: isFocused
                                            ? const Color(0xFFD32F2F)
                                            : AppColors.govNavy,
                                        size: isFocused ? 34 : 28,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                        // ── 2. Ko'p qavatli binolar (APARTMENT) ──
                        ..._buildingGroups(households).entries.map((entry) {
                          final apartments = entry.value;
                          final first = apartments.first;
                          final point = LatLng(first.latitude, first.longitude);
                          final isFocused = apartments.any(
                            (a) => a.id == _focusedHousehold?.id,
                          );
                          final buildingNum = first.buildingNumber ?? '?';
                          final aptCount = apartments.length;

                          return Marker(
                            point: point,
                            width: 68,
                            height: 70,
                            child: GestureDetector(
                              onTap: () => BuildingBottomSheet.show(
                                context,
                                apartments,
                                onTapApartment: (apt) =>
                                    showHouseholdInfoSheet(context, apt),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFocused
                                          ? const Color(0xFF6A1B9A)
                                          : const Color(0xFF37474F),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: isFocused
                                          ? [
                                              BoxShadow(
                                                color: Colors.purple.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.apartment,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$buildingNum-b • $aptCount kv',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.pin_fill,
                                    color: isFocused
                                        ? const Color(0xFF6A1B9A)
                                        : const Color(0xFF37474F),
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                ],
              ),

              // ── Loading overlay ──────────────────────────────────────
              if (!_mapReady)
                Container(
                  color: const Color(0xFFF5F6F8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.govNavy.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: AppColors.govNavy,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: AppColors.govNavy,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Xarita yuklanmoqda...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.govNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Iltimos kuting',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Top info pill ────────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (widget.focusHousehold != null) ...[
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.govNavy.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.govNavy,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.govNavy,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: widget.focusHousehold != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.focusHousehold!.officialAddress,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${widget.focusHousehold!.residents.length} nafar aholi',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Xaritada ${households.length} ta xonadon',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.govNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentZoom < 11
                                  ? 'Tumanlar'
                                  : _currentZoom < 14
                                  ? 'Klasterlar'
                                  : 'Xonadonlar',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.govNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_type',
                  onPressed: _toggleMapType,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _mapType == 'm' ? Icons.layers_outlined : Icons.layers,
                    color: AppColors.govNavy,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'my_loc',
                  onPressed: _isLocationLoading ? null : _goToMyLocation,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  icon: _isLocationLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.govNavy,
                          ),
                        )
                      : const Icon(Icons.my_location, color: AppColors.govNavy),
                  label: Text(
                    _isLocationLoading ? 'Aniqlanmoqda...' : 'Yaqin hudud',
                    style: const TextStyle(
                      color: AppColors.govNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
