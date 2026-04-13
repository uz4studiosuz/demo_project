import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../theme/colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/household_card.dart';
import '../login.dart';
import 'add_family_page.dart';
import 'patient_list_page.dart';
import '../../additional/map_border.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/household_info_sheet.dart';

class SurveyorDashboard extends StatefulWidget {
  const SurveyorDashboard({super.key});

  @override
  State<SurveyorDashboard> createState() => _SurveyorDashboardState();
}

class _SurveyorDashboardState extends State<SurveyorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const PatientListPage(isEmbedded: true),
    const HouseholdsMapPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  CupertinoIcons.square_grid_2x2,
                  CupertinoIcons.square_grid_2x2_fill,
                ),
                _buildNavItem(
                  1,
                  CupertinoIcons.list_bullet,
                  CupertinoIcons.list_bullet,
                ),
                _buildNavItem(2, CupertinoIcons.map, CupertinoIcons.map_fill),
                _buildNavItem(
                  3,
                  CupertinoIcons.person,
                  CupertinoIcons.person_fill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 100,
            title: _buildAppBar(context, provider),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          body: provider.isLoading && provider.households.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildStatsBanner(provider),
                    const SizedBox(height: 20),
                    _buildQuickAction(context),
                    const SizedBox(height: 25),
                    _buildSectionHeader('Yaqinda qo\'shilganlar', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientListPage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 15),
                    ...provider.households.reversed
                        .take(10)
                        .map(
                          (h) => HouseholdCard(
                            household: h,
                            onTap: () => showHouseholdInfoSheet(context, h),
                          ),
                        ),
                    const SizedBox(height: 120),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hayirli kun!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Punkt №7',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner(AppProvider provider) {
    int totalResidents = 0;
    for (var h in provider.households) {
      totalResidents += h.residents.length;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Row(
        children: [
          StatCard(
            label: 'Xonadonlar',
            value: provider.households.length.toString(),
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(width: 15),
          StatCard(
            label: 'Aholi soni',
            value: totalResidents.toString(),
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    return InkWell(
      onTap: () => _openAddPage(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 28,
              child: Icon(
                Icons.add_location_alt_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yangi xatlov',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Geolokatsiya va oila ma\'lumotlari',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.54),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Barchasi'),
        ),
      ],
    );
  }

  void _openAddPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFamilyPage()),
    );
    if (result == true) {
      if (context.mounted) {
        Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
      }
    }
  }
}

class HouseholdsMapPage extends StatefulWidget {
  const HouseholdsMapPage({super.key});

  @override
  State<HouseholdsMapPage> createState() => _HouseholdsMapPageState();
}

class _HouseholdsMapPageState extends State<HouseholdsMapPage> {
  final MapController _mapController = MapController();
  String _mapType = 'y'; // Default: Hybrid (y), Normal (m), Satellite (s)

  void _toggleMapType() {
    setState(() {
      if (_mapType == 'y') {
        _mapType = 'm';
      } else if (_mapType == 'm') {
        _mapType = 's';
      } else {
        _mapType = 'y';
      }
    });
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Tekshiramiz: Joylashuv xizmati yoqilganmi?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')),
        );
      }
      return;
    }

    // Ruxsatlarni tekshiramiz
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuvga ruxsat berilmadi')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joylashuv ruxsati butunlay rad etilgan'),
          ),
        );
      }
      return;
    }

    // Hozirgi joylashuvni olish
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joylashuvni aniqlashda xatolik: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final households = provider.households;

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(40.3864, 71.7825),
                  initialZoom: 13.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
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
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(45, 45),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 15,
                      markers: households.map((h) {
                        // final hasHighRisk = h.residents.any((r) => r.isHighRiskMock);
                        return Marker(
                          point: LatLng(h.latitude, h.longitude),
                          width: 45,
                          height: 45,
                          child: GestureDetector(
                            onTap: () => showHouseholdInfoSheet(context, h),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 45,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Icon(
                                    Icons.family_restroom,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Xaritada ${households.length} ta xonadon',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_type_btn',
                  onPressed: _toggleMapType,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _mapType == 'm' ? Icons.layers_outlined : Icons.layers,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'my_location_btn',
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                  label: const Text(
                    'Yaqin hudud',
                    style: TextStyle(
                      color: AppColors.primary,
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 50, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 20),
            Text(
              provider.currentUser?.fullName ?? 'Hatlovchi App',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                provider.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'Tizimdan chiqish',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
