import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import '../login.dart';
import 'driver_map_page.dart';
import 'driver_search_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRILL LEVEL enum
// ═══════════════════════════════════════════════════════════════════════════

enum _DrillLevel { district, mfy, street, household, residents }

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  // ─── Tabs ────
  int _currentTab = 0;

  // ─── Data ────
  List<HouseholdModel> _all = [];

  // ─── Breadcrumb drill-down ────
  _DrillLevel _level = _DrillLevel.district;
  String? _selDistrict;
  String? _selMfy;
  String? _selStreet;
  HouseholdModel? _selHousehold;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final p = Provider.of<AppProvider>(context, listen: false);
    await p.fetchHouseholds();
    setState(() => _all = p.households);
  }

  // ─── Drill helpers ────────────────────────────────────────────────────────

  /// Returns all distinct districts from loaded households
  List<String> get _districts {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    final list = s.toList()..sort();
    return list;
  }

  /// MFYs for selected district
  List<String> get _mfys {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName == _selDistrict &&
          h.mfyName != null &&
          h.mfyName!.isNotEmpty) {
        s.add(h.mfyName!);
      }
    }
    final list = s.toList()..sort();
    return list;
  }

  /// Streets for selected MFY
  List<String> get _streets {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName == _selDistrict &&
          h.mfyName == _selMfy &&
          h.streetName != null &&
          h.streetName!.isNotEmpty) {
        s.add(h.streetName!);
      }
    }
    final list = s.toList()..sort();
    return list;
  }

  /// Households for selected Street
  List<HouseholdModel> get _householdsInStreet {
     return _all.where((h) => 
       h.tumanName == _selDistrict && 
       h.mfyName == _selMfy && 
       h.streetName == _selStreet
     ).toList();
  }

  /// Households for the deepest selected level (legacy or generic)
  List<HouseholdModel> get _levelHouseholds {
    return _all.where((h) {
      if (_selDistrict != null && h.tumanName != _selDistrict) return false;
      if (_selMfy != null && h.mfyName != _selMfy) return false;
      if (_selStreet != null && h.streetName != _selStreet) return false;
      if (_selHousehold != null && h.id != _selHousehold!.id) return false;
      return true;
    }).toList();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────
  void _logout() {
    Provider.of<AppProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openNav(HouseholdModel h, {ResidentModel? r}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NavOptionsSheet(
        household: h,
        targetResident: r ?? (h.residents.isNotEmpty ? h.residents.first : null),
      ),
    );
  }

  void _openDetails(HouseholdModel h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HouseholdDetailSheet(
        household: h,
        onNavigate: (r) {
          Navigator.pop(ctx);
          _openNav(h, r: r);
        },
      ),
    );
  }

  // ─── Breadcrumb back ─────────────────────────────────────────────────────
  void _goBack() {
    setState(() {
      switch (_level) {
        case _DrillLevel.mfy:
          _level = _DrillLevel.district;
          _selDistrict = null;
        case _DrillLevel.street:
          _level = _DrillLevel.mfy;
          _selMfy = null;
        case _DrillLevel.household:
          _level = _DrillLevel.street;
          _selStreet = null;
        case _DrillLevel.residents:
          _level = _DrillLevel.household;
          _selHousehold = null;
        case _DrillLevel.district:
          break;
      }
    });
  }

  bool get _canGoBack => _level != _DrillLevel.district;

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;

    // Tab 0 = Drill-down home, Tab 1 = Map, Tab 2 = Notifications, Tab 3 = Profile
    final pages = [
      _buildHomePage(provider, user?.fullName ?? 'Haydovchi'),
      const DriverMapPlaceholder(),
      const _NotificationsPage(),
      _buildProfilePage(user?.fullName ?? 'Haydovchi'),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        extendBody: true,
        body: IndexedStack(
          index: _currentTab,
          children: pages,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────
  Widget _buildHeader(String name) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.govNavy, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xush kelibsiz',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
            label: const Text(
              'Chiqish',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppColors.danger.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HOME PAGE (tab 0) ──────────────────────────────────────────
  Widget _buildHomePage(AppProvider provider, String name) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(name),
          _buildSearchTrigger(), // tappable search bar → open search page
          _buildBreadcrumb(),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.govNavy),
                  )
                : _buildDrillContent(),
          ),
        ],
      ),
    );
  }

  // ─── PROFILE PAGE (tab 3) ────────────────────────────────────────
  Widget _buildProfilePage(String name) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.govNavy, size: 40),
            ),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy)),
            const SizedBox(height: 8),
            const Text('Haydovchi', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Chiqish', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BREADCRUMB ─────────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    if (!_canGoBack) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: const Text(
          'Farg\'ona viloyati → Tumanlar',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.govNavy,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    final parts = <String>['Farg\'ona viloyati'];
    if (_selDistrict != null) parts.add(_selDistrict!);
    if (_selMfy != null) parts.add(_selMfy!);
    if (_selStreet != null) parts.add(_selStreet!);
    if (_selHousehold != null) parts.add('№${_selHousehold!.houseNumber ?? _selHousehold!.id}');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.govNavy),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              parts.join(' → '),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.govNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH TRIGGER (read-only tap → open search page) ──────────
  Widget _buildSearchTrigger() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverSearchPage(
              households: _all,
              onNavigate: (h, r) => _openNav(h, r: r),
              onOpenDetail: _openDetails,
            ),
          ),
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.govNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ism, ko\'cha, telefon...',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AppColors.govNavy),
                    const SizedBox(width: 4),
                    const Text(
                      'Filtr',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.govNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ─── DRILL CONTENT ───────────────────────────────────────────────
  Widget _buildDrillContent() {
    switch (_level) {
      case _DrillLevel.district:
        return _buildGrid(
          title: 'Tumanlar va shaharlar',
          items: _districts,
          icon: Icons.location_city_rounded,
          onTap: (d) => setState(() {
            _selDistrict = d;
            _level = _DrillLevel.mfy;
          }),
        );
      case _DrillLevel.mfy:
        final mfys = _mfys;
        if (mfys.isEmpty) return _buildResidentList(_levelHouseholds);
        return _buildGrid(
          title: '${_selDistrict} — MFYlar',
          items: mfys,
          icon: Icons.maps_home_work_rounded,
          onTap: (m) => setState(() {
            _selMfy = m;
            _level = _DrillLevel.street;
          }),
        );
      case _DrillLevel.street:
        final streets = _streets;
        if (streets.isEmpty) return _buildResidentList(_levelHouseholds);
        return _buildGrid(
          title: '${_selMfy} — Ko\'chalar',
          items: streets,
          icon: Icons.signpost_rounded,
          onTap: (s) => setState(() {
            _selStreet = s;
            _level = _DrillLevel.household;
          }),
        );
      case _DrillLevel.household:
        final households = _householdsInStreet;
        if (households.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '${_selStreet} — Xonadonlar',
          items: households,
          // ✅ Tap → Bottom Sheet (list emas)
          onTap: (h) => _openDetails(h),
        );
      case _DrillLevel.residents:
        return _buildResidentList(_levelHouseholds);
    }
  }

  // ─── GRID ────────────────────────────────────────────────────────
  Widget _buildGrid({
    required String title,
    required List<String> items,
    required IconData icon,
    required void Function(String) onTap,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Ma\'lumot topilmadi',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildGridItem(items[i], icon, onTap),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, IconData icon, void Function(String) onTap) {
    // Count households inside this item
    int count = _all.where((h) {
      if (_level == _DrillLevel.district) return h.tumanName == label;
      if (_level == _DrillLevel.mfy) return h.tumanName == _selDistrict && h.mfyName == label;
      if (_level == _DrillLevel.street) {
        return h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName == label;
      }
      return false;
    }).length;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.govNavy, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count > 0 ? '$count ta xonadon' : 'Ochish →',
                  style: TextStyle(
                    fontSize: 10,
                    color: count > 0 ? AppColors.textSecondary : AppColors.govNavy,
                    fontWeight: count > 0 ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── HOUSEHOLD GRID ─────────────────────────────────────────────
  Widget _buildHouseholdGrid({
    required String title,
    required List<HouseholdModel> items,
    required void Function(HouseholdModel) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildHouseholdItem(items[i], onTap),
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdItem(HouseholdModel h, void Function(HouseholdModel) onTap) {
    // Uy raqamini chiroyli ko'rsatish (45-uy)
    String houseTitle = h.houseNumber != null && h.houseNumber!.isNotEmpty
        ? '${h.houseNumber}-uy'
        : 'Raqamsiz-uy';

    return GestureDetector(
      onTap: () => onTap(h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: AppColors.govNavy, size: 20),
                ),
                Text(
                  'ID: ${h.id}',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  houseTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${h.residents.length} nafar aholi',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESIDENT/HOUSEHOLD LIST ─────────────────────────────────────
  Widget _buildResidentList(List<HouseholdModel> households) {
    final List<({ResidentModel r, HouseholdModel h})> rows = [];
    for (final h in households) {
      for (final r in h.residents) {
        rows.add((r: r, h: h));
      }
    }

    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('Bu yerda aholisi yo\'q',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Text('Aholi ro\'yxati',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rows.length} nafar',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.govNavy),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final rec = rows[i];
              final r = rec.r;
              final h = rec.h;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openDetails(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.govNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            r.gender == 'FEMALE' ? Icons.woman : Icons.man,
                            color: AppColors.govNavy, size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.displayFullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textMain)),
                              const SizedBox(height: 3),
                              Text(
                                '${r.role ?? "Oila a\'zosi"} \u2022 ${h.officialAddress}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (r.phonePrimary != null && r.phonePrimary!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(r.phonePrimary!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.govNavy,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openNav(h, r: r),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.govNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.directions_car_rounded,
                                color: AppColors.govNavy, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── BOTTOM NAV (liquid_glass_bar package) ───────────────────────
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
        LiquidGlassBarItem(iconData: Icons.search_rounded,              label: 'Qidiruv'),
        LiquidGlassBarItem(iconData: Icons.map_outlined,                label: 'Xarita'),
        LiquidGlassBarItem(iconData: Icons.notifications_none_rounded,  label: 'Bildirish'),
        LiquidGlassBarItem(iconData: Icons.person_outline_rounded,      label: 'Profil'),
      ],
    );
  }
}



// ═══════════════════════════════════════════════════════════════════════════
//  NAVIGATION OPTIONS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _NavOptionsSheet extends StatelessWidget {
  final HouseholdModel household;
  final ResidentModel? targetResident;
  const _NavOptionsSheet({required this.household, this.targetResident});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yo\'nalish usulini tanlang',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.govNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            household.officialAddress,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _option(
            context,
            icon: Icons.map_rounded,
            color: AppColors.govNavy,
            title: 'Ilova ichida navigatsiya',
            sub: 'Marshrut va yo\'nalish ko\'rsatmalar',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverMapPage(
                    destination: LatLng(household.latitude, household.longitude),
                    addressTitle: household.officialAddress,
                    household: household,
                    targetResident: targetResident,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _option(
            context,
            icon: Icons.location_on_rounded,
            color: Colors.red,
            title: 'Google Maps',
            sub: 'Tashqi ilovada ochish',
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=${household.latitude},${household.longitude}&travelmode=driving',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const Divider(height: 1),
          _option(
            context,
            icon: Icons.navigation_rounded,
            color: Colors.amber.shade700,
            title: 'Yandex Navigator',
            sub: 'Tashqi ilovada ochish',
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse(
                'yandexnavi://build_route_on_map?lat_to=${household.latitude}&lon_to=${household.longitude}',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                final fb = Uri.parse(
                  'https://yandex.com/maps/?rtext=~${household.latitude},${household.longitude}',
                );
                if (await canLaunchUrl(fb)) {
                  await launchUrl(fb, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HOUSEHOLD DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _HouseholdDetailSheet extends StatelessWidget {
  final HouseholdModel household;
  final void Function(ResidentModel?) onNavigate;
  const _HouseholdDetailSheet({required this.household, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: AppColors.govNavy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        household.officialAddress.isEmpty ? 'Manzilsiz' : household.officialAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        [household.tumanName, household.mfyName, household.streetName]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Oila a\'zolari',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.govNavy),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${household.residents.length} nafar',
                    style: const TextStyle(
                      color: AppColors.govNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: household.residents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = household.residents[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      r.gender == 'FEMALE' ? Icons.woman : Icons.man,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    r.displayFullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    [r.role, r.phonePrimary]
                        .where((e) => e != null && e!.isNotEmpty)
                        .join(' • '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Material(
                    color: AppColors.govNavy.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onNavigate(r),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.directions_car_rounded, color: AppColors.govNavy, size: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => onNavigate(
                    household.residents.isNotEmpty ? household.residents.first : null),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text(
                  'Yo\'nalish olish',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.govNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAP PLACEHOLDER (Tab 1)
// ═══════════════════════════════════════════════════════════════════════════

class DriverMapPlaceholder extends StatelessWidget {
  const DriverMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 56, color: AppColors.govNavy),
            SizedBox(height: 16),
            Text(
              'Xarita',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.govNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Tez orada',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  NOTIFICATIONS PAGE (Tab 2)
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 56, color: AppColors.govNavy),
              SizedBox(height: 16),
              Text(
                'Bildirishnomalar',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy),
              ),
              SizedBox(height: 6),
              Text(
                'Hozircha bildirishnomalar yo\'q',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
