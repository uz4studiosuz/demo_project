import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';

import '../../models/household_model.dart';
import '../../models/resident_model.dart';

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

class _DriverMapPageState extends State<DriverMapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  bool _isMapReady = false; // FlutterMap render bo'lguncha MapController ishlatilmaydi

  // ─── Smooth interpolation ──────────────────────────────────────
  LatLng? _rawPosition;
  LatLng? _displayPosition;
  double _rawHeading = 0.0;
  double _displayHeading = 0.0;
  double _displayMapRotation = 0.0;

  // Animatsiya controllerlari
  AnimationController? _moveAnimController;
  AnimationController? _headingAnimController;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  Animation<double>? _headingAnim;
  Animation<double>? _mapRotationAnim;

  // ─── Route state ───────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  List<List<LatLng>> _alternativeRoutes = [];
  List<dynamic> _turnSteps = [];
  String _distance = '';
  String _duration = '';
  bool _isRouteLoading = false;

  // ─── Navigation ────────────────────────────────────────────────
  // ─── Navigation ────────────────────────────────────────────────
  bool _isNavigationStarted = false;
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
  bool _followUser = true;

  // ─── Timers ────────────────────────────────────────────────────
  Timer? _routeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SMOOTH ANIMATION
  // ═══════════════════════════════════════════════════════════════

  double _shortestRotation(double from, double to) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void _animateToNewPosition(LatLng newPos, double newHeading) {
    _moveAnimController?.stop();
    _headingAnimController?.stop();
    _moveAnimController?.dispose();
    _headingAnimController?.dispose();

    final oldPos = _displayPosition ?? newPos;
    final oldHeading = _displayHeading;
    final oldMapRotation = _displayMapRotation;

    // Pozitsiya — 800ms silliq
    _moveAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _latAnim = Tween<double>(begin: oldPos.latitude, end: newPos.latitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));
    _lngAnim = Tween<double>(begin: oldPos.longitude, end: newPos.longitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));

    // Heading — 500ms silliq
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
      setState(() => _displayPosition = animatedPos);
      if (_followUser && _isMapReady) {
        _mapController.move(animatedPos, _mapController.camera.zoom);
      }
    });

    _headingAnimController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _displayHeading = _headingAnim!.value;
        _displayMapRotation = _mapRotationAnim!.value;
      });
      if (_followUser && _isNavigationStarted && _isMapReady) {
        _mapController.rotate(_mapRotationAnim!.value);
      }
    });

    _moveAnimController!.forward();
    _headingAnimController!.forward();
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
          _displayPosition = startLatLng;
          _rawHeading = pos.heading;
          _displayHeading = pos.heading;
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
        if (_isNavigationStarted && !_isRouteLoading) {
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
    if (position.speed > 1.0 && position.heading.isFinite && position.heading != 0.0) {
      newHeading = position.heading;
    } else if (_rawPosition != null) {
      // Emulator uchun yoki past tezlikda harakatlanganda kordinatalar orqali hisoblash
      final dist = _latLngDistance(_rawPosition!, newPos);
      if (dist > 0.0000005) { // Juda kichik harakatlarda sakrash bo'lmasligi uchun
        newHeading = _bearingBetween(_rawPosition!, newPos);
      }
    }

    setState(() {
      _currentSpeed = position.speed; // m/s -> biz keyin x/h ga o'tkazamiz
    });

    if (_isNavigationStarted) {
      _followUser = true; // Navigatsiya davrida haydovchi markazdan siljimaydi
    }

    _rawPosition = newPos;
    _rawHeading = newHeading;
    _animateToNewPosition(newPos, newHeading);

    if (_routePoints.isEmpty && !_isRouteLoading) {
      _fetchRoute();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ROUTE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchRoute() async {
    final pos = _rawPosition;
    if (pos == null) return;
    setState(() => _isRouteLoading = true);

    try {
      final start = '${pos.longitude},${pos.latitude}';
      final end = '${widget.destination.longitude},${widget.destination.latitude}';
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson&steps=true&alternatives=true',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final mainRoute = data['routes'][0];
          final List<dynamic> mainCoords = mainRoute['geometry']['coordinates'];
          _routePoints = mainCoords.map((c) => LatLng(c[1], c[0])).toList();

          _alternativeRoutes = [];
          for (int i = 1; i < data['routes'].length; i++) {
            final altRoute = data['routes'][i];
            final List<dynamic> altCoords = altRoute['geometry']['coordinates'];
            _alternativeRoutes.add(altCoords.map((c) => LatLng(c[1], c[0])).toList());
          }

          final distMeters = mainRoute['distance'] ?? 0.0;
          final durSeconds = mainRoute['duration'] ?? 0.0;
          _distance = (distMeters / 1000).toStringAsFixed(1);
          _duration = (durSeconds / 60).round().toString();

          if (mainRoute['legs'] != null && mainRoute['legs'].isNotEmpty) {
            _turnSteps = mainRoute['legs'][0]['steps'] ?? [];
          }

          if (mounted) {
            setState(() {});
            if (!_isNavigationStarted) _centerOnRoute();
          }
        }
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
    } finally {
      if (mounted) setState(() => _isRouteLoading = false);
    }
  }

  void _centerOnRoute() {
    if (!_isMapReady) return;
    if (_routePoints.isEmpty && _displayPosition == null) return;
    final points = _routePoints.isNotEmpty
        ? _routePoints
        : [_displayPosition!, widget.destination];
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 80, left: 40, right: 40, bottom: 180),
      ),
    );
  }

  /// Marshrutning birinchi 2 nuqtasidan boshlang'ich yo'nalishni hisoblab beradi
  double _calcRouteHeading() {
    if (_routePoints.length < 2 || _displayPosition == null) return _rawHeading;
    // Hozirgi pozitsiyaga eng yaqin nuqtani topamiz
    int nearestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < _routePoints.length; i++) {
      final d = _latLngDistance(_displayPosition!, _routePoints[i]);
      if (d < minDist) {
        minDist = d;
        nearestIdx = i;
      }
    }
    // Eng yaqin nuqta + keyingi nuqta orasidagi burchakni hisoblaymiz
    final nextIdx = (nearestIdx + 1).clamp(0, _routePoints.length - 1);
    if (nearestIdx == nextIdx) return _rawHeading;
    return _bearingBetween(_routePoints[nearestIdx], _routePoints[nextIdx]);
  }

  /// Ikki nuqta orasidagi geodezik bearing (0-360)
  double _bearingBetween(LatLng a, LatLng b) {
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Oddiy evklid masofasi (faqat qiyoslash uchun)
  double _latLngDistance(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _translateManeuver(String type, String modifier) {
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

  IconData _getStepIcon(String type, String modifier) {
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

  String _formatDistance(num meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }



  void _startNavigation() {
    // Marshrutdan boshlang'ich yo'nalishni hisoblaymiz
    final routeHeading = _calcRouteHeading();
    _rawHeading = routeHeading;
    _displayHeading = routeHeading;

    setState(() {
      _isNavigationStarted = true;
      _followUser = true;
    });
    if (_displayPosition != null && _isMapReady) {
      _mapController.move(_displayPosition!, 18.0);
      _mapController.rotate(-routeHeading);
      _displayMapRotation = -routeHeading;
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigationStarted = false;
      _followUser = true;
      _displayMapRotation = 0;
    });
    if (_isMapReady) {
      _mapController.rotate(0);
      if (_routePoints.isNotEmpty) _centerOnRoute();
    }
  }

  void _focusOnUser() {
    setState(() => _followUser = true);
    if (_displayPosition != null && _isMapReady) {
      _mapController.move(_displayPosition!, 18.0);
      if (_isNavigationStarted) {
        _mapController.rotate(-_rawHeading);
        _displayMapRotation = -_rawHeading;
      }
    }
  }

  void _showExternalMaps() {
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
            const Text(
              'Tashqi ilovada ochish',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.danger),
              title: const Text('Google Karta'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${widget.destination.latitude},${widget.destination.longitude}&travelmode=driving');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.amber),
              title: const Text('Yandex Navigator'),
              onTap: () async {
                Navigator.pop(context);
                final yandexUrlStr = 'yandexnavi://build_route_on_map?lat_to=${widget.destination.latitude}&lon_to=${widget.destination.longitude}';
                final url = Uri.parse(yandexUrlStr);
                
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  final fallbackUrl = Uri.parse('https://yandex.com/maps/?rtext=~${widget.destination.latitude},${widget.destination.longitude}');
                  if (await canLaunchUrl(fallbackUrl)) {
                     await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeRefreshTimer?.cancel();
    _moveAnimController?.dispose();
    _headingAnimController?.dispose();
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
      appBar: _isNavigationStarted
          ? null
          : AppBar(
              title: Text(widget.addressTitle),
              backgroundColor: AppColors.surface,
              elevation: 0,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // ─── MAP ─────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _displayPosition ?? widget.destination,
                    initialZoom: 17.0,
                    onMapReady: () {
                      _isMapReady = true;
                      if (_routePoints.isNotEmpty && !_isNavigationStarted) {
                        _centerOnRoute();
                      }
                    },
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && _followUser) {
                        if (!_isNavigationStarted) {
                          setState(() => _followUser = false);
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
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          ..._alternativeRoutes.map((alt) => Polyline(
                                points: alt,
                                color: Colors.grey.withValues(alpha: 0.35),
                                strokeWidth: 5.0,
                                strokeJoin: StrokeJoin.round,
                                strokeCap: StrokeCap.round,
                              )),
                          // Soya (outline)
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                            strokeWidth: 12.0,
                            strokeJoin: StrokeJoin.round,
                            strokeCap: StrokeCap.round,
                          ),
                          // Asosiy marshrut (Google-uslub — quyuq ko'k)
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF1565C0),
                            strokeWidth: 7.0,
                            strokeJoin: StrokeJoin.round,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      )
                    else if (_displayPosition != null && _isRouteLoading)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_displayPosition!, widget.destination],
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
                          ..._branches.map((b) => Marker(
                                point: b,
                                width: 32,
                                height: 32,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 18),
                                ),
                              )),

                          // 🚙 User (Driver) Marker — ko'k dumaloq va yo'nalish belgisi
                          if (_displayPosition != null)
                            Marker(
                              point: _displayPosition!,
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              rotate: false, // Ekran yuzasiga qulf, harita aylansa ham u "Tepani" (UP) ko'rsataveradi!
                              child: Transform.rotate(
                                // Agar navigatsiya boshlangan bo'lsa (Xarita aylanadi), marker har doim tepani ko'rsatishi u-n 0 gradus kerak.
                                // Chunki xarita uning ostida aylanadi.
                                angle: _isNavigationStarted
                                    ? 0
                                    : (_displayHeading * math.pi / 180),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Yo'nalishni bildiruvchi kichik pointer (tepaga qarab turadi)
                                    const Positioned(
                                      top: 2,
                                      child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
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

                if (_isNavigationStarted && _turnSteps.isNotEmpty) ...[
                  if (_turnSteps.length > 1) 
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
                              '${_formatDistance(_turnSteps[0]['distance'] ?? 0)} dan keyin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              _getStepIcon(
                                _turnSteps[1]['maneuver']['type'] ?? '',
                                _turnSteps[1]['maneuver']['modifier'] ?? '',
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
                            _translateManeuver(
                              _turnSteps[0]['maneuver']['type'] ?? '',
                              _turnSteps[0]['maneuver']['modifier'] ?? '',
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
                  if (_turnSteps.length > 1)
                    Positioned(
                      top: topPad + 86,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  _getStepIcon(
                                    _turnSteps[1]['maneuver']['type'] ?? '',
                                    _turnSteps[1]['maneuver']['modifier'] ?? '',
                                  ),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                            Text(
                              _formatDistance(_turnSteps[0]['distance'] ?? 0),
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
                      top: topPad + ( _turnSteps.length > 1 ? 144 : 86 ),
                      left: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _isPatientInfoExpanded = !_isPatientInfoExpanded),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isPatientInfoExpanded ? 220 : 60,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _isPatientInfoExpanded
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          widget.targetResident?.gender == 'FEMALE' ? Icons.person_outline : Icons.person,
                                          color: widget.targetResident?.isHighRiskMock == true ? AppColors.danger : AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.targetResident?.displayFullName ?? 'Bemor',
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
                                          onTap: () => setState(() => _isPatientInfoExpanded = false),
                                          child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                        )
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
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
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
                                      widget.targetResident?.gender == 'FEMALE' ? Icons.person_outline : Icons.person,
                                      color: widget.targetResident?.isHighRiskMock == true ? AppColors.danger : AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Bemor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                ],

                // ─── Meni ko'rsat (fokus) tooltip ───────────────
                if (_isNavigationStarted && !_followUser)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _focusOnUser,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFF1B8D5B), size: 18),
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
                  bottom: _isNavigationStarted ? 90 : (_distance.isNotEmpty ? 155 : 80),
                  right: 12,
                  child: Column(
                    children: [
                      // Tezlik o'lchagich (Speedometer)
                      if (_isNavigationStarted)
                        Container(
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (_currentSpeed * 3.6).round().toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.0, color: Colors.black87),
                                ),
                                const Text('km/h', style: TextStyle(fontSize: 9, height: 1.0, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),

                      // Kompas
                      if (_isNavigationStarted)
                        _buildControlButton(
                          heroTag: 'compass_btn',
                          icon: Transform.rotate(
                            angle: _displayMapRotation * math.pi / 180,
                            child: const Icon(Icons.navigation, color: Colors.red, size: 22),
                          ),
                          onTap: () {
                            // Shimolga qarab qo'yish
                            _mapController.rotate(0);
                            setState(() => _displayMapRotation = 0);
                          },
                        ),
                      if (_isNavigationStarted) const SizedBox(height: 10),

                      // Qatlam
                      _buildControlButton(
                        heroTag: 'layer_toggle',
                        icon: Icon(
                          _mapLayer == 'm'
                              ? Icons.layers
                              : (_mapLayer == 'y' ? Icons.layers_outlined : Icons.satellite_alt),
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
                          color: _followUser ? AppColors.primary : Colors.black54,
                          size: 22,
                        ),
                        onTap: _focusOnUser,
                      ),

                      if (_isNavigationStarted) ...[
                        const SizedBox(height: 10),
                        // Ovoz (placeholder)
                        _buildControlButton(
                          heroTag: 'sound_btn',
                          icon: const Icon(Icons.volume_up, color: Colors.black87, size: 22),
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
                  child: _isNavigationStarted
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: icon),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  GOOGLE NAVIGATION BOTTOM BAR (navigatsiya paytidagi pastki panel)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNavigationBottomBar() {
    final etaMinutes = int.tryParse(_duration) ?? 0;
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
                onTap: _stopNavigation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(Icons.close, color: Colors.black54, size: 22),
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
                          _duration,
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
                      '$_distance km  •  $etaString',
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
                onTap: _showExternalMaps,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(Icons.map_outlined, color: Colors.black54, size: 22),
                ),
              ),
              const SizedBox(width: 12),

              // Marshrut ko'rinishi
              GestureDetector(
                onTap: () {
                  setState(() => _followUser = false);
                  _centerOnRoute();
                  _mapController.rotate(0);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(Icons.alt_route, color: Colors.black54, size: 22),
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
              if (_distance.isNotEmpty && _duration.isNotEmpty) ...[
                // Sarlavha + masofa bir qatorda
                Row(
                  children: [
                    const Text(
                      'Tez Yordam',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '$_duration daq.',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' ($_distance km)',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
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
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.navigation, color: Colors.black87, size: 22),
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
                 width: 40, height: 5,
                 decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Oila a\'zolari',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.household!.residents.length}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
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
                      backgroundColor: res.isHighRiskMock
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.background,
                      child: Icon(
                        res.gender == 'FEMALE' ? Icons.person_outline : Icons.person,
                        color: res.isHighRiskMock ? AppColors.danger : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      res.displayFullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Row(
                      children: [
                        if (res.role != null) ...[
                          Text(res.role!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const Text('  •  ', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                        Text(
                          res.phonePrimary ?? 'Telefon yo\'q',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    trailing: res.isHighRiskMock
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Xavfli', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : null,
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

