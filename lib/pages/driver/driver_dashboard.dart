import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import '../login.dart';
import 'driver_map_page.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _searchController = TextEditingController();
  List<HouseholdModel> _allHouseholds = [];
  List<HouseholdModel> _filteredHouseholds = [];
  List<_FlatSearchMatch> _flatResults = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHouseholds();
    });
  }

  Future<void> _loadHouseholds() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchHouseholds();
    setState(() {
      _allHouseholds = provider.households;
      _filteredHouseholds = provider.households;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredHouseholds = _allHouseholds;
        _flatResults = [];
      } else {
        final q = query.toLowerCase();
        _flatResults = [];
        
        // Match Residents first
        for (var h in _allHouseholds) {
          final matchedInHouse = h.residents.where((r) => 
            r.displayFullName.toLowerCase().contains(q) || 
            (r.phonePrimary ?? '').contains(q)
          );
          
          for (var r in matchedInHouse) {
            _flatResults.add(_FlatSearchMatch(r, h));
          }
        }
        
        // Also match address (if not already added via resident)
        _filteredHouseholds = _allHouseholds.where((h) {
          return h.officialAddress.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  /// Qidiruv natijasiga mos kelgan yashovchilarni qaytaradi
  List<ResidentModel> _matchingResidents(HouseholdModel household) {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return household.residents.where(
      (r) => r.displayFullName.toLowerCase().contains(q) ||
             (r.phonePrimary ?? '').contains(q),
    ).toList();
  }

  void _showNavigationOptions(BuildContext context, HouseholdModel household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yo\'nalish olish usulini tanlang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.map, color: AppColors.primary),
              title: const Text('Ilova ichida'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverMapPage(
                      destination: LatLng(household.latitude, household.longitude),
                      addressTitle: household.officialAddress,
                      household: household,
                      targetResident: _matchingResidents(household).isNotEmpty 
                          ? _matchingResidents(household).first 
                          : (household.residents.isNotEmpty ? household.residents.first : null),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.danger),
              title: const Text('Google Karta'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${household.latitude},${household.longitude}&travelmode=driving');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Kartani ochib bo\'lmadi')));
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.amber),
              title: const Text('Yandex Navigator'),
              onTap: () async {
                Navigator.pop(context);
                final yandexUrlStr = 'yandexnavi://build_route_on_map?lat_to=${household.latitude}&lon_to=${household.longitude}';
                final url = Uri.parse(yandexUrlStr);
                
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  final fallbackUrl = Uri.parse('https://yandex.com/maps/?rtext=~${household.latitude},${household.longitude}');
                  if (await canLaunchUrl(fallbackUrl)) {
                     await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yandex Navigatorni ochib bo\'lmadi')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Haydovchi Ekroni'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: () {
              provider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ─── SEARCH BAR ──────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Ism, manzil yoki telefon raqam...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ─── NATIJALAR SONI ──────────────────────────────
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _flatResults.isNotEmpty 
                          ? '${_flatResults.length} ta kishi topildi'
                          : '${_filteredHouseholds.length} ta xonadon topildi',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                // ─── HOUSEHOLD LIST ──────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadHouseholds,
                    child: (_searchQuery.isEmpty ? _filteredHouseholds.isEmpty : (_flatResults.isEmpty && _filteredHouseholds.isEmpty))
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              const Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  'Natija topilmadi',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 20),
                            itemCount: _searchQuery.isNotEmpty ? _flatResults.length : _filteredHouseholds.length,
                            itemBuilder: (context, index) {
                              if (_searchQuery.isNotEmpty) {
                                return _buildResidentSearchResultCard(_flatResults[index]);
                              }
                              return _buildHouseholdCard(_filteredHouseholds[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HOUSEHOLD CARD — ism + manzil + oila a'zolari
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHouseholdCard(HouseholdModel household) {
    final hasHighRisk = household.residents.any((r) => r.isHighRiskMock);
    final matchedResidents = _matchingResidents(household);
    // Qidiruv bo'yicha mos kelgan yashovchi ismlari yoki ongina birinchi yashovchi
    final displayResident = matchedResidents.isNotEmpty
        ? matchedResidents.first
        : (household.residents.isNotEmpty ? household.residents.first : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasHighRisk ? AppColors.danger.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.08),
          width: hasHighRisk ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHouseholdDetails(context, household),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasHighRisk
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      displayResident != null
                          ? (displayResident.gender == 'FEMALE' ? Icons.person_outline : Icons.person)
                          : Icons.location_on,
                      color: hasHighRisk ? AppColors.danger : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ism + manzil
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yashovchi ismi (agar qidiruv bo'yicha topilgan bo'lsa — highlight)
                        if (displayResident != null)
                          Text(
                            displayResident.displayFullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        // Manzil
                        Text(
                          household.officialAddress.isEmpty ? 'Manzilsiz' : household.officialAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Yo'nalish tugmasi
                  Material(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showNavigationOptions(context, household),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.directions, color: AppColors.secondary, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

              // Oila a'zolari + xavf ko'rsatkichlari
              const SizedBox(height: 8),
              Row(
                children: [
                  // Oila a'zolari soni
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${household.residents.length} nafar',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  if (hasHighRisk) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.danger),
                          SizedBox(width: 3),
                          Text('Xavfli', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],

                  // Agar qidiruv natijasida mos yashovchilar bo'lsa, ularni kichik ro'yxatda ko'rsatamiz
                  if (_searchQuery.isNotEmpty && matchedResidents.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: matchedResidents.map((r) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.displayFullName,
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Batafsil
                  GestureDetector(
                    onTap: () => _showHouseholdDetails(context, household),
                    child: const Text(
                      'Batafsil →',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HOUSEHOLD DETAILS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showHouseholdDetails(BuildContext context, HouseholdModel household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
            const SizedBox(height: 16),
            // Manzil
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    household.officialAddress,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Yashovchilar sarlavha
            Row(
              children: [
                const Text(
                  'Oila a\'zolari',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${household.residents.length}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Yashovchilar ro'yxati
            Expanded(
              child: ListView.separated(
                itemCount: household.residents.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final res = household.residents[index];
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                   Navigator.pop(context);
                   _showNavigationOptions(context, household);
                },
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('Yo\'nalish olish', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RESIDENT SEARCH CARD — Individual matches
  // ═══════════════════════════════════════════════════════════════

  Widget _buildResidentSearchResultCard(_FlatSearchMatch match) {
    final resident = match.resident;
    final household = match.household;
    final hasHighRisk = resident.isHighRiskMock;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasHighRisk ? AppColors.danger.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.08),
          width: hasHighRisk ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHouseholdDetails(context, household),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasHighRisk
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  resident.gender == 'FEMALE' ? Icons.person_outline : Icons.person,
                  color: hasHighRisk ? AppColors.danger : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Ism + manzil
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.displayFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${resident.gender == 'FEMALE' ? "Ayol" : "Erkak"} • ${household.officialAddress}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Yo'nalish tugmasi
              Material(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showNavigationOptions(context, household),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.directions, color: AppColors.secondary, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlatSearchMatch {
  final ResidentModel resident;
  final HouseholdModel household;
  _FlatSearchMatch(this.resident, this.household);
}
