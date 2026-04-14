import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import 'surveyor_form_widgets.dart';

class MemberCardWidget extends StatelessWidget {
  final int index;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController middleCtrl;
  final TextEditingController phoneCtrl;
  final String gender;
  final String role;
  final bool showPhone;
  final DateTime? birthDate;
  final List<String> roles;
  final List<String> cachedFirstNames;
  final List<String> cachedLastNames;
  final List<String> cachedMiddleNames;
  final VoidCallback onRemove;
  final void Function(String) onGenderChanged;
  final void Function(String) onRoleChanged;
  final void Function(bool) onPhoneToggle;
  final void Function(DateTime?) onBirthDateChanged;

  const MemberCardWidget({
    super.key,
    required this.index,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.middleCtrl,
    required this.phoneCtrl,
    required this.gender,
    required this.role,
    required this.showPhone,
    required this.roles,
    required this.onRemove,
    required this.onGenderChanged,
    required this.onRoleChanged,
    required this.onPhoneToggle,
    required this.onBirthDateChanged,
    this.birthDate,
    this.cachedFirstNames = const [],
    this.cachedLastNames = const [],
    this.cachedMiddleNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SurveyorFormWidgets.card(
      icon: Icons.person_add_alt_1_rounded,
      title: '${index + 1}-oila a\'zosi',
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SurveyorFormWidgets.formField(
                      lastCtrl,
                      'Familiyasi',
                      suggestions: cachedLastNames,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SurveyorFormWidgets.formField(
                      firstCtrl,
                      'Ismi',
                      suggestions: cachedFirstNames,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SurveyorFormWidgets.formField(
                middleCtrl,
                'Sharifi (Otchestvasi)',
                suggestions: cachedMiddleNames,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _genderToggle()),
                  const SizedBox(width: 10),
                  Expanded(child: _roleDropdown()),
                ],
              ),
              const SizedBox(height: 10),
              SurveyorFormWidgets.datePicker(
                context,
                selectedDate: birthDate,
                onChanged: onBirthDateChanged,
              ),
              const SizedBox(height: 12),
              _phoneSection(),
            ],
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _genderBtn('MALE', Icons.man),
          _genderBtn('FEMALE', Icons.woman),
        ],
      ),
    );
  }

  Widget _genderBtn(String g, IconData icon) {
    final active = gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => onGenderChanged(g),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                : null,
          ),
          child: Icon(icon, size: 20, color: active ? AppColors.govNavy : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppColors.textMain),
          onChanged: (v) {
            if (v != null) onRoleChanged(v);
          },
          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        ),
      ),
    );
  }

  Widget _phoneSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Telefon raqami mavjud',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: showPhone,
                onChanged: onPhoneToggle,
                activeColor: AppColors.govNavy,
              ),
            ),
          ],
        ),
        if (showPhone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SurveyorFormWidgets.formField(
              phoneCtrl,
              'Telefon raqami',
              icon: Icons.phone_android_rounded,
              keyboard: TextInputType.phone,
            ),
          ),
      ],
    );
  }
}

