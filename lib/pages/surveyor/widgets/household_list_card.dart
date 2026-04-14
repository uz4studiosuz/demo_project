import 'package:flutter/material.dart';
import '../../../models/household_model.dart';
import '../../../theme/colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  HouseholdListCard — Surveyor bosh sahifasidagi xonadon kartochkasi
// ═══════════════════════════════════════════════════════════════════════════

class HouseholdListCard extends StatelessWidget {
  final HouseholdModel household;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const HouseholdListCard({
    super.key,
    required this.household,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final h = household;
    final houseNum = h.houseNumber != null && h.houseNumber!.isNotEmpty
        ? '${h.houseNumber}-uy'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_outlined, color: AppColors.govNavy, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  houseNum ?? h.officialAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [h.streetName, h.mfyName, h.tumanName]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' • '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${h.residents.length} nafar',
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.govNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Tahrir', style: TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600,
                    )),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
