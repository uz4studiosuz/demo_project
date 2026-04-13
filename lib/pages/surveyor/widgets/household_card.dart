import 'package:flutter/material.dart';
import '../../../models/household_model.dart';
import '../../../models/resident_model.dart';
import '../../../theme/colors.dart';

class HouseholdCard extends StatelessWidget {
  final HouseholdModel household;
  final VoidCallback? onTap;

  const HouseholdCard({super.key, required this.household, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_city, color: AppColors.primary),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  household.officialAddress.isEmpty
                      ? 'Manzilsiz Xonadon'
                      : household.officialAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
                if (household.mfyName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${household.tumanName ?? ''} | ${household.mfyName} | ${household.streetName ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${household.residents.length} kishi',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            children: household.residents
                .map((resident) => _buildResidentItem(resident))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildResidentItem(ResidentModel resident) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(
              resident.gender == 'FEMALE' ? Icons.woman : Icons.man,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident.displayFullName.isEmpty
                      ? 'Noma\'lum shaxs'
                      : resident.displayFullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  resident.role ?? 'Oila a\'zosi',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
