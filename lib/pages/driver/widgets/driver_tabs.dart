import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../../../models/household_model.dart';
import '../../../models/resident_model.dart';
import '../../login/login_page.dart';
import 'nav_optionsheet.dart';
import '../../../widgets/household_info_sheet.dart';
import '../../search/global_search_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER HOME TAB — Drill-down qidiruv, stateful
// ═══════════════════════════════════════════════════════════════════════════

enum _DrillLevel { district, mfy, street, household, residents }

class _HouseOrBuilding {
  final bool isBuilding;
  final String title;
  final HouseholdModel? house;
  final List<HouseholdModel>? apartments;

  _HouseOrBuilding.house(this.house)
      : isBuilding = false,
        title = (house!.houseNumber != null && house.houseNumber!.trim().isNotEmpty)
            ? '${house.houseNumber}-uy'
            : 'Raqamsiz uy',
        apartments = null;
  _HouseOrBuilding.building(this.title, this.apartments)
      : isBuilding = true,
        house = null;
}

class DriverListsTab extends StatefulWidget {
  const DriverListsTab({super.key});

  @override
  State<DriverListsTab> createState() => _DriverListsTabState();
}

class _DriverListsTabState extends State<DriverListsTab> {
  List<HouseholdModel> _all = [];
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

  // ─── Drill helpers ──────────────────────────────────────────────
  List<String> get _districts {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    return s.toList()..sort();
  }

  List<String> get _mfys {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName == _selDistrict && h.mfyName != null && h.mfyName!.isNotEmpty) {
        s.add(h.mfyName!);
      }
    }
    return s.toList()..sort();
  }

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
    return s.toList()..sort();
  }

  List<HouseholdModel> get _householdsInStreet {
    return _all
        .where((h) =>
            h.tumanName == _selDistrict &&
            h.mfyName == _selMfy &&
            h.streetName == _selStreet)
        .toList();
  }

  List<_HouseOrBuilding> get _groupedObjectsInStreet {
    final list = _householdsInStreet;
    final result = <_HouseOrBuilding>[];
    final aptGroups = <String, List<HouseholdModel>>{};
    for (final h in list) {
      if (h.propertyType == 'APARTMENT') {
        final bNum = h.buildingNumber != null && h.buildingNumber!.isNotEmpty
            ? h.buildingNumber!
            : "Noma'lum";
        aptGroups.putIfAbsent(bNum, () => []).add(h);
      } else {
        result.add(_HouseOrBuilding.house(h));
      }
    }
    aptGroups.forEach((bNum, apts) {
      result.add(_HouseOrBuilding.building('$bNum-bino', apts));
    });
    return result;
  }

  List<HouseholdModel> get _levelHouseholds {
    return _all.where((h) {
      if (_selDistrict != null && h.tumanName != _selDistrict) return false;
      if (_selMfy != null && h.mfyName != _selMfy) return false;
      if (_selStreet != null && h.streetName != _selStreet) return false;
      if (_selHousehold != null && h.id != _selHousehold!.id) return false;
      return true;
    }).toList();
  }

  // ─── Navigation ──────────────────────────────────────────────────
  void _openNav(HouseholdModel h, {ResidentModel? r}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NavOptionsSheet(
        household: h,
        targetResident: r ?? (h.residents.isNotEmpty ? h.residents.first : null),
      ),
    );
  }

  void _openDetails(HouseholdModel h) {
    showHouseholdInfoSheet(
      context,
      h,
      onGetDirections: () => _openNav(h),
    );
  }

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

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(provider.currentUser?.fullName ?? 'Haydovchi'),
              _buildSearchTrigger(),
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
      },
    );
  }

  Widget _buildHeader(String name) {
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
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.govNavy,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
            label: const Text(
              'Chiqish',
              style: TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12,
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

  Widget _buildSearchTrigger() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalSearchPage(
              households: _all,
              actionIcon: Icons.directions_car_rounded,
              onActionTap: (h, r) => _openNav(h, r: r),
              onResultTap: _openDetails,
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: AppColors.govNavy),
                    SizedBox(width: 4),
                    Text(
                      'Filtr',
                      style: TextStyle(
                        fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (!_canGoBack) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: const Text(
          'Farg\'ona viloyati → Tumanlar',
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.govNavy, letterSpacing: 0.3,
          ),
        ),
      );
    }

    final parts = <String>['Farg\'ona viloyati'];
    if (_selDistrict != null) parts.add(_selDistrict!);
    if (_selMfy != null) parts.add(_selMfy!);
    if (_selStreet != null) parts.add(_selStreet!);
    if (_selHousehold != null) {
      parts.add('№${_selHousehold!.houseNumber ?? _selHousehold!.id}');
    }

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
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.govNavy,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
          title: '$_selDistrict — MFYlar',
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
          title: '$_selMfy — Ko\'chalar',
          items: streets,
          icon: Icons.signpost_rounded,
          onTap: (s) => setState(() {
            _selStreet = s;
            _level = _DrillLevel.household;
          }),
        );
      case _DrillLevel.household:
        final grouped = _groupedObjectsInStreet;
        if (grouped.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '$_selStreet — Binolar/Xonadonlar',
          items: grouped,
          onTap: (item) {
            if (item.isBuilding) {
              _showBuildingSheet(item.apartments!);
            } else {
              _openDetails(item.house!);
            }
          },
        );
      case _DrillLevel.residents:
        return _buildResidentList(_levelHouseholds);
    }
  }

  void _showBuildingSheet(List<HouseholdModel> apartments) {
    final floorsMap = <int, List<HouseholdModel>>{};
    for (final apt in apartments) {
      final f = apt.floor ?? 0;
      floorsMap.putIfAbsent(f, () => []).add(apt);
    }
    final sortedFloors = floorsMap.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20,
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF37474F), Color(0xFF263238)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.apartment, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${apartments.first.buildingNumber ?? "?"}–bino',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                Text(
                  "Jami ${apartments.length} ta xonadon ro'yxatga olingan",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedFloors.length,
                itemBuilder: (context, i) {
                  final floor = sortedFloors[i];
                  final apts = floorsMap[floor]!;
                  apts.sort((a, b) {
                    final numA = int.tryParse(a.apartment ?? '') ?? 0;
                    final numB = int.tryParse(b.apartment ?? '') ?? 0;
                    return numA.compareTo(numB);
                  });
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 56,
                            decoration: BoxDecoration(
                              color: AppColors.govNavy.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              border: Border(right: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  floor == 0 ? '?' : '$floor',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.govNavy),
                                ),
                                const Text('qavat', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: apts.map((apt) {
                                  final head = apt.residents.isNotEmpty ? apt.residents.first : null;
                                  final hasHead = head != null;
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openDetails(apt);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(children: [
                                        Container(
                                          width: 38, height: 38,
                                          decoration: BoxDecoration(
                                            color: hasHead ? const Color(0xFFF1F8E9) : const Color(0xFFF5F6F8),
                                            border: Border.all(color: hasHead ? const Color(0xFFAED581).withValues(alpha: 0.5) : Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(apt.apartment ?? '?',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                                    color: hasHead ? const Color(0xFF33691E) : AppColors.textMain)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(hasHead ? '${head.lastName} ${head.firstName}' : "Ma'lumot kiritilmagan",
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                                  color: hasHead ? AppColors.textMain : AppColors.textSecondary)),
                                          const SizedBox(height: 2),
                                          Text(hasHead ? '${apt.residents.length} nafar aholi' : "Bo'sh xonadon",
                                              style: TextStyle(fontSize: 11, color: hasHead ? AppColors.textSecondary : Colors.grey.shade400)),
                                        ])),
                                        const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                                      ]),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid({
    required String title,
    required List<String> items,
    required IconData icon,
    required void Function(String) onTap,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Ma\'lumot topilmadi', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
            ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildGridItem(items[i], icon, onTap),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, IconData icon, void Function(String) onTap) {
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.govNavy, size: 20),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(count > 0 ? '$count ta xonadon' : 'Ochish →',
                  style: TextStyle(fontSize: 10, color: count > 0 ? AppColors.textSecondary : AppColors.govNavy,
                      fontWeight: count > 0 ? FontWeight.normal : FontWeight.w600)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdGrid({
    required String title,
    required List<_HouseOrBuilding> items,
    required void Function(_HouseOrBuilding) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
            ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildHouseholdItem(items[i], onTap),
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdItem(_HouseOrBuilding item, void Function(_HouseOrBuilding) onTap) {
    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
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
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.isBuilding ? Icons.apartment : Icons.home_work_outlined, color: AppColors.govNavy, size: 20),
                ),
                Text(
                  item.isBuilding ? '${item.apartments!.length} xonadon' : 'ID: ${item.house!.id}',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                item.isBuilding ? "Bino ko'rinishi →" : '${item.house!.residents.length} nafar aholi',
                style: TextStyle(fontSize: 10, color: item.isBuilding ? AppColors.govNavy : AppColors.textSecondary,
                    fontWeight: item.isBuilding ? FontWeight.bold : FontWeight.normal),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentList(List<HouseholdModel> households) {
    final List<({ResidentModel r, HouseholdModel h})> rows = [];
    for (final h in households) {
      for (final r in h.residents) {
        rows.add((r: r, h: h));
      }
    }
    if (rows.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('Bu yerda aholisi yo\'q', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Text('Aholi ro\'yxati', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('${rows.length} nafar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
            ),
          ]),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openDetails(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                        child: Icon(r.gender == 'FEMALE' ? Icons.woman : Icons.man, color: AppColors.govNavy, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.displayFullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
                        const SizedBox(height: 3),
                        Text(
                          '${r.role ?? "Oila a\'zosi"} \u2022 ${h.officialAddress}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (r.phonePrimary != null && r.phonePrimary!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(r.phonePrimary!, style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w500)),
                        ],
                      ])),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openNav(h, r: r),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.directions_car_rounded, color: AppColors.govNavy, size: 20),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER SETTINGS TAB (Tab 1)
// ═══════════════════════════════════════════════════════════════════════════

class DriverSettingsTab extends StatelessWidget {
  const DriverSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sozlamalar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.govNavy),
              ),
              const SizedBox(height: 24),
              _buildSettingItem(icon: Icons.language_rounded, title: 'Tilni o\'zgartirish', onTap: () {}),
              _buildSettingItem(
                icon: Icons.dark_mode_outlined,
                title: 'Tungi rejim',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
              _buildSettingItem(icon: Icons.notifications_none_rounded, title: 'Bildirishnomalar', onTap: () {}),
              const SizedBox(height: 12),
              _buildSettingItem(icon: Icons.info_outline_rounded, title: 'Ilova haqida', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.govNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.govNavy, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER PROFILE TAB (Tab 2)
// ═══════════════════════════════════════════════════════════════════════════

class DriverProfileTab extends StatelessWidget {
  const DriverProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final name = provider.currentUser?.fullName ?? 'Haydovchi';

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
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
            const SizedBox(height: 8),
            const Text('Haydovchi', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                provider.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
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
}
