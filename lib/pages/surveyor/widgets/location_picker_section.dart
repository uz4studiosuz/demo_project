import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../utils/location_data.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LocationPickerSection — Smart hudud tanlash
//  • "Farg'ona viloyati" bilan boshlangich manzil
//  • Shahar tanlansa → shahar MFY lari ko'rinadi
//  • Tuman tanlansa → qishloq MFY lari ko'rinadi
//  • Ketma-ketlik: Tuman/Shahar → MFY → Ko'cha
// ═══════════════════════════════════════════════════════════════════════════

class LocationPickerSection extends StatefulWidget {
  final Function(
    String? tuman,
    String? qfy,
    String? mfy,
    String? street,
    String fullAddress,
  ) onAddressChanged;

  final String? initialTuman;
  final String? initialMfy;
  final String? initialStreet;

  const LocationPickerSection({
    super.key,
    required this.onAddressChanged,
    this.initialTuman,
    this.initialMfy,
    this.initialStreet,
  });

  @override
  State<LocationPickerSection> createState() => _LocationPickerSectionState();
}

class _LocationPickerSectionState extends State<LocationPickerSection> {
  String? _selectedTuman;
  String? _selectedMfy;
  String? _selectedStreet;

  @override
  void initState() {
    super.initState();
    _selectedTuman  = widget.initialTuman;
    _selectedMfy    = widget.initialMfy;
    _selectedStreet = widget.initialStreet;
  }

  bool get _isCity => _selectedTuman != null && LocationData.isCity(_selectedTuman!);

  List<String> get _availableMfys =>
      _selectedTuman != null ? (LocationData.mfylar[_selectedTuman!] ?? []) : [];

  String get _builtAddress {
    final parts = <String>['Farg\'ona viloyati'];
    if (_selectedTuman != null) parts.add(_selectedTuman!);
    if (_selectedMfy != null)   parts.add(_selectedMfy!);
    if (_selectedStreet != null) parts.add(_selectedStreet!);
    return parts.join(', ');
  }

  void _notify() {
    widget.onAddressChanged(
      _selectedTuman,
      null, // qfy ishlatilmaydi, lekin signature saqlanadi
      _selectedMfy,
      _selectedStreet,
      _builtAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Viloyat — har doim ko'rsatiladi, o'zgartirib bo'lmaydi
        _readOnlyChip(
          label: 'Viloyat',
          value: 'Farg\'ona viloyati',
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 12),

        // ── 1. Tuman / Shahar ──────────────────────────────
        _dropdownField<String>(
          label: 'Tuman / Shahar *',
          icon: Icons.location_city_outlined,
          value: _selectedTuman,
          items: LocationData.allLocations,
          onChanged: (val) {
            setState(() {
              _selectedTuman  = val;
              _selectedMfy    = null;
              _selectedStreet = null;
            });
            _notify();
          },
          hint: 'Tuman yoki shaharni tanlang',
        ),

        if (_selectedTuman != null) ...[
          const SizedBox(height: 8),
          // Shahar/Tuman belgisi
          _typeBadge(_isCity),
        ],

        const SizedBox(height: 12),

        // ── 2. MFY ────────────────────────────────────────
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _selectedTuman != null ? 1.0 : 0.4,
          child: _dropdownField<String>(
            label: _isCity ? 'Mahalla (MFY) *' : 'Qishloq / MFY *',
            icon: Icons.groups_outlined,
            value: _selectedMfy,
            items: _availableMfys,
            enabled: _selectedTuman != null,
            onChanged: (val) {
              setState(() {
                _selectedMfy    = val;
                _selectedStreet = null;
              });
              _notify();
            },
            hint: _selectedTuman == null
                ? 'Avval tuman/shahar tanlang'
                : (_isCity ? 'Mahalla (MFY) ni tanlang' : 'Qishloq/MFY ni tanlang'),
          ),
        ),

        const SizedBox(height: 12),

        // ── 3. Ko'cha ─────────────────────────────────────
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _selectedMfy != null ? 1.0 : 0.4,
          child: _dropdownField<String>(
            label: 'Ko\'cha nomi',
            icon: Icons.add_road_outlined,
            value: _selectedStreet,
            items: _selectedMfy != null ? (LocationData.kochalar[_selectedMfy!] ?? []) : [],
            enabled: _selectedMfy != null,
            onChanged: (val) {
              setState(() => _selectedStreet = val);
              _notify();
            },
            hint: _selectedMfy == null ? 'Avval MFY ni tanlang' : 'Ko\'cha nomini tanlang',
          ),
        ),

        const SizedBox(height: 16),

        // ── To'liq rasmiy manzil (auto-generated) ─────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.govNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.govNavy.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home_outlined, size: 18, color: AppColors.govNavy.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To\'liq rasmiy manzil',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _builtAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _readOnlyChip({required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.govNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.govNavy.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.govNavy),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.govNavy, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 14, color: AppColors.govNavy.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _typeBadge(bool isCity) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCity ? const Color(0xFF1565C0).withValues(alpha: 0.08) : const Color(0xFF2E7D32).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCity ? Icons.location_city : Icons.nature_people_outlined,
                size: 13,
                color: isCity ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 4),
              Text(
                isCity ? 'Shahar hududi' : 'Tuman hududi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCity ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdownField<T extends Object>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: enabled ? AppColors.govNavy : AppColors.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        filled: true,
        fillColor: enabled ? const Color(0xFFF5F6F8) : const Color(0xFFF0F0F0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.govNavy, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString(), style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
