import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../../../models/household_model.dart';
import '../../login/login_page.dart';
import '../../surveyor/households_map/households_map_page.dart';
import '../../surveyor/households_map/households_map_page.dart';
import '../../search/global_search_page.dart';
import 'nav_optionsheet.dart';
import '../../../widgets/household_info_sheet.dart';

class DriverHomeTab extends StatelessWidget {
  const DriverHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final households = provider.households;
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context, provider.currentUser?.fullName ?? 'Haydovchi'),
              _buildSearchTrigger(context, households),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: HouseholdsMapPage(
                    onGetDirections: (h) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => NavOptionsSheet(
                          household: h,
                          targetResident: h.residents.isNotEmpty ? h.residents.first : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
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

  Widget _buildSearchTrigger(BuildContext context, List<HouseholdModel> households) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalSearchPage(
              households: households,
              actionIcon: Icons.directions_car_rounded,
              onActionTap: (h, r) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => NavOptionsSheet(
                    household: h,
                    targetResident: r ?? (h.residents.isNotEmpty ? h.residents.first : null),
                  ),
                );
              },
              onResultTap: (h) {
                showHouseholdInfoSheet(
                  context,
                  h,
                  onGetDirections: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => NavOptionsSheet(
                        household: h,
                        targetResident: h.residents.isNotEmpty ? h.residents.first : null,
                      ),
                    );
                  },
                );
              },
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
            ],
          ),
        ),
      ),
    );
  }
}
