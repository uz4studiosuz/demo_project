import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/colors.dart';
import 'patient_list/patient_list_page.dart';
import 'widgets/surveyor_home_tab.dart';
import 'households_map/households_map_page.dart';
import 'widgets/surveyor_profile_tab.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SURVEYOR DASHBOARD  — Shell (bottom nav + indexed stack)
//  Tab 0: SurveyorHomeTab
//  Tab 1: PatientListPage
//  Tab 2: HouseholdsMapPage
//  Tab 3: SurveyorProfileTab
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
      SurveyorHomeTab(),
      PatientListPage(isEmbedded: true),
      HouseholdsMapPage(),
      SurveyorProfileTab(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
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
