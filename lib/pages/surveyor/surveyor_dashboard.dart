import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import 'package:provider/provider.dart';

import '../../additional/map_border.dart';
import '../../models/household_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/household_info_sheet.dart';
import '../login.dart';
import 'add_family_page.dart';
import 'patient_list_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SURVEYOR DASHBOARD  — Government UI, Driver stili bilan birxil
// ═══════════════════════════════════════════════════════════════════════════

class SurveyorDashboard extends StatefulWidget {
  const SurveyorDashboard({super.key});

  @override
  State<SurveyorDashboard> createState() => _SurveyorDashboardState();
}

class _SurveyorDashboardState extends State<SurveyorDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
    });
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      _SurveyorHome(),
      PatientListPage(isEmbedded: true),
      _HouseholdsMapPage(),
      _ProfilePage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return LiquidGlassBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      style: LiquidGlassBarStyle(
        activeColor: AppColors.govNavy,
        inactiveColor: const Color(0xFF9EA8B8),
        borderRadius: 28,
        height: 60,
        iconSize: 24,
        selectedIconScale: 1.2,
        animationDuration: const Duration(milliseconds: 280),
        animationCurve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        liquidGlassSettings: LiquidGlassSettings(
          blur: 18.0,
          thickness: 18.0,
          glassColor: Colors.white.withValues(alpha: 0.75),
          lightIntensity: 0.5,
          refractiveIndex: 1.4,
        ),
      ),
      items: const [
        LiquidGlassBarItem(iconData: Icons.grid_view_rounded,      label: 'Bosh sahifa'),
        LiquidGlassBarItem(iconData: Icons.list_alt_rounded,       label: 'Ro\'yxat'),
        LiquidGlassBarItem(iconData: Icons.map_outlined,           label: 'Xarita'),
        LiquidGlassBarItem(iconData: Icons.person_outline_rounded, label: 'Profil'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BOSH SAHIFA (Tab 0)
// ═══════════════════════════════════════════════════════════════════════════

class _SurveyorHome extends StatelessWidget {
  const _SurveyorHome();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final households = provider.households;
        final totalResidents = households.fold<int>(0, (s, h) => s + h.residents.length);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F8),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: provider.isLoading && households.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.govNavy))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _statCard(icon: Icons.home_work_outlined,     value: '${households.length}', label: 'Xonadonlar'),
                                const SizedBox(width: 12),
                                _statCard(icon: Icons.people_outline_rounded, value: '$totalResidents',       label: 'Aholi'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAddBanner(context),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Yaqinda qo\'shilganlar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                TextButton(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const PatientListPage())),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.govNavy),
                                  child: const Text('Barchasi'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Maks 10 ta — reversed tartibda (eng yangi birinchi)
                            ...households.reversed.take(10).map(
                                  (h) => _HouseholdCard(
                                    household: h,
                                    onTap: () => showHouseholdInfoSheet(context, h),
                                    onEdit: () => _openEditPage(context, h, provider),
                                  ),
                                ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_accounts, color: AppColors.govNavy, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xush kelibsiz',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  provider.currentUser?.fullName ?? 'Hatlovchi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.govNavy),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openAddPage(context, provider),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.govNavy, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.govNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAddBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddPage(context, Provider.of<AppProvider>(context, listen: false)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF1A5C99)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.govNavy.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Yangi xatlov', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Geolokatsiya va oila ma\'lumotlari', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.6), size: 16),
        ]),
      ),
    );
  }

  Future<void> _openAddPage(BuildContext context, AppProvider provider) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFamilyPage()));
    if (result == true && context.mounted) provider.fetchHouseholds();
  }

  Future<void> _openEditPage(BuildContext context, HouseholdModel h, AppProvider provider) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)));
    if (result == true && context.mounted) provider.fetchHouseholds();
  }
}

// ─── Household card ───────────────────────────────────────────────────────
class _HouseholdCard extends StatelessWidget {
  final HouseholdModel household;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _HouseholdCard({required this.household, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final h = household;
    final houseNum = h.houseNumber != null && h.houseNumber!.isNotEmpty ? '${h.houseNumber}-uy' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.home_work_outlined, color: AppColors.govNavy, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(houseNum ?? h.officialAddress,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
                const SizedBox(height: 3),
                Text(
                  [h.streetName, h.mfyName, h.tumanName].where((e) => e != null && e.isNotEmpty).join(' • '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('${h.residents.length} nafar',
                    style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.govNavy, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Tahrir', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  XARITA (Tab 2) — Smart zoom-based rendering
//  zoom < 11  → Tuman aggregate badges
//  zoom 11-13 → MarkerCluster
//  zoom >= 14 → Individual house markers with house number
// ═══════════════════════════════════════════════════════════════════════════

class _HouseholdsMapPage extends StatefulWidget {
  const _HouseholdsMapPage();

  @override
  State<_HouseholdsMapPage> createState() => _HouseholdsMapPageState();
}

class _HouseholdsMapPageState extends State<_HouseholdsMapPage> {
  final MapController _mapController = MapController();
  String _mapType = 'y';
  bool _isLocationLoading = false;
  double _currentZoom = 13.0;

  void _toggleMapType() => setState(() {
        _mapType = _mapType == 'y' ? 'm' : _mapType == 'm' ? 's' : 'y';
      });

  Future<void> _goToMyLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')));
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuvga ruxsat berilmadi')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
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
    for (final h in list) { lat += h.latitude; lng += h.longitude; }
    return LatLng(lat / list.length, lng / list.length);
  }

  @override
  Widget build(BuildContext context) {
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
                  initialCenter: const LatLng(40.3864, 71.7825),
                  initialZoom: _currentZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onPositionChanged: (pos, _) {
                    if ((pos.zoom - _currentZoom).abs() > 0.4) {
                      setState(() => _currentZoom = pos.zoom);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt1.google.com/vt/lyrs=$_mapType&hl=uz&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.example.demoproject',
                    maxZoom: 20,
                  ),
                  if (kShowMapBorder)
                    PolylineLayer(polylines: [
                      Polyline(points: kFerganaBorder, color: Colors.redAccent.withValues(alpha: 0.5), strokeWidth: 3)
                    ]),

                  // ── ZOOM < 11 → Tuman badge ───────────────────────
                  if (_currentZoom < 11)
                    MarkerLayer(
                      markers: groups.entries.map((e) {
                        final c = _center(e.value);
                        return Marker(
                          point: c, width: 84, height: 44,
                          child: GestureDetector(
                            onTap: () => _mapController.move(c, 13),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.govNavy,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: AppColors.govNavy.withValues(alpha: 0.35), blurRadius: 8)],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.location_city, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('${e.value.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ]),
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
                        markers: households.map((h) => Marker(
                          point: LatLng(h.latitude, h.longitude),
                          width: 36, height: 36,
                          child: GestureDetector(
                            onTap: () => showHouseholdInfoSheet(context, h),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.govNavy, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.home, color: Colors.white, size: 16),
                            ),
                          ),
                        )).toList(),
                        builder: (context, markers) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24), color: AppColors.govNavy,
                            boxShadow: [BoxShadow(color: AppColors.govNavy.withValues(alpha: 0.3), blurRadius: 10)],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(child: Text(markers.length.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                        ),
                      ),
                    ),

                  // ── ZOOM >= 14 → Individual markers ──────────────
                  if (_currentZoom >= 14)
                    MarkerLayer(
                      markers: households.map((h) => Marker(
                        point: LatLng(h.latitude, h.longitude),
                        width: 48, height: 54,
                        child: GestureDetector(
                          onTap: () => showHouseholdInfoSheet(context, h),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.govNavy, borderRadius: BorderRadius.circular(6)),
                              child: Text(h.houseNumber ?? '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.location_on, color: AppColors.govNavy, size: 28),
                          ]),
                        ),
                      )).toList(),
                    ),
                ],
              ),

              // Top info pill
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20, right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.map_outlined, color: AppColors.govNavy, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Xaritada ${households.length} ta xonadon',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            _currentZoom < 11 ? 'Tumanlar' : _currentZoom < 14 ? 'Klasterlar' : 'Xonadonlar',
                            style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FloatingActionButton.small(
                heroTag: 'map_type', onPressed: _toggleMapType, backgroundColor: Colors.white,
                child: Icon(_mapType == 'm' ? Icons.layers_outlined : Icons.layers, color: AppColors.govNavy),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'my_loc',
                onPressed: _isLocationLoading ? null : _goToMyLocation,
                backgroundColor: Colors.white, elevation: 4,
                icon: _isLocationLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.govNavy))
                    : const Icon(Icons.my_location, color: AppColors.govNavy),
                label: Text(_isLocationLoading ? 'Aniqlanmoqda...' : 'Yaqin hudud',
                    style: const TextStyle(color: AppColors.govNavy, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PROFIL (Tab 3)
// ═══════════════════════════════════════════════════════════════════════════

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final name = provider.currentUser?.fullName ?? 'Hatlovchi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.manage_accounts, color: AppColors.govNavy, size: 44),
                ),
                const SizedBox(height: 18),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
                const SizedBox(height: 4),
                const Text('Hatlovchi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.logout();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    label: const Text('Tizimdan chiqish',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
