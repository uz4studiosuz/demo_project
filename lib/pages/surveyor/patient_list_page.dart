import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../theme/colors.dart';
import '../../widgets/household_info_sheet.dart';
// surveyor_dashboard import removed — no longer needed
import 'widgets/households_map_page.dart';
import 'add_family_page.dart';
import 'surveyor_search_page.dart';

enum _DrillLevel { district, mfy, street, household }

class _HouseOrBuilding {
  final bool isBuilding;
  final String title;
  final HouseholdModel? house;
  final List<HouseholdModel>? apartments;

  _HouseOrBuilding.house(this.house) 
      : isBuilding = false, 
        title = (house!.houseNumber != null && house.houseNumber!.trim().isNotEmpty) ? '${house.houseNumber}-uy' : 'Raqamsiz uy', 
        apartments = null;
  _HouseOrBuilding.building(this.title, this.apartments) 
      : isBuilding = true, 
        house = null;
}

class PatientListPage extends StatefulWidget {
  final bool isEmbedded;
  const PatientListPage({super.key, this.isEmbedded = false});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  List<HouseholdModel> _all = [];

  _DrillLevel _level = _DrillLevel.district;
  String? _selDistrict;
  String? _selMfy;
  String? _selStreet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final p = Provider.of<AppProvider>(context, listen: false);
    if (p.households.isEmpty) {
      await p.fetchHouseholds();
    }
    setState(() => _all = p.households);
  }

  // ─── Drill helpers ────────────────────────────────────────────────────────
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
      if (h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName != null && h.streetName!.isNotEmpty) {
        s.add(h.streetName!);
      }
    }
    return s.toList()..sort();
  }

  List<HouseholdModel> get _householdsInStreet {
     return _all.where((h) => 
       h.tumanName == _selDistrict && 
       h.mfyName == _selMfy && 
       h.streetName == _selStreet
     ).toList();
  }

  List<_HouseOrBuilding> get _groupedObjectsInStreet {
    final list = _householdsInStreet;
    final result = <_HouseOrBuilding>[];
    final aptGroups = <String, List<HouseholdModel>>{};

    for (final h in list) {
      if (h.propertyType == 'APARTMENT') {
        final bNum = h.buildingNumber != null && h.buildingNumber!.isNotEmpty ? h.buildingNumber! : 'Noma\'lum';
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

  // ─── UI Helpers ───────────────────────────────────────────────────────────
  void _openDetails(HouseholdModel h) {
    showHouseholdInfoSheet(context, h);
  }

  void _openAdd() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFamilyPage()));
    if (res == true && mounted) {
      _load();
    }
  }

  Future<void> _refresh() async {
    await Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          _all = provider.households;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F6F8),
            body: RefreshIndicator(
              color: AppColors.govNavy,
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: _buildSearchTrigger()),
                  SliverToBoxAdapter(
                    child: provider.isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(color: AppColors.govNavy)),
                          )
                        : _buildDrillContent(),
                  ),
                ],
              ),
            ),
            floatingActionButton: widget.isEmbedded
                ? null
                : FloatingActionButton.extended(
                    onPressed: _openAdd,
                    backgroundColor: AppColors.govNavy,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Yangi xatlov',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          );
        },
      ),
    );
  }

  // ─── APP BAR & BREADCRUMBS ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF5F6F8),
      elevation: 0,
      pinned: true,
      title: const Text(
        'Xonadonlar',
        style: TextStyle(color: AppColors.govNavy, fontSize: 22, fontWeight: FontWeight.w800),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBreadcrumbItem('Hududlar', _DrillLevel.district, _level == _DrillLevel.district),
              if (_level.index >= _DrillLevel.mfy.index && _selDistrict != null)
                _buildBreadcrumbItem(_selDistrict!, _DrillLevel.mfy, _level == _DrillLevel.mfy),
              if (_level.index >= _DrillLevel.street.index && _selMfy != null)
                _buildBreadcrumbItem(_selMfy!, _DrillLevel.street, _level == _DrillLevel.street),
              if (_level.index >= _DrillLevel.household.index && _selStreet != null)
                _buildBreadcrumbItem(_selStreet!, _DrillLevel.household, _level == _DrillLevel.household),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(String label, _DrillLevel lvl, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _level = lvl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.govNavy : AppColors.govNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.govNavy,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (lvl != _DrillLevel.household && isActive == false)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  // ─── SEARCH TRIGGER ──────────────────────────────────────────────────────
  Widget _buildSearchTrigger() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SurveyorSearchPage(households: _all)),
        ),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.govNavy, size: 20),
              const SizedBox(width: 12),
              Text(
                'Ism, familiya, manzil orqali...',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DRILL CONTENT ───────────────────────────────────────────────────────
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
        if (mfys.isEmpty) return _buildEmpty();
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
        if (streets.isEmpty) return _buildEmpty();
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
        if (grouped.isEmpty) return _buildEmpty();
        return _buildHouseholdGrid(
          title: '$_selStreet — Binolar',
          items: grouped,
          onTap: (item) {
            if (item.isBuilding) {
              _showBuildingSheet(context, item.apartments!);
            } else {
              _openDetails(item.house!);
            }
          },
        );
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 36, color: AppColors.govNavy.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Hech narsa topilmadi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
        ],
      ),
    );
  }

  // ─── GRID ELEMENTS ───────────────────────────────────────────────────────
  Widget _buildGrid({
    required String title,
    required List<String> items,
    required IconData icon,
    required void Function(String) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildGridItem(items[i], icon, onTap),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, IconData icon, void Function(String) onTap) {
    int count = _all.where((h) {
      if (_level == _DrillLevel.district) return h.tumanName == label;
      if (_level == _DrillLevel.mfy) return h.tumanName == _selDistrict && h.mfyName == label;
      if (_level == _DrillLevel.street) return h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName == label;
      return false;
    }).length;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.govNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Text('$count ta xonadon', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildHouseholdItem(items[i], onTap),
        ),
      ],
    );
  }

  Widget _buildHouseholdItem(_HouseOrBuilding item, void Function(_HouseOrBuilding) onTap) {
    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.isBuilding ? Icons.apartment : Icons.home_work_outlined, color: AppColors.govNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Text(item.isBuilding ? '${item.apartments!.length} ta kavartira' : 'ID: ${item.house!.id}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!item.isBuilding)
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HouseholdsMapPage(focusHousehold: item.house))),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFF1976D2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF1976D2)),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFamilyPage(existing: item.house)));
                      if (result == true && mounted) _refresh();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.govNavy, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ─── BUILDING BOTTOM SHEET ────────────────────────────────────────
  void _showBuildingSheet(BuildContext context, List<HouseholdModel> apartments) {
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
        decoration: const BoxDecoration(color: Color(0xFFF8F9FA), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
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
                Text('${apartments.first.buildingNumber ?? "?"}–bino', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                Text('Jami ${apartments.length} ta xonadon ro\'yxatga olingan', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                                Text(floor == 0 ? '?' : '$floor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.govNavy)),
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
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38, height: 38,
                                            decoration: BoxDecoration(
                                              color: hasHead ? const Color(0xFFF1F8E9) : const Color(0xFFF5F6F8),
                                              border: Border.all(color: hasHead ? const Color(0xFFAED581).withValues(alpha: 0.5) : Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(apt.apartment ?? '?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hasHead ? const Color(0xFF33691E) : AppColors.textMain)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(hasHead ? '${head.lastName} ${head.firstName}' : 'Ma\'lumot kiritilmagan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasHead ? AppColors.textMain : AppColors.textSecondary)),
                                                const SizedBox(height: 2),
                                                Text(hasHead ? '${apt.residents.length} nafar aholi' : 'Bo\'sh xonadon', style: TextStyle(fontSize: 11, color: hasHead ? AppColors.textSecondary : Colors.grey.shade400)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                                        ],
                                      ),
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
}
