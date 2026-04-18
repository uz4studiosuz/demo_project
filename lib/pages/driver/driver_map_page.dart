import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../theme/colors.dart';

import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import 'utils/smooth_anim.dart';
import 'utils/navigation_helpers.dart';

class DriverMapPage extends StatefulWidget {
  final LatLng destination;
  final String addressTitle;
  final HouseholdModel? household;
  final ResidentModel? targetResident;

  const DriverMapPage({
    super.key,
    required this.destination,
    required this.addressTitle,
    this.household,
    this.targetResident,
  });

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage>
    with TickerProviderStateMixin, SmoothMapAnimationMixin<DriverMapPage>, NavigationHelpersMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  bool _isMapReady =
      false; // FlutterMap render bo'lguncha MapController ishlatilmaydi

  // ─── Smooth interpolation ──────────────────────────────────────
  LatLng? _rawPosition;
  double _rawHeading = 0.0;
  // displayPosition, displayHeading, displayMapRotation endi mixin'da

  // ─── Route state & Navigation (endi mixin'da bo'lganlar)
  double _currentSpeed = 0.0;
  bool _isPatientInfoExpanded = false;

  // Stansiyalar (Branches / Punktlar)
  final List<LatLng> _branches = const [
    LatLng(40.380000, 71.780000),
    LatLng(40.385000, 71.775000),
    LatLng(40.370000, 71.790000),
    LatLng(40.382000, 71.785000),
    LatLng(40.375000, 71.770000),
  ];

  // ─── Map layer ─────────────────────────────────────────────────
  String _mapLayer = 'm';

  // ─── Timers ────────────────────────────────────────────────────
  Timer? _routeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOCATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv xizmati yoqilmagan')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv ruxsati rad etilgan.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      final startLatLng = LatLng(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _rawPosition = startLatLng;
          displayPosition = startLatLng;
          _rawHeading = pos.heading;
          displayHeading = pos.heading;
          _isLoading = false;
        });
        _fetchRoute();
      }

      // Real-time GPS stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen(_onPositionUpdate);

      // Har 10 sekundda marshrutni yangilash
      _routeRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (isNavigationStarted && !isRouteLoading) {
          _fetchRoute();
        }
      });
    } catch (e) {
      debugPrint('Location init error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joylashuvni aniqlashda xato: $e')),
        );
      }
    }
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;
    final newPos = LatLng(position.latitude, position.longitude);
    double newHeading = _rawHeading;

    // Tezlik > 1 m/s bo'lganda heading yangilanadi
    if (position.speed > 1.0 &&
        position.heading.isFinite &&
        position.heading != 0.0) {
      newHeading = position.heading;
    } else if (_rawPosition != null) {
      // Emulator uchun yoki past tezlikda harakatlanganda kordinatalar orqali hisoblash
      final dist = latLngDistance(_rawPosition!, newPos);
      if (dist > 0.0000005) {
        // Juda kichik harakatlarda sakrash bo'lmasligi uchun
        newHeading = bearingBetween(_rawPosition!, newPos);
      }
    }

    setState(() {
      _currentSpeed = position.speed; // m/s -> biz keyin x/h ga o'tkazamiz
    });

    if (isNavigationStarted) {
      followUser = true; // Navigatsiya davrida haydovchi markazdan siljimaydi
    }

    _rawPosition = newPos;
    _rawHeading = newHeading;
    animateToNewPosition(
      newPos: newPos,
      newHeading: newHeading,
      mapController: _mapController,
      followUser: followUser,
      isMapReady: _isMapReady,
      isNavigationStarted: isNavigationStarted,
    );

    if (routePoints.isEmpty && !isRouteLoading) {
      _fetchRoute();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ROUTE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchRoute() async {
    final pos = _rawPosition;
    if (pos == null) return;
    setState(() => isRouteLoading = true);

    try {
      final start = '${pos.longitude},${pos.latitude}';
      final end =
          '${widget.destination.longitude},${widget.destination.latitude}';
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson&steps=true&alternatives=true',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final mainRoute = data['routes'][0];
          final List<dynamic> mainCoords = mainRoute['geometry']['coordinates'];
          routePoints = mainCoords.map((c) => LatLng(c[1], c[0])).toList();

          alternativeRoutes = [];
          for (int i = 1; i < data['routes'].length; i++) {
            final altRoute = data['routes'][i];
            final List<dynamic> altCoords = altRoute['geometry']['coordinates'];
            alternativeRoutes.add(
              altCoords.map((c) => LatLng(c[1], c[0])).toList(),
            );
          }

          final distMeters = mainRoute['distance'] ?? 0.0;
          final durSeconds = mainRoute['duration'] ?? 0.0;
          distance = (distMeters / 1000).toStringAsFixed(1);
          duration = (durSeconds / 60).round().toString();

          if (mainRoute['legs'] != null && mainRoute['legs'].isNotEmpty) {
            turnSteps = mainRoute['legs'][0]['steps'] ?? [];
          }

          if (mounted) {
            setState(() {});
            if (!isNavigationStarted) {
              centerOnRoute(
                mapController: _mapController,
                isMapReady: _isMapReady,
                destination: widget.destination,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
    } finally {
      if (mounted) setState(() => isRouteLoading = false);
    }
  }

  // Calculation methods moved to NavigationHelpersMixin

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeRefreshTimer?.cancel();
    disposeAnimations();
    _mapController.dispose();
    super.dispose();
  }


  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: isNavigationStarted
          ? null
          : AppBar(
              title: Text(widget.addressTitle),
              backgroundColor: AppColors.surface,
              elevation: 0,
            ),
      body: (_isLoading || (isRouteLoading && routePoints.isEmpty))
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading
                        ? 'GPS qidirilmoqda...'
                        : 'Marshrut hisoblanmoqda...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // ─── MAP ─────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: displayPosition ?? widget.destination,
                    initialZoom: 17.0,
                    onMapReady: () {
                      _isMapReady = true;
                      if (routePoints.isNotEmpty && !isNavigationStarted) {
                        centerOnRoute(mapController: _mapController, isMapReady: _isMapReady, destination: widget.destination);
                      }
                    },
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && followUser) {
                        if (!isNavigationStarted) {
                          setState(() => followUser = false);
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://mt1.google.com/vt/lyrs=$_mapLayer&hl=uz&x={x}&y={y}&z={z}',
                      userAgentPackageName: 'com.example.demoproject',
                    ),

                    // Route polylines
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          ...alternativeRoutes.map(
                            (alt) => Polyline(
                              points: alt,
                              color: Colors.grey.withValues(alpha: 0.35),
                              strokeWidth: 5.0,
                              strokeJoin: StrokeJoin.round,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Soya (outline)
                          Polyline(
                            points: routePoints,
                            color: const Color(
                              0xFF1A237E,
                            ).withValues(alpha: 0.4),
                            strokeWidth: 12.0,
                            strokeJoin: StrokeJoin.round,
                            strokeCap: StrokeCap.round,
                          ),
                          // Asosiy marshrut (Google-uslub — quyuq ko'k)
                          Polyline(
                            points: routePoints,
                            color: const Color(0xFF1565C0),
                            strokeWidth: 7.0,
                            strokeJoin: StrokeJoin.round,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      )
                    else if (displayPosition != null && isRouteLoading)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [displayPosition!, widget.destination],
                            color: Colors.grey,
                            strokeWidth: 3.0,
                            pattern: StrokePattern.dashed(segments: [10, 10]),
                          ),
                        ],
                      ),

                    // Markers
                    MarkerLayer(
                      markers: [
                        // Punktlar (Branches)
                        ..._branches.map(
                          (b) => Marker(
                            point: b,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        // 🚙 User (Driver) Marker — ko'k dumaloq va yo'nalish belgisi
                        if (displayPosition != null)
                          Marker(
                            point: displayPosition!,
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            rotate:
                                false, // Ekran yuzasiga qulf, harita aylansa ham u "Tepani" (UP) ko'rsataveradi!
                            child: Transform.rotate(
                              // Agar navigatsiya boshlangan bo'lsa (Xarita aylanadi), marker har doim tepani ko'rsatishi u-n 0 gradus kerak.
                              // Chunki xarita uning ostida aylanadi.
                              angle: isNavigationStarted
                                  ? 0
                                  : (displayHeading * math.pi / 180),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Yo'nalishni bildiruvchi kichik pointer (tepaga qarab turadi)
                                  const Positioned(
                                    top: 2,
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Manzil
                        Marker(
                          point: widget.destination,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.danger,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ═══════════════════════════════════════════════════
                //  NAVIGATSIYA UI (Google Maps uslubida)
                // ═══════════════════════════════════════════════════
                if (isNavigationStarted && turnSteps.isNotEmpty) ...[
                  if (turnSteps.length > 1)
                    // ─── YUQORI PANEL: "500 m dan keyin ↰" ─────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFF1B8D5B),
                        padding: EdgeInsets.only(
                          top: topPad + 12,
                          left: 20,
                          right: 20,
                          bottom: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${formatDistance(turnSteps[0]['distance'] ?? 0)} dan keyin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              getStepIcon(
                                turnSteps[1]['maneuver']['type'] ?? '',
                                turnSteps[1]['maneuver']['modifier'] ?? '',
                              ),
                              color: Colors.white,
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Agar faqat bitta step qolgan bo'lsa (manzilga yetib kelish)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFF1B8D5B),
                        padding: EdgeInsets.only(
                          top: topPad + 12,
                          left: 20,
                          right: 20,
                          bottom: 16,
                        ),
                        child: Center(
                          child: Text(
                            translateManeuver(
                              turnSteps[0]['maneuver']['type'] ?? '',
                              turnSteps[0]['maneuver']['modifier'] ?? '',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ─── "Keyin" ko'rsatkich ───────────────────────
                  if (turnSteps.length > 1)
                    Positioned(
                      top: topPad + 86,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF145A3A),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Keyin',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  getStepIcon(
                                    turnSteps[1]['maneuver']['type'] ?? '',
                                    turnSteps[1]['maneuver']['modifier'] ?? '',
                                  ),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                            Text(
                              formatDistance(turnSteps[0]['distance'] ?? 0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── Bemor haqida ma'lumot (Patient info) ───────────
                  if (widget.targetResident != null || widget.household != null)
                    Positioned(
                      top: topPad + (turnSteps.length > 1 ? 144 : 86),
                      left: 12,
                      child: GestureDetector(
                        onTap: () => setState(
                          () =>
                              _isPatientInfoExpanded = !_isPatientInfoExpanded,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isPatientInfoExpanded ? 220 : 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isPatientInfoExpanded
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          widget.targetResident?.gender ==
                                                  'FEMALE'
                                              ? Icons.person_outline
                                              : Icons.person,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget
                                                    .targetResident
                                                    ?.displayFullName ??
                                                'Bemor',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textMain,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(
                                            () =>
                                                _isPatientInfoExpanded = false,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (widget.targetResident?.role != null)
                                      Text(
                                        '${widget.targetResident!.birthDate != null ? "${DateTime.now().year - widget.targetResident!.birthDate!.year} yosh" : ""} • ${widget.targetResident!.role!}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 30,
                                      child: OutlinedButton(
                                        onPressed: _showFamilyMembers,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.05),
                                        ),
                                        child: const Text(
                                          "Oila a'zolarini ko'rish",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.targetResident?.gender == 'FEMALE'
                                          ? Icons.person_outline
                                          : Icons.person,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Bemor',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                ],

                // ─── Meni ko'rsat (fokus) tooltip ───────────────
                if (isNavigationStarted && !followUser)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => focusOnUser(mapController: _mapController, isMapReady: _isMapReady, rawHeading: _rawHeading),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFF1B8D5B),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Meni ko\'rsat',
                                style: TextStyle(
                                  color: Color(0xFF1B8D5B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ─── O'NG TOMON TUGMALAR ─────────────────────────
                Positioned(
                  bottom: isNavigationStarted
                      ? 90
                      : (distance.isNotEmpty ? 155 : 80),
                  right: 12,
                  child: Column(
                    children: [
                      // Tezlik o'lchagich (Speedometer)
                      if (isNavigationStarted)
                        Container(
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (_currentSpeed * 3.6).round().toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    height: 1.0,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'km/h',
                                  style: TextStyle(
                                    fontSize: 9,
                                    height: 1.0,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Kompas
                      if (isNavigationStarted)
                        _buildControlButton(
                          heroTag: 'compass_btn',
                          icon: Transform.rotate(
                            angle: displayMapRotation * math.pi / 180,
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          onTap: () {
                            // Shimolga qarab qo'yish
                            _mapController.rotate(0);
                            setState(() => displayMapRotation = 0);
                          },
                        ),
                      if (isNavigationStarted) const SizedBox(height: 10),

                      // Qatlam
                      _buildControlButton(
                        heroTag: 'layer_toggle',
                        icon: Icon(
                          _mapLayer == 'm'
                              ? Icons.layers
                              : (_mapLayer == 'y'
                                    ? Icons.layers_outlined
                                    : Icons.satellite_alt),
                          color: Colors.black87,
                          size: 22,
                        ),
                        onTap: () {
                          setState(() {
                            if (_mapLayer == 'm') {
                              _mapLayer = 'y';
                            } else if (_mapLayer == 'y') {
                              _mapLayer = 's';
                            } else {
                              _mapLayer = 'm';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Fokus
                      _buildControlButton(
                        heroTag: 'focus_user',
                        icon: Icon(
                          Icons.my_location,
                          color: followUser
                              ? AppColors.primary
                              : Colors.black54,
                          size: 22,
                        ),
                        onTap: () => focusOnUser(mapController: _mapController, isMapReady: _isMapReady, rawHeading: _rawHeading),
                      ),

                      if (isNavigationStarted) ...[
                        const SizedBox(height: 10),
                        // Ovoz (placeholder)
                        _buildControlButton(
                          heroTag: 'sound_btn',
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.black87,
                            size: 22,
                          ),
                          onTap: () {},
                        ),
                      ],
                    ],
                  ),
                ),

                // ─── PASTKI PANEL ────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: isNavigationStarted
                      ? _buildNavigationBottomBar()
                      : _buildRoutePreviewSheet(),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONTROL BUTTON (Google style — oq aylana)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildControlButton({
    required String heroTag,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  GOOGLE NAVIGATION BOTTOM BAR (navigatsiya paytidagi pastki panel)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNavigationBottomBar() {
    final etaMinutes = int.tryParse(duration) ?? 0;
    final eta = DateTime.now().add(Duration(minutes: etaMinutes));
    final etaString = '${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ✕ Tugmasi
              GestureDetector(
                onTap: () => stopNavigation(mapController: _mapController, isMapReady: _isMapReady, destination: widget.destination),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Vaqt va masofa
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B8D5B),
                          ),
                        ),
                        const Text(
                          ' daq.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B8D5B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B8D5B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$distance km  •  $etaString',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Tashqi kartalar
              GestureDetector(
                onTap: () => showExternalMaps(context, widget.destination),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Marshrut ko'rinishi
              GestureDetector(
                onTap: () {
                  setState(() => followUser = false);
                  centerOnRoute(mapController: _mapController, isMapReady: _isMapReady, destination: widget.destination);
                  _mapController.rotate(0);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.alt_route,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ROUTE PREVIEW SHEET (navigatsiya boshlanmagan holatda)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRoutePreviewSheet() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tutqich
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (distance.isNotEmpty && duration.isNotEmpty) ...[
                // Sarlavha + masofa bir qatorda
                Row(
                  children: [
                    const Text(
                      'Tez Yordam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$duration daq.',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' ($distance km)',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Eng tezkor marshrut',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                // Tugmalar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => startNavigation(
                      mapController: _mapController,
                      isMapReady: _isMapReady,
                      rawHeading: _rawHeading,
                      onHeadingUpdate: (h) => setState(() => _rawHeading = h),
                    ),
                    icon: const Icon(
                      Icons.navigation,
                      color: Colors.black87,
                      size: 22,
                    ),
                    label: const Text(
                      'Boshlash',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80DEEA),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFamilyMembers() {
    if (widget.household == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Oila a\'zolari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.household!.residents.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: widget.household!.residents.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final res = widget.household!.residents[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.background,
                      child: Icon(
                        res.gender == 'FEMALE'
                            ? Icons.person_outline
                            : Icons.person,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      res.displayFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (res.role != null) ...[
                          Text(
                            res.role!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                        Text(
                          res.phonePrimary ?? 'Telefon yo\'q',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
