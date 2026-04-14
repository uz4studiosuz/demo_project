import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import 'member_card_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Step2MembersStep — Qo'shimcha oila a'zolari (AddFamilyPage Step 2)
// ═══════════════════════════════════════════════════════════════════════════

class MemberData {
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController middleCtrl;
  final TextEditingController phoneCtrl;
  bool showPhone;
  String gender;
  String role;
  DateTime? birthDate;

  MemberData({
    required this.firstCtrl,
    required this.lastCtrl,
    required this.middleCtrl,
    required this.phoneCtrl,
    this.showPhone = false,
    this.gender = 'MALE',
    this.role = 'Turmush o\'rtog\'i',
    this.birthDate,
  });
}

class Step2MembersStep extends StatelessWidget {
  final List<MemberData> members;
  final List<String> roles;
  final VoidCallback onAddMember;
  final void Function(int index) onRemoveMember;
  final void Function(int index, String gender) onGenderChanged;
  final void Function(int index, String role) onRoleChanged;
  final void Function(int index, bool show) onPhoneToggle;
  final void Function(int index, DateTime? date) onBirthDateChanged;
  final List<String> cachedFirstNames;
  final List<String> cachedLastNames;
  final List<String> cachedMiddleNames;

  const Step2MembersStep({
    super.key,
    required this.members,
    required this.roles,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onGenderChanged,
    required this.onRoleChanged,
    required this.onPhoneToggle,
    required this.onBirthDateChanged,
    this.cachedFirstNames = const [],
    this.cachedLastNames = const [],
    this.cachedMiddleNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddMember,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Oila a\'zosi qo\'shish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.govNavy,
                side: const BorderSide(color: AppColors.govNavy),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCardWidget(
                index: i,
                firstCtrl: members[i].firstCtrl,
                lastCtrl: members[i].lastCtrl,
                middleCtrl: members[i].middleCtrl,
                phoneCtrl: members[i].phoneCtrl,
                gender: members[i].gender,
                role: members[i].role,
                showPhone: members[i].showPhone,
                roles: roles,
                cachedFirstNames: cachedFirstNames,
                cachedLastNames: cachedLastNames,
                cachedMiddleNames: cachedMiddleNames,
              birthDate: members[i].birthDate,
                onRemove: () => onRemoveMember(i),
                onGenderChanged: (g) => onGenderChanged(i, g),
                onRoleChanged: (r) => onRoleChanged(i, r),
                onPhoneToggle: (v) => onPhoneToggle(i, v),
                onBirthDateChanged: (d) => onBirthDateChanged(i, d),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
