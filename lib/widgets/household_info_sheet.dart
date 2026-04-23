import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../theme/colors.dart';

// ─── Open from anywhere ───────────────────────────────────────────────────
void showHouseholdInfoSheet(
  BuildContext context,
  HouseholdModel household, {
  VoidCallback? onGetDirections,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _HouseholdInfoSheet(
      household: household,
      onGetDirections: onGetDirections,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

// ─── Sheet widget ─────────────────────────────────────────────────────────
class _HouseholdInfoSheet extends StatelessWidget {
  final HouseholdModel household;
  final VoidCallback? onGetDirections;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _HouseholdInfoSheet({
    required this.household,
    this.onGetDirections,
    this.onEdit,
    this.onDelete,
  });

  // Yosh hisoblash
  int? _age(DateTime? bDay) {
    if (bDay == null) return null;
    final now = DateTime.now();
    int age = now.year - bDay.year;
    if (now.month < bDay.month ||
        (now.month == bDay.month && now.day < bDay.day))
      age--;
    return age;
  }

  // Sana formatlash: "15-may, 2003"
  String _fmtDate(DateTime d) {
    const months = [
      'yanvar',
      'fevral',
      'mart',
      'aprel',
      'may',
      'iyun',
      'iyul',
      'avgust',
      'sentabr',
      'oktabr',
      'noyabr',
      'dekabr',
    ];
    return '${d.day}-${months[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final h = household;
    final bool isApt = h.propertyType == kApartment;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ── Header card
          Stack(
            children: [
              _HeaderCard(household: h, isApt: isApt),
              if (kIsWeb)
                Positioned(
                  top: 12,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),

          // ── Residents list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: h.residents.length,
              itemBuilder: (_, i) {
                final r = h.residents[i];
                final age = _age(r.birthDate);
                final isHead = r.role == 'Oila boshlig\'i';
                return _ResidentCard(
                  resident: r,
                  age: age,
                  isHead: isHead,
                  fmtDate: _fmtDate,
                );
              },
            ),
          ),

          if (onGetDirections != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    ); // Jo'nab ketishdan oldin oynani yopamiz
                    onGetDirections!();
                  },
                  icon: const Icon(CupertinoIcons.location_fill),
                  label: const Text(
                    'Yo\'nalish olish',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.govNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          if (onEdit != null || onDelete != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          'Tahrirlash',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.govNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 12),
                  if (onDelete != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          'O\'chirish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─── Header card ─────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final HouseholdModel household;
  final bool isApt;
  const _HeaderCard({required this.household, required this.isApt});

  @override
  Widget build(BuildContext context) {
    final h = household;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.govNavy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + address
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isApt ? Icons.apartment : Icons.home_rounded,
                  color: AppColors.govNavy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.tumanName ?? ''}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h.mfyName ?? ''}',
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
          const SizedBox(height: 14),
          // Detail chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (h.streetName != null)
                _Chip(icon: Icons.signpost_rounded, label: h.streetName!),
              if (!isApt && h.houseNumber != null)
                _Chip(
                  icon: Icons.cottage_rounded,
                  label: 'Uy: ${h.houseNumber}',
                ),
              if (isApt && h.buildingNumber != null)
                _Chip(
                  icon: Icons.domain_rounded,
                  label: '${h.buildingNumber}-bino',
                ),
              if (isApt && h.apartment != null)
                _Chip(
                  icon: Icons.door_front_door_rounded,
                  label: '${h.apartment}-kvartira',
                ),
              if (isApt && h.floor != null)
                _Chip(icon: Icons.layers_rounded, label: '${h.floor}-qavat'),
              _Chip(
                icon: Icons.people_rounded,
                label: '${h.residents.length} nafar',
                color: AppColors.govNavy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Resident card ─────────────────────────────────────────────────────────
class _ResidentCard extends StatelessWidget {
  final ResidentModel resident;
  final int? age;
  final bool isHead;
  final String Function(DateTime) fmtDate;

  const _ResidentCard({
    required this.resident,
    required this.age,
    required this.isHead,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    final r = resident;
    final bool isFemale = r.gender == 'FEMALE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHead
            ? Border.all(
                color: AppColors.govNavy.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isFemale
                  ? const Color(0xFFFCE4EC)
                  : AppColors.govNavy.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFemale ? Icons.woman_rounded : Icons.man_rounded,
              color: isFemale ? const Color(0xFFE91E63) : AppColors.govNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.displayFullName.isNotEmpty
                            ? r.displayFullName
                            : 'Ismsiz',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (isHead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '👑 Boshliq',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57F17),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Role
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_badge_plus,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.role ?? 'Oila a\'zosi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Birthday + age
                if (r.birthDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmtDate(r.birthDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (age != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.govNavy.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$age yosh',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.govNavy,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                // Phone
                if (r.phonePrimary != null &&
                    r.phonePrimary!.isNotEmpty &&
                    r.phonePrimary != '+998') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.phone,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r.phonePrimary!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small chip ────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
