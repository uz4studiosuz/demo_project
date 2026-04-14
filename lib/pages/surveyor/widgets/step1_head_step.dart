import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import 'surveyor_form_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Step1HeadStep — Oila boshlig'i ma'lumotlari (AddFamilyPage Step 1)
// ═══════════════════════════════════════════════════════════════════════════

class Step1HeadStep extends StatelessWidget {
  final TextEditingController headFirstCtrl;
  final TextEditingController headLastCtrl;
  final TextEditingController headMiddleCtrl;
  final TextEditingController headPhoneCtrl;
  final String headGender;
  final void Function(String) onGenderChanged;

  const Step1HeadStep({
    super.key,
    required this.headFirstCtrl,
    required this.headLastCtrl,
    required this.headMiddleCtrl,
    required this.headPhoneCtrl,
    required this.headGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SurveyorFormWidgets.card(
        icon: Icons.person_outline_rounded,
        title: 'Oila boshlig\'i',
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SurveyorFormWidgets.formField(
                    headLastCtrl,
                    'Familiyasi',
                    required: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SurveyorFormWidgets.formField(
                    headFirstCtrl,
                    'Ismi',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SurveyorFormWidgets.formField(
              headMiddleCtrl,
              'Sharifi (Otchestvasi)',
            ),
            const SizedBox(height: 10),
            _GenderSelector(value: headGender, onChanged: onGenderChanged),
            const SizedBox(height: 12),
            SurveyorFormWidgets.formField(
              headPhoneCtrl,
              'Telefon',
              icon: Icons.phone_android_rounded,
              keyboard: TextInputType.phone,
              required: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gender selector (ichki widget) ──────────────────────────────────────
class _GenderSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _GenderSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['MALE', 'FEMALE'].map((g) {
        final active = value == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(g),
            child: Container(
              margin: EdgeInsets.only(right: g == 'MALE' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                g == 'MALE' ? Icons.man : Icons.woman,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
