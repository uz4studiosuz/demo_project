import 'package:beemor/pages/surveyor/patient_list/patient_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/colors.dart';
import 'lite_add_family_page.dart';
import 'lite_record_list_page.dart';
import '../../pages/surveyor/households_map/households_map_page.dart';

class LiteDashboardPage extends StatefulWidget {
  const LiteDashboardPage({super.key});

  @override
  State<LiteDashboardPage> createState() => _LiteDashboardPageState();
}

class _LiteDashboardPageState extends State<LiteDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchHouseholds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lite Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.govNavy,
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final count = provider.households.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(provider),
                const SizedBox(height: 24),
                _buildStatsCard(count),
                const SizedBox(height: 32),
                _buildActionCard(
                  title: 'Yangi xatlov qo\'shish',
                  subtitle: 'Tezkor va sodda kiritish',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.govNavy,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiteAddFamilyPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Kiritilganlar ro\'yxati',
                  subtitle: 'Barcha yozuvlarni ko\'rish',
                  icon: Icons.list_alt_rounded,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientListPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Xaritada ko\'rish',
                  subtitle: 'Kiritilgan honadonlar xaritasi',
                  icon: Icons.map_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HouseholdsMapPage(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xush kelibsiz,',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        Text(
          provider.currentUser?.fullName ?? 'Foydalanuvchi',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.govNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.govNavy, Color(0xFF004D99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.govNavy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kiritilgan honadonlar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ta xonadon',
                style: TextStyle(color: Colors.white60, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
