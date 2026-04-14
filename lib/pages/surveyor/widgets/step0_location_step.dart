import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';

import 'surveyor_form_widgets.dart';
import 'location_picker_section.dart';
import 'map_preview_picker.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Step0LocationStep — Manzil va joylashuv (AddFamilyPage Step 0)
//
//  Bug Fix: mavjud bino dropdown faqat ko'cha tanlanganda ko'rinadi.
//  Bu boshqa lokatsiyada bir xil bino raqami bo'lsa ham muammosiz
//  yangi bino raqami kiritishni ta'minlaydi.
//
//  Pin Icon Fix: lokatsiya bannerida Icons.location_pin ishlatiladi.
// ═══════════════════════════════════════════════════════════════════════════

class Step0LocationStep extends StatelessWidget {
  final String propertyType;
  final String? tuman;
  final String? mfy;
  final String? street;
  final TextEditingController houseCtrl;
  final TextEditingController buildingCtrl;
  final TextEditingController apartmentCtrl;
  final TextEditingController floorCtrl;
  final LatLng position;
  final String? copiedFromBuildingKey;

  // Callbacks
  final void Function(String newType) onPropertyTypeChanged;
  final void Function(String? t, String? q, String? m, String? s, String addr)
      onAddressChanged;
  final void Function(String? key, HouseholdModel? src) onBuildingKeySelected;
  final void Function(LatLng pos) onPositionChanged;
  final VoidCallback onOpenFullScreenMap;

  const Step0LocationStep({
    super.key,
    required this.propertyType,
    required this.tuman,
    required this.mfy,
    required this.street,
    required this.houseCtrl,
    required this.buildingCtrl,
    required this.apartmentCtrl,
    required this.floorCtrl,
    required this.position,
    required this.copiedFromBuildingKey,
    required this.onPropertyTypeChanged,
    required this.onAddressChanged,
    required this.onBuildingKeySelected,
    required this.onPositionChanged,
    required this.onOpenFullScreenMap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          SurveyorFormWidgets.card(
            icon: Icons.house_outlined,
            title: 'Mulk turi',
            child: _PropertyTypeToggle(
              propertyType: propertyType,
              onChanged: onPropertyTypeChanged,
            ),
          ),
          const SizedBox(height: 12),
          SurveyorFormWidgets.card(
            icon: Icons.location_on_outlined,
            title: 'Hudud ma\'lumotlari',
            child: LocationPickerSection(
              initialTuman: tuman,
              initialMfy: mfy,
              initialStreet: street,
              onAddressChanged: onAddressChanged,
            ),
          ),
          const SizedBox(height: 12),
          SurveyorFormWidgets.card(
            icon: propertyType == kHouse
                ? Icons.home_outlined
                : Icons.apartment_outlined,
            title: propertyType == kHouse
                ? 'Uy ma\'lumotlari'
                : 'Kvartira ma\'lumotlari',
            child: _PropertyDetails(
              propertyType: propertyType,
              tuman: tuman,
              mfy: mfy,
              street: street,
              houseCtrl: houseCtrl,
              buildingCtrl: buildingCtrl,
              apartmentCtrl: apartmentCtrl,
              floorCtrl: floorCtrl,
              copiedFromBuildingKey: copiedFromBuildingKey,
              onBuildingKeySelected: onBuildingKeySelected,
            ),
          ),
          const SizedBox(height: 12),
          if (propertyType == kApartment && copiedFromBuildingKey != null)
            _SelectedBuildingBanner(
              onClear: () => onBuildingKeySelected(null, null),
            )
          else
            _MapSection(
              position: position,
              onPositionChanged: onPositionChanged,
              onOpenFullScreenMap: onOpenFullScreenMap,
            ),
        ],
      ),
    );
  }
}

// ─── Mulk turi toggle ────────────────────────────────────────────────────
class _PropertyTypeToggle extends StatelessWidget {
  final String propertyType;
  final void Function(String) onChanged;

  const _PropertyTypeToggle({
    required this.propertyType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PropTypeBtn(
          type: kHouse,
          icon: Icons.home_outlined,
          label: 'Xonadon\n(alohida uy)',
          activeType: propertyType,
          onTap: onChanged,
        ),
        const SizedBox(width: 10),
        _PropTypeBtn(
          type: kApartment,
          icon: Icons.apartment_outlined,
          label: 'Kvartira\n(ko\'p qavatli)',
          activeType: propertyType,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _PropTypeBtn extends StatelessWidget {
  final String type;
  final IconData icon;
  final String label;
  final String activeType;
  final void Function(String) onTap;

  const _PropTypeBtn({
    required this.type,
    required this.icon,
    required this.label,
    required this.activeType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.govNavy : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mulk tafsilotlari (uy yoki kvartira) ──────────────────────────────
class _PropertyDetails extends StatelessWidget {
  final String propertyType;
  final String? tuman;
  final String? mfy;
  final String? street;
  final TextEditingController houseCtrl;
  final TextEditingController buildingCtrl;
  final TextEditingController apartmentCtrl;
  final TextEditingController floorCtrl;
  final String? copiedFromBuildingKey;
  final void Function(String? key, HouseholdModel? src) onBuildingKeySelected;

  const _PropertyDetails({
    required this.propertyType,
    required this.tuman,
    required this.mfy,
    required this.street,
    required this.houseCtrl,
    required this.buildingCtrl,
    required this.apartmentCtrl,
    required this.floorCtrl,
    required this.copiedFromBuildingKey,
    required this.onBuildingKeySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (propertyType == kHouse) {
      return SurveyorFormWidgets.field(
        label: 'Uy raqami (masalan: 45A)',
        icon: Icons.home_outlined,
        controller: houseCtrl,
      );
    }

    // ── APARTMENT holati ──
    // Bug Fix: ko'cha tanlanmasa — dropdown ko'rsatilmaydi
    final provider = Provider.of<AppProvider>(context, listen: false);
    final existingBuildings = <String, HouseholdModel>{};

    if (tuman != null && mfy != null && street != null) {
      for (final h in provider.households) {
        if (h.propertyType != kApartment) continue;
        if (h.tumanName != tuman || h.mfyName != mfy || h.streetName != street) continue;
        final key =
            '${h.buildingNumber ?? "?"}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
        existingBuildings.putIfAbsent(key, () => h);
      }
    }

    return Column(
      children: [
        if (existingBuildings.isNotEmpty) ...[
          _BuildingDropdown(
            buildings: existingBuildings,
            copiedFromBuildingKey: copiedFromBuildingKey,
            onChanged: onBuildingKeySelected,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: SurveyorFormWidgets.field(
                label: 'Bino raqami',
                icon: Icons.apartment_outlined,
                controller: buildingCtrl,
                readOnly: copiedFromBuildingKey != null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SurveyorFormWidgets.field(
                label: 'Qavat',
                icon: Icons.stairs_outlined,
                keyboardType: TextInputType.number,
                controller: floorCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SurveyorFormWidgets.field(
          label: 'Kvartira raqami',
          icon: Icons.door_front_door_outlined,
          controller: apartmentCtrl,
        ),
      ],
    );
  }
}

// ─── Mavjud bino dropdown ─────────────────────────────────────────────────
class _BuildingDropdown extends StatelessWidget {
  final Map<String, HouseholdModel> buildings;
  final String? copiedFromBuildingKey;
  final void Function(String? key, HouseholdModel? src) onChanged;

  const _BuildingDropdown({
    required this.buildings,
    required this.copiedFromBuildingKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF388E3C)),
              SizedBox(width: 6),
              Text(
                'Mavjud binoni tanlang',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: copiedFromBuildingKey,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Bino tanlang...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Yangi bino')),
              ...buildings.entries.map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.value.buildingNumber ?? "?"}-bino'),
                ),
              ),
            ],
            onChanged: (key) {
              if (key != null) {
                onChanged(key, buildings[key]);
              } else {
                onChanged(null, null);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Tanlangan bino banneri ───────────────────────────────────────────────
class _SelectedBuildingBanner extends StatelessWidget {
  final VoidCallback onClear;

  const _SelectedBuildingBanner({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Bug Fix: location_on → location_pin (uchi tog'ri nuqtani ko'rsatadi)
          const Icon(Icons.location_pin, color: Color(0xFF1976D2)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Lokatsiya binodan olindi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('O\'zgartirish'),
          ),
        ],
      ),
    );
  }
}

// ─── Xarita bo'limi ───────────────────────────────────────────────────────
class _MapSection extends StatelessWidget {
  final LatLng position;
  final void Function(LatLng) onPositionChanged;
  final VoidCallback onOpenFullScreenMap;

  const _MapSection({
    required this.position,
    required this.onPositionChanged,
    required this.onOpenFullScreenMap,
  });

  @override
  Widget build(BuildContext context) {
    return SurveyorFormWidgets.card(
      icon: Icons.map_outlined,
      title: 'Geolokatsiya',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenFullScreenMap,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Kartadan tanlash'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.govNavy,
                    side: const BorderSide(color: AppColors.govNavy),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: MapPreviewPicker(
                initialPosition: position,
                onPositionChanged: onPositionChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
