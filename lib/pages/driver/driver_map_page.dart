import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../theme/colors.dart';

class DriverMapPage extends StatefulWidget {
  final LatLng destination;
  final String addressTitle;

  const DriverMapPage({
    super.key,
    required this.destination,
    required this.addressTitle,
  });

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;

  // ─── Smooth interpolation state ────────────────────────────────
  LatLng? _rawPosition;           // GPS'dan kelgan oxirgi nuqta
  LatLng? _displayPosition;       // Ekranda ko'rsatilayotgan (interpolatsiya qilingan) nuqta
  double _rawHeading = 0.0;       // GPS'dan kelgan oxirgi yo'nalish
  double _displayHeading = 0.0;   // Ekranda ko'rsatilayotgan (silliq) yo'nalish
  double _displayMapRotation = 0.0; // Xarita burilish burchagi (silliq)

  // Animatsiya
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

  // ─── Navigation state ──────────────────────────────────────────
  bool _isNavigationStarted = false;

  // ─── Map layer state ───────────────────────────────────────────
  String _mapLayer = 'm'; // m: street, s: satellite, y: hybrid
  bool _followUser = true;

  // ─── Route re-fetch timer ──────────────────────────────────────
  Timer? _routeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SMOOTH ANIMATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Ikki burchak orasidagi eng qisqa yo'lni topadi (−180..+180)
  double _shortestRotation(double from, double to) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  /// GPS yangilanganda pozitsiya va heading'ni silliq animatsiya qiladi
  void _animateToNewPosition(LatLng newPos, double newHeading) {
    // Oldingi animatsiyalarni to'xtatamiz
    _moveAnimController?.dispose();
    _headingAnimController?.dispose();

    final oldPos = _displayPosition ?? newPos;
    final oldHeading = _displayHeading;
    final oldMapRotation = _displayMapRotation;

    // ─── Pozitsiya animatsiyasi (800ms, silliq) ──────────────
    _moveAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _latAnim = Tween<double>(begin: oldPos.latitude, end: newPos.latitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));
    _lngAnim = Tween<double>(begin: oldPos.longitude, end: newPos.longitude)
        .animate(CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeInOut));

    // ─── Heading animatsiyasi (600ms, silliq) ────────────────
    _headingAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final headingDiff = _shortestRotation(oldHeading, newHeading);
    _headingAnim = Tween<double>(begin: oldHeading, end: oldHeading + headingDiff)
        .animate(CurvedAnimation(parent: _headingAnimController!, curve: Curves.easeInOut));

    // Xarita burilishi uchun (faqat navigatsiya rejimida)
    final targetMapRotation = -newHeading;
    final mapRotDiff = _shortestRotation(oldMapRotation, targetMapRotation);
    _mapRotationAnim = Tween<double>(begin: oldMapRotation, end: oldMapRotation + mapRotDiff)
        .animate(CurvedAnimation(parent: _headingAnimController!, curve: Curves.easeInOut));

    // ─── Frame listener ──────────────────────────────────────
    _moveAnimController!.addListener(() {
      if (!mounted) return;
      final animatedPos = LatLng(_latAnim!.value, _lngAnim!.value);
      setState(() {
        _displayPosition = animatedPos;
      });
      if (_followUser) {
        _mapController.move(animatedPos, _mapController.camera.zoom);
      }
    });

    _headingAnimController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _displayHeading = _headingAnim!.value;
        _displayMapRotation = _mapRotationAnim!.value;
      });
      if (_followUser && _isNavigationStarted) {
        _mapController.rotate(_mapRotationAnim!.value);
      }
    });

    _moveAnimController!.forward();
    _headingAnimController!.forward();
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOCATION INITIALIZATION
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
            const SnackBar(content: Text('Joylashuv ruxsati rad etilgan. Sozlamalardan yoqing.')),
          );
        }
        return;
      }

      // Boshlang'ich pozitsiya — eng aniq
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
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

      // ─── Real-time GPS stream ──────────────────────────────
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0, // Har bir GPS tikini oladi — to'liq real vaqt
        ),
      ).listen(_onPositionUpdate);

      // ─── Har 30 sekundda marshrutni yangilash (ETA + yo'l) ─
      _routeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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

  /// GPS stream'dan har bir yangilanishni qayta ishlaydi
  void _onPositionUpdate(Position position) {
    if (!mounted) return;

    final newPos = LatLng(position.latitude, position.longitude);
    double newHeading = _rawHeading;

    // Faqat yetarli tezlikda heading'ni yangilaymiz (piyoda tezlikdan yuqori)
    // Bu svetoforda turganida ikonka aylanib ketishini oldini oladi
    if (position.speed > 1.0 && position.heading.isFinite && position.heading != 0.0) {
      newHeading = position.heading;
    }

    _rawPosition = newPos;
    _rawHeading = newHeading;

    // Silliq animatsiya orqali yangi nuqtaga ko'chirish
    _animateToNewPosition(newPos, newHeading);

    // Agar hali marshrut bo'lmasa — olishga harakat
    if (_routePoints.isEmpty && !_isRouteLoading) {
      _fetchRoute();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ROUTE FETCHING (OSRM)
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
            if (!_isNavigationStarted) {
              _centerOnRoute();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRouteLoading = false);
      }
    }
  }

  void _centerOnRoute() {
    if (_routePoints.isEmpty && _displayPosition == null) return;

    final points = _routePoints.isNotEmpty
        ? _routePoints
        : [_displayPosition!, widget.destination];

    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 100,
          left: 50,
          right: 50,
          bottom: 250,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _translateManeuver(String type, String modifier) {
    if (type == 'turn') {
      if (modifier.contains('left')) return 'Chapga buriling';
      if (modifier.contains('right')) return 'O\'ngga buriling';
      if (modifier == 'uturn') return 'Orqaga qayting';
    } else if (type == 'roundabout') {
      return 'Aylanmadan harakatlaning';
    } else if (type == 'arrive') {
      return 'Manzilga yetib keldingiz';
    } else if (type == 'depart') {
      return 'Harakatni boshlang';
    }
    return 'To\'g\'riga davom eting';
  }

  IconData _getStepIcon(String type, String modifier) {
    if (type == 'arrive') return Icons.flag;
    if (type == 'depart') return Icons.play_arrow;
    if (modifier.contains('left')) return Icons.turn_left;
    if (modifier.contains('right')) return Icons.turn_right;
    if (modifier == 'uturn') return Icons.u_turn_left;
    if (type == 'roundabout') return Icons.roundabout_right;
    return Icons.straight;
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION START / STOP
  // ═══════════════════════════════════════════════════════════════

  void _startNavigation() {
    setState(() {
      _isNavigationStarted = true;
      _followUser = true;
    });
    if (_displayPosition != null) {
      _mapController.move(_displayPosition!, 18.0);
      _mapController.rotate(-_rawHeading);
      _displayMapRotation = -_rawHeading;
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigationStarted = false;
      _displayMapRotation = 0;
    });
    _mapController.rotate(0);
  }

  void _focusOnUser() {
    setState(() => _followUser = true);
    if (_displayPosition != null) {
      _mapController.move(_displayPosition!, 18.0);
      if (_isNavigationStarted) {
        _mapController.rotate(-_rawHeading);
        _displayMapRotation = -_rawHeading;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  DISPOSE
  // ═══════════════════════════════════════════════════════════════

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
    return Scaffold(
      appBar: _isNavigationStarted ? null : AppBar(
        title: Text(widget.addressTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                // ─── MAP ─────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _displayPosition ?? widget.destination,
                    initialZoom: 17.0,
                    onMapReady: () {
                      if (_routePoints.isNotEmpty && !_isNavigationStarted) {
                        _centerOnRoute();
                      }
                    },
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && _followUser) {
                        setState(() => _followUser = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://mt1.google.com/vt/lyrs=$_mapLayer&hl=uz&x={x}&y={y}&z={z}',
                      userAgentPackageName: 'com.example.demoproject',
                    ),

                    // ─── Route polylines ─────────────────────────
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          ..._alternativeRoutes.map((altPoints) => Polyline(
                                points: altPoints,
                                color: Colors.grey.withValues(alpha: 0.4),
                                strokeWidth: 4.0,
                                strokeJoin: StrokeJoin.round,
                                strokeCap: StrokeCap.round,
                              )),
                          // Soya
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue.shade900.withValues(alpha: 0.3),
                            strokeWidth: 10.0,
                            strokeJoin: StrokeJoin.round,
                            strokeCap: StrokeCap.round,
                          ),
                          // Asosiy yo'l
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 6.0,
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

                    // ─── Markers ─────────────────────────────────
                    MarkerLayer(
                      markers: [
                        // Ambulance marker
                        if (_displayPosition != null)
                          Marker(
                            point: _displayPosition!,
                            width: 48,
                            height: 48,
                            child: Transform.rotate(
                              // Navigatsiya rejimida: xarita buriladi, mashina doim tepaga
                              // Oddiy rejimda: mashina yo'nalish bo'yicha buriladi
                              angle: _isNavigationStarted
                                  ? 0 // Xarita aylanadi → mashina doim yuqoriga
                                  : (_displayHeading * math.pi / 180),
                              child: Image.asset(
                                'assets/images/ambulance-car-top-view.png',
                                width: 38,
                                height: 38,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                        // Manzil markeri
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

                // ─── BACK BUTTON (navigatsiya paytida) ──────────
                if (_isNavigationStarted)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'nav_back_btn',
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: const Color(0xFF2B303A),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),

                // ─── TOP NAVIGATION GUIDE ────────────────────────
                if (_turnSteps.isNotEmpty && _isNavigationStarted)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF144D3A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStepIcon(
                              _turnSteps[0]['maneuver']['type'] ?? '',
                              _turnSteps[0]['maneuver']['modifier'] ?? '',
                            ),
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _translateManeuver(
                                    _turnSteps[0]['maneuver']['type'] ?? '',
                                    _turnSteps[0]['maneuver']['modifier'] ?? '',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(_turnSteps[0]['distance'] ?? 0).round()} m dan keyin',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ─── MAP CONTROLS ────────────────────────────────
                Positioned(
                  bottom: _isNavigationStarted ? 160 : (_turnSteps.isNotEmpty ? 220 : 100),
                  right: 16,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Qatlam almashtirish
                        FloatingActionButton.small(
                          heroTag: 'layer_toggle',
                          onPressed: () {
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
                          backgroundColor: const Color(0xFF2B303A),
                          child: Icon(
                            _mapLayer == 'm'
                                ? Icons.layers
                                : (_mapLayer == 'y' ? Icons.layers_outlined : Icons.satellite_alt),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Foydalanuvchiga fokus
                        FloatingActionButton.small(
                          heroTag: 'focus_user',
                          onPressed: _focusOnUser,
                          backgroundColor: _followUser ? AppColors.primary : const Color(0xFF2B303A),
                          child: const Icon(Icons.my_location, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── BOTTOM SHEET ────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (_distance.isNotEmpty && _duration.isNotEmpty)
                              _isNavigationStarted
                                  ? _buildNavigationActiveCard()
                                  : _buildRoutePreviewCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM SHEET CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRoutePreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tez Yordam',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '$_duration daq.',
              style: const TextStyle(
                color: Color(0xFF81C784),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' ($_distance km)',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Eng tezkor marshrut, yo\'llar holati ochiq',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.local_hospital, color: Color(0xFFEF5350), size: 16),
            SizedBox(width: 6),
            Text(
              'Inson hayoti hamma narsadan ustun',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation, color: Colors.black87),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_location_alt, color: Color(0xFF80DEEA)),
                label: const Text(
                  'Bekat kiritish',
                  style: TextStyle(
                    color: Color(0xFF80DEEA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF80DEEA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationActiveCard() {
    final etaMinutes = int.tryParse(_duration.split(' ')[0]) ?? 0;
    final eta = DateTime.now().add(Duration(minutes: etaMinutes));
    final etaString = '${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_duration daq.',
                  style: const TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_distance km • Soat $etaString',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_split, color: Colors.white),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _stopNavigation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
