import 'package:flutter/material.dart';
import '../../../models/household_model.dart';
import '../../../theme/colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  BuildingBottomSheet — Ko'p qavatli bino qavat/kvartira ko'rinishi
//  Surveyor va Driver dashboard larda umumiy ishlatiladi.
//  onTapApartment — kvartira bosilganda chaqiriladi (Navigator.pop ichida)
// ═══════════════════════════════════════════════════════════════════════════

class BuildingBottomSheet {
  static void show(
    BuildContext context,
    List<HouseholdModel> apartments, {
    required void Function(HouseholdModel apt) onTapApartment,
  }) {
    final floorsMap = <int, List<HouseholdModel>>{};
    for (final apt in apartments) {
      final f = apt.floor ?? 0;
      floorsMap.putIfAbsent(f, () => []).add(apt);
    }
    final sortedFloors = floorsMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${apartments.first.buildingNumber ?? "?"}–bino',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      if (apartments.first.mfyName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${apartments.first.tumanName ?? ''} | ${apartments.first.mfyName} | ${apartments.first.streetName ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Jami ${apartments.length} ta xonadon ro\'yxatga olingan',
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedFloors.length,
                itemBuilder: (context, i) {
                  final floor = sortedFloors[i];
                  final apts = floorsMap[floor]!;
                  apts.sort((a, b) {
                    final numA = int.tryParse(a.apartment ?? '') ?? 0;
                    final numB = int.tryParse(b.apartment ?? '') ?? 0;
                    return numA.compareTo(numB);
                  });

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Qavat ko'rsatkichi (chap tomonda) ──
                          Container(
                            width: 56,
                            decoration: BoxDecoration(
                              color: AppColors.govNavy.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(16),
                              ),
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  floor == 0 ? '?' : '$floor',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColors.govNavy,
                                  ),
                                ),
                                const Text(
                                  'qavat',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ── Xonadonlar (o'ng tomonda) ──
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: apts.map((apt) {
                                  final head = apt.residents.isNotEmpty
                                      ? apt.residents.first
                                      : null;
                                  final hasHead = head != null;

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      onTapApartment(apt);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: hasHead
                                                  ? const Color(0xFFF1F8E9)
                                                  : const Color(0xFFF5F6F8),
                                              border: Border.all(
                                                color: hasHead
                                                    ? const Color(
                                                        0xFFAED581,
                                                      ).withValues(alpha: 0.5)
                                                    : Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                apt.apartment ?? '?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: hasHead
                                                      ? const Color(0xFF33691E)
                                                      : AppColors.textMain,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hasHead
                                                      ? '${head.lastName} ${head.firstName}'
                                                      : 'Ma\'lumot kiritilmagan',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: hasHead
                                                        ? AppColors.textMain
                                                        : AppColors
                                                              .textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  hasHead
                                                      ? '${apt.residents.length} nafar aholi'
                                                      : 'Bo\'sh xonadon',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: hasHead
                                                        ? AppColors
                                                              .textSecondary
                                                        : Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: AppColors.textSecondary,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
