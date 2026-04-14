import 'dart:io';

void main() {
  final file = File('lib/pages/driver/driver_dashboard.dart');
  var content = file.readAsStringSync();

  // 1. Enum
  content = content.replaceFirst(
    'enum _DrillLevel { district, mfy, street, household, residents }',
    '''enum _DrillLevel { district, mfy, street, household, residents }

class _HouseOrBuilding {
  final bool isBuilding;
  final String title;
  final HouseholdModel? house;
  final List<HouseholdModel>? apartments;

  _HouseOrBuilding.house(this.house) 
      : isBuilding = false, 
        title = (house!.houseNumber != null && house.houseNumber!.trim().isNotEmpty) ? '\${house.houseNumber}-uy' : 'Raqamsiz uy', 
        apartments = null;
  _HouseOrBuilding.building(this.title, this.apartments) 
      : isBuilding = true, 
        house = null;
}'''
  );

  // 2. Add _groupedObjectsInStreet
  content = content.replaceFirst(
    '''  List<HouseholdModel> get _householdsInStreet {
     return _all.where((h) => 
       h.tumanName == _selDistrict && 
       h.mfyName == _selMfy && 
       h.streetName == _selStreet
     ).toList();
  }''',
    '''  List<HouseholdModel> get _householdsInStreet {
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
        final bNum = h.buildingNumber != null && h.buildingNumber!.isNotEmpty ? h.buildingNumber! : "Noma'lum";
        aptGroups.putIfAbsent(bNum, () => []).add(h);
      } else {
        result.add(_HouseOrBuilding.house(h));
      }
    }

    aptGroups.forEach((bNum, apts) {
      result.add(_HouseOrBuilding.building('\$bNum-bino', apts));
    });

    return result;
  }'''
  );

  // 3. Drill Content
  content = content.replaceFirst(
    '''      case _DrillLevel.household:
        final households = _householdsInStreet;
        if (households.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '\${_selStreet} — Xonadonlar',
          items: households,
          // ✅ Tap → Bottom Sheet (list emas)
          onTap: (h) => _openDetails(h),
        );''',
    '''      case _DrillLevel.household:
        final grouped = _groupedObjectsInStreet;
        if (grouped.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '\${_selStreet} — Binolar/Xonadonlar',
          items: grouped,
          onTap: (item) {
            if (item.isBuilding) {
              _showBuildingSheet(context, item.apartments!);
            } else {
              _openDetails(item.house!);
            }
          },
        );'''
  );

  // 4. Grid header fix
  content = content.replaceFirst(
    '''  Widget _buildHouseholdGrid({
    required String title,
    required List<HouseholdModel> items,
    required void Function(HouseholdModel) onTap,
  }) {''',
    '''  Widget _buildHouseholdGrid({
    required String title,
    required List<_HouseOrBuilding> items,
    required void Function(_HouseOrBuilding) onTap,
  }) {'''
  );

  // 5. Item widget fix
  var itemOld = '''  Widget _buildHouseholdItem(HouseholdModel h, void Function(HouseholdModel) onTap) {
    // Uy raqamini chiroyli ko'rsatish (45-uy)
    String houseTitle = h.houseNumber != null && h.houseNumber!.isNotEmpty
        ? '\${h.houseNumber}-uy'
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
                  'ID: \${h.id}',
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
                  '\${h.residents.length} nafar aholi',
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
  }''';

  var itemNew = '''  Widget _buildHouseholdItem(_HouseOrBuilding item, void Function(_HouseOrBuilding) onTap) {
    return GestureDetector(
      onTap: () => onTap(item),
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
                  child: Icon(item.isBuilding ? Icons.apartment : Icons.home_work_outlined, color: AppColors.govNavy, size: 20),
                ),
                Text(
                  item.isBuilding ? '\${item.apartments!.length} xonadon' : 'ID: \${item.house!.id}',
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
                  item.title,
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
                  item.isBuilding ? "Bino ko'rinishi →" : '\${item.house!.residents.length} nafar aholi',
                  style: TextStyle(
                    fontSize: 10,
                    color: item.isBuilding ? AppColors.govNavy : AppColors.textSecondary,
                    fontWeight: item.isBuilding ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }''';
  content = content.replaceFirst(itemOld, itemNew);

  // 6. _showBuildingSheet
  var sheetNew = '''  // ─── BUILDING BOTTOM SHEET ────────────────────────────────────────
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
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
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
                Text('\${apartments.first.buildingNumber ?? "?"}–bino',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                Text("Jami \${apartments.length} ta xonadon ro'yxatga olingan",
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
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
                                  floor == 0 ? '?' : '\$floor',
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
                                              child: Text(
                                                apt.apartment ?? '?',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, 
                                                    color: hasHead ? const Color(0xFF33691E) : AppColors.textMain),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hasHead ? '\${head.lastName} \${head.firstName}' : "Ma'lumot kiritilmagan",
                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                                      color: hasHead ? AppColors.textMain : AppColors.textSecondary),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  hasHead ? '\${apt.residents.length} nafar aholi' : "Bo'sh xonadon",
                                                  style: TextStyle(fontSize: 11, color: hasHead ? AppColors.textSecondary : Colors.grey.shade400),
                                                ),
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

  // ─── BOTTOM NAV (liquid_glass_bar package) ───────────────────────''';
  
  content = content.replaceFirst('  // ─── BOTTOM NAV (liquid_glass_bar package) ───────────────────────', sheetNew);

  // 7. _all = provider.households length check removal
  content = content.replaceFirst(
    '''  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;

    // Tab 0 = Drill-down home, Tab 1 = Settings, Tab 2 = Profile
    final pages = [
      _buildHomePage(provider, user?.fullName ?? 'Haydovchi'),
      const _SettingsPage(),
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
  }''',
  '''  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;

    _all = provider.households;

    // Tab 0 = Drill-down home, Tab 1 = Settings, Tab 2 = Profile
    final pages = [
      _buildHomePage(provider, user?.fullName ?? 'Haydovchi'),
      const _SettingsPage(),
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
  }'''
  );

  file.writeAsStringSync(content);
}
