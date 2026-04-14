import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/household_info_sheet.dart';
import '../add_family_page.dart';
import '../patient_list_page.dart';
import 'household_list_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SurveyorHomeTab — Surveyor Dashboard Tab 0 (Bosh sahifa)
// ═══════════════════════════════════════════════════════════════════════════

class SurveyorHomeTab extends StatelessWidget {
  const SurveyorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final households = provider.households;
        final totalResidents =
            households.fold<int>(0, (s, h) => s + h.residents.length);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F8),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: provider.isLoading && households.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.govNavy),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _statCard(
                                  icon: Icons.home_work_outlined,
                                  value: '${households.length}',
                                  label: 'Xonadonlar',
                                ),
                                const SizedBox(width: 12),
                                _statCard(
                                  icon: Icons.people_outline_rounded,
                                  value: '$totalResidents',
                                  label: 'Aholi',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAddBanner(context, provider),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Yaqinda qo\'shilganlar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PatientListPage(),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.govNavy,
                                  ),
                                  child: const Text('Barchasi'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Maks 10 ta — reversed tartibda (eng yangi birinchi)
                            ...households.reversed.take(10).map(
                                  (h) => HouseholdListCard(
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
                const Text(
                  'Xush kelibsiz',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  provider.currentUser?.fullName ?? 'Hatlovchi',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.govNavy,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openAddPage(context, provider),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.govNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.govNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.govNavy,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAddBanner(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => _openAddPage(context, provider),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF1A5C99)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.govNavy.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Yangi xatlov',
                style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Geolokatsiya va oila ma\'lumotlari',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.6),
            size: 16,
          ),
        ]),
      ),
    );
  }

  Future<void> _openAddPage(BuildContext context, AppProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFamilyPage()),
    );
    if (result == true && context.mounted) provider.fetchHouseholds();
  }

  Future<void> _openEditPage(
    BuildContext context,
    HouseholdModel h,
    AppProvider provider,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)),
    );
    if (result == true && context.mounted) provider.fetchHouseholds();
  }
}
