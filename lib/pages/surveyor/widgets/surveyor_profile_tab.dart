import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../../login.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SurveyorProfileTab — Surveyor Dashboard Tab 3 (Profil)
// ═══════════════════════════════════════════════════════════════════════════

class SurveyorProfileTab extends StatelessWidget {
  const SurveyorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final name = provider.currentUser?.fullName ?? 'Hatlovchi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.manage_accounts, color: AppColors.govNavy, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.govNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hatlovchi',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    label: const Text(
                      'Tizimdan chiqish',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
