import 'package:flutter/material.dart';
import '../models/household_model.dart';
import '../theme/colors.dart';

class HouseholdCard extends StatelessWidget {
  final HouseholdModel household;
  final VoidCallback? onTap;

  const HouseholdCard({
    super.key,
    required this.household,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHighRisk = household.residents.any((r) => r.isHighRiskMock);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasHighRisk ? AppColors.danger : Colors.grey.withValues(alpha: 0.1),
            width: hasHighRisk ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasHighRisk
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_filled,
                  color: hasHighRisk ? AppColors.danger : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household.officialAddress.isEmpty
                          ? 'Manzil kiritilmagan'
                          : household.officialAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oila a\'zolari: ${household.residents.length} ta',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
