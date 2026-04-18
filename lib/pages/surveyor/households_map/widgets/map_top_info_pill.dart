import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../models/household_model.dart';
import '../../../../theme/colors.dart';

class MapTopInfoPill extends StatelessWidget {
  final HouseholdModel? focusHousehold;
  final int householdsCount;
  final double currentZoom;
  final VoidCallback onBack;

  const MapTopInfoPill({
    super.key,
    required this.focusHousehold,
    required this.householdsCount,
    required this.currentZoom,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                if (focusHousehold != null) ...[
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.govNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.govNavy,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(
                    Icons.map_outlined,
                    color: AppColors.govNavy,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: focusHousehold != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              focusHousehold!.officialAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${focusHousehold!.residents.length} nafar aholi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Xaritada $householdsCount ta xonadon',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentZoom < 11
                        ? 'Tumanlar'
                        : currentZoom < 12.5
                            ? 'MFYlar'
                            : currentZoom < 15
                                ? 'Ko\'chalar'
                                : 'Xonadonlar',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.govNavy,
                      fontWeight: FontWeight.w600,
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
