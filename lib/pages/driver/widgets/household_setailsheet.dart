// ═══════════════════════════════════════════════════════════════════════════
//  HOUSEHOLD DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════

import 'package:beemor/models/household_model.dart';
import 'package:beemor/models/resident_model.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class HouseholdDetailSheet extends StatelessWidget {
  final HouseholdModel household;
  final void Function(ResidentModel?) onNavigate;
  const HouseholdDetailSheet({
    super.key,
    required this.household,
    required this.onNavigate,
  });

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
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: AppColors.govNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        household.officialAddress.isEmpty
                            ? 'Manzilsiz'
                            : household.officialAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        [
                          household.tumanName,
                          household.mfyName,
                          household.streetName,
                        ].where((e) => e != null && e.isNotEmpty).join(' • '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    [
                      r.role,
                      r.phonePrimary,
                    ].where((e) => e != null && e!.isNotEmpty).join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Material(
                    color: AppColors.govNavy.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onNavigate(r),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.govNavy,
                          size: 18,
                        ),
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
                  household.residents.isNotEmpty
                      ? household.residents.first
                      : null,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text(
                  'Yo\'nalish olish',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.govNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
