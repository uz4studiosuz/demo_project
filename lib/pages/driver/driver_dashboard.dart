import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import '../../theme/colors.dart';
import 'widgets/driver_tabs.dart';
import 'widgets/driver_home_tab.dart'; // import newly added home tab

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER DASHBOARD  — Shell (bottom nav + indexed stack)
//  Tab 0: DriverHomeTab (Map + Search)
//  Tab 1: DriverListsTab (Grids / Drill-down)
//  Tab 2: DriverSettingsTab
//  Tab 3: DriverProfileTab
// ═══════════════════════════════════════════════════════════════════════════

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      DriverHomeTab(),
      DriverListsTab(),
      DriverSettingsTab(),
      DriverProfileTab(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        extendBody: true,
        body: IndexedStack(index: _currentTab, children: pages),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return LiquidGlassBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
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
        LiquidGlassBarItem(iconData: Icons.map_outlined,           label: 'Asosiy'),
        LiquidGlassBarItem(iconData: Icons.format_list_bulleted,   label: 'Ro\'yxatlar'),
        LiquidGlassBarItem(iconData: Icons.settings_outlined,      label: 'Sozlamalar'),
        LiquidGlassBarItem(iconData: Icons.person_outline_rounded, label: 'Profil'),
      ],
    );
  }
}
