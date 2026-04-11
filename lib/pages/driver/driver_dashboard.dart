import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
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
  List<HouseholdModel> _filteredHouseholds = [];

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
      _filteredHouseholds = provider.households;
    });
  }

  void _onSearchChanged(String query) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (query.isEmpty) {
      setState(() {
        _filteredHouseholds = provider.households;
      });
    } else {
      setState(() {
        _filteredHouseholds = provider.households.where((h) {
          final isAddressMatch = h.officialAddress.toLowerCase().contains(query.toLowerCase());
          final hasResidentMatch = h.residents.any((r) => r.displayFullName.toLowerCase().contains(query.toLowerCase()));
          return isAddressMatch || hasResidentMatch;
        }).toList();
      });
    }
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
                  // Fallback to web link if app is not installed
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
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Manzil yoki ism bo\'yicha qidirish...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadHouseholds,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: _filteredHouseholds.length,
                      itemBuilder: (context, index) {
                        final household = _filteredHouseholds[index];
                        final hasHighRisk = household.residents.any((r) => r.isHighRiskMock);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasHighRisk ? AppColors.danger : Colors.grey.withValues(alpha: 0.1),
                              width: hasHighRisk ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showHouseholdDetails(context, household),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: hasHighRisk ? AppColors.danger.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.location_on, color: hasHighRisk ? AppColors.danger : AppColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          household.officialAddress.isEmpty ? 'Manzilsiz' : household.officialAddress,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${household.residents.length} nafar yashovchi', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        if (hasHighRisk)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Qizil Hudud Xavfi', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.directions, color: AppColors.secondary, size: 36),
                                    style: IconButton.styleFrom(
                                       backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                                       padding: const EdgeInsets.all(12)
                                    ),
                                    onPressed: () => _showNavigationOptions(context, household),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showHouseholdDetails(BuildContext context, HouseholdModel household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
            const SizedBox(height: 20),
            const Text('Manzil', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            Text(household.officialAddress, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 24),
            const Text('Yashovchilar (Tibbiy varaqa)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: household.residents.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final res = household.residents[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: res.isHighRiskMock ? AppColors.danger.withValues(alpha: 0.1) : AppColors.background,
                      child: Icon(Icons.person, color: res.isHighRiskMock ? AppColors.danger : AppColors.textSecondary),
                    ),
                    title: Text(res.displayFullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(res.phonePrimary ?? 'Telefon yo\'q', style: const TextStyle(fontSize: 12)),
                    trailing: res.isHighRiskMock 
                        ? const Icon(Icons.warning_amber_rounded, color: AppColors.danger)
                        : null,
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                   Navigator.pop(context);
                   _showNavigationOptions(context, household);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Yo\'nalish olish', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      )
    );
  }
}
