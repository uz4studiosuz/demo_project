import 'package:flutter/material.dart';
import '../../../models/household_model.dart';
import '../../../models/resident_model.dart';
import '../../../theme/colors.dart';
import '../utils/navigation_helpers.dart';

class NavigationOverlay extends StatefulWidget {
  final bool isNavigationStarted;
  final List<dynamic> turnSteps;
  final double topPad;
  final HouseholdModel? household;
  final ResidentModel? targetResident;
  final VoidCallback onShowFamilyMembers;

  const NavigationOverlay({
    super.key,
    required this.isNavigationStarted,
    required this.turnSteps,
    required this.topPad,
    this.household,
    this.targetResident,
    required this.onShowFamilyMembers,
  });

  @override
  State<NavigationOverlay> createState() => _NavigationOverlayState();
}

class _NavigationOverlayState extends State<NavigationOverlay> {
  bool _isPatientInfoExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isNavigationStarted || widget.turnSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    final turnSteps = widget.turnSteps;
    final topPad = widget.topPad;

    return Stack(
      children: [
        if (turnSteps.length > 1)
          // ─── YUQORI PANEL: "500 m dan keyin ↰" ─────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF1B8D5B),
              padding: EdgeInsets.only(
                top: topPad + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${formatDistance(turnSteps[0]['distance'] ?? 0)} dan keyin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    getStepIcon(
                      turnSteps[1]['maneuver']['type'] ?? '',
                      turnSteps[1]['maneuver']['modifier'] ?? '',
                    ),
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),
          )
        else
          // Agar faqat bitta step qolgan bo'lsa (manzilga yetib kelish)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF1B8D5B),
              padding: EdgeInsets.only(
                top: topPad + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Center(
                child: Text(
                  translateManeuver(
                    turnSteps[0]['maneuver']['type'] ?? '',
                    turnSteps[0]['maneuver']['modifier'] ?? '',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),

        // ─── Bemor haqida ma'lumot (Patient info) ───────────
        if (widget.targetResident != null || widget.household != null)
          Positioned(
            top: topPad + (turnSteps.length > 1 ? 144 : 86),
            left: 12,
            child: GestureDetector(
              onTap: () => setState(
                () => _isPatientInfoExpanded = !_isPatientInfoExpanded,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isPatientInfoExpanded ? 220 : 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isPatientInfoExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.targetResident?.gender == 'FEMALE'
                                    ? Icons.person_outline
                                    : Icons.person,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.targetResident?.displayFullName ??
                                      'Bemor',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _isPatientInfoExpanded = false,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (widget.targetResident != null)
                            Text(
                              '${widget.targetResident!.birthDate != null ? "${DateTime.now().year - widget.targetResident!.birthDate!.year} yosh" : ""} • ${widget.targetResident!.role ?? ""}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 30,
                            child: OutlinedButton(
                              onPressed: widget.onShowFamilyMembers,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                              ),
                              child: const Text(
                                "Oila a'zolarini ko'rish",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.targetResident?.gender == 'FEMALE'
                                ? Icons.person_outline
                                : Icons.person,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Bemor',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
