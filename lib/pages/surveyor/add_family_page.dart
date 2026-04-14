import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/colors.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import 'widgets/map_preview_picker.dart';
import 'widgets/location_picker_section.dart';
import 'widgets/surveyor_form_widgets.dart';
import 'widgets/member_card_widget.dart';
import 'full_screen_map_picker.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ADD / EDIT FAMILY PAGE  —  Step-by-step UX, gobierno stili
//  existing != null → tahrirlash rejimi
// ═══════════════════════════════════════════════════════════════════════════

class AddFamilyPage extends StatefulWidget {
  final HouseholdModel? existing; // null → yangi, non-null → tahrirlash

  const AddFamilyPage({super.key, this.existing});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

// ─── Oila a'zosi modeli (ichki) ───────────────────────────────────────────
class _Member {
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController middleCtrl;
  final TextEditingController phoneCtrl;
  bool showPhone;
  String gender;
  String role;

  _Member({
    String firstName = '',
    String lastName = '',
    String middleName = '',
    String phone = '',
    this.showPhone = false,
    this.gender = 'MALE',
    this.role = 'Turmush o\'rtog\'i',
  }) : firstCtrl = TextEditingController(text: firstName),
       lastCtrl = TextEditingController(text: lastName),
       middleCtrl = TextEditingController(text: middleName),
       phoneCtrl = TextEditingController(
         text: phone.isEmpty ? '+998 ' : phone,
       ) {
    if (phone.isNotEmpty && phone != '+998 ') {
      showPhone = true;
    }
  }

  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    middleCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  // Steps: 0 = manzil, 1 = oila boshlig'i, 2 = a'zolar
  int _step = 0;
  bool get _isEdit => widget.existing != null;

  // ── Joylashuv ────────────────────────────────────────────────────
  String _propertyType = kHouse; // 'HOUSE' yoki 'APARTMENT'
  String? _tuman;
  String? _qfy;
  String? _mfy;
  String? _street;
  final _houseCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  String _officialAddress = '';
  LatLng _position = const LatLng(40.3864, 71.7825);
  // Mavjud bino kalit (Apartment uchun) — null → yangi lokatsiya
  String? _copiedFromBuildingKey;

  // ── Oila boshlig'i ───────────────────────────────────────────────
  final _headFirstCtrl = TextEditingController();
  final _headLastCtrl = TextEditingController();
  final _headMiddleCtrl = TextEditingController();
  final _headPhoneCtrl = TextEditingController(text: '+998 ');
  String _headGender = 'MALE';

  // ── Qo'shimcha a'zolar ───────────────────────────────────────────
  final List<_Member> _members = [];

  static const _roles = [
    'Turmush o\'rtog\'i',
    'Farzandi',
    'Otasi',
    'Onasi',
    'Akasi',
    'Ukasi',
    'Opasi',
    'Singlisi',
    'Bobosi',
    'Buvisi',
    'Boshqa',
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final h = widget.existing;
    if (h == null) return;

    // Manzil
    _propertyType = h.propertyType;
    _tuman = h.tumanName;
    _qfy = h.qfyName;
    _mfy = h.mfyName;
    _street = h.streetName;
    _houseCtrl.text = h.houseNumber ?? '';
    _buildingCtrl.text = h.buildingNumber ?? '';
    _apartmentCtrl.text = h.apartment ?? '';
    _floorCtrl.text = h.floor?.toString() ?? '';
    _officialAddress = h.officialAddress;
    _position = LatLng(h.latitude, h.longitude);

    // Oila boshlig'i
    final residents = h.residents;
    if (residents.isNotEmpty) {
      final head = residents.first;
      _headFirstCtrl.text = head.firstName;
      _headLastCtrl.text = head.lastName;
      _headMiddleCtrl.text = head.middleName ?? '';
      _headPhoneCtrl.text =
          (head.phonePrimary == null || head.phonePrimary!.isEmpty)
          ? '+998 '
          : head.phonePrimary!;
      _headGender = head.gender;
    }

    // Qolgan a'zolar
    for (int i = 1; i < residents.length; i++) {
      final r = residents[i];
      _members.add(
        _Member(
          firstName: r.firstName,
          lastName: r.lastName,
          middleName: r.middleName ?? '',
          phone: r.phonePrimary ?? '',
          gender: r.gender,
          role: r.role ?? 'Boshqa',
        ),
      );
    }
  }

  @override
  void dispose() {
    _headFirstCtrl.dispose();
    _headLastCtrl.dispose();
    _headMiddleCtrl.dispose();
    _headPhoneCtrl.dispose();
    _houseCtrl.dispose();
    _buildingCtrl.dispose();
    _apartmentCtrl.dispose();
    _floorCtrl.dispose();
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _openFullScreenMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPicker(initialPosition: _position),
      ),
    );

    if (result != null) {
      if (mounted) setState(() => _position = result);
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    final household = HouseholdModel(
      id: _isEdit ? widget.existing!.id : 0,
      regionId: 1,
      districtId: 1,
      createdByAgentId: provider.currentUser?.id ?? 0,
      officialAddress: _officialAddress.isEmpty
          ? '${_tuman ?? ''}, ${_street ?? ''}'.trim()
          : _officialAddress,
      propertyType: _propertyType,
      tumanName: _tuman,
      qfyName: _qfy,
      mfyName: _mfy,
      streetName: _street,
      houseNumber: _houseCtrl.text.trim().isEmpty
          ? null
          : _houseCtrl.text.trim(),
      buildingNumber: _buildingCtrl.text.trim().isEmpty
          ? null
          : _buildingCtrl.text.trim(),
      apartment: _apartmentCtrl.text.trim().isEmpty
          ? null
          : _apartmentCtrl.text.trim(),
      floor: int.tryParse(_floorCtrl.text.trim()),
      latitude: _position.latitude,
      longitude: _position.longitude,
      createdAt: _isEdit ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final residents = <ResidentModel>[
      ResidentModel(
        id: _isEdit && widget.existing!.residents.isNotEmpty
            ? widget.existing!.residents.first.id
            : 0,
        householdId: household.id,
        firstName: _headFirstCtrl.text.trim(),
        lastName: _headLastCtrl.text.trim(),
        middleName: _headMiddleCtrl.text.trim().isEmpty
            ? null
            : _headMiddleCtrl.text.trim(),
        phonePrimary: _headPhoneCtrl.text.trim() == '+998'
            ? null
            : _headPhoneCtrl.text.trim(),
        gender: _headGender,
        role: 'Oila boshlig\'i',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ..._members
          .where((m) => m.firstCtrl.text.trim().isNotEmpty)
          .map(
            (m) => ResidentModel(
              id: 0,
              householdId: household.id,
              firstName: m.firstCtrl.text.trim(),
              lastName: m.lastCtrl.text.trim(),
              middleName: m.middleCtrl.text.trim().isEmpty
                  ? null
                  : m.middleCtrl.text.trim(),
              phonePrimary: (m.phoneCtrl.text.trim() == '+998' || !m.showPhone)
                  ? null
                  : m.phoneCtrl.text.trim(),
              gender: m.gender,
              role: m.role,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
    ];

    bool ok;
    if (_isEdit) {
      ok = await provider.updateHouseholdWithResidents(household, residents);
    } else {
      ok = await provider.saveHouseholdWithResidents(household, residents);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        _snack(
          _isEdit ? 'Muvaffaqiyatli yangilandi!' : 'Muvaffaqiyatli saqlandi!',
          success: true,
        );
        Navigator.pop(context, true);
      } else {
        _snack('Saqlashda xatolik yuz berdi');
      }
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildStepsIndicator(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Components ───────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.govNavy,
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Xonadonni tahrirlash' : 'Yangi xatlov',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
                Text(
                  _stepTitle(_step),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_step + 1} / 3',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.govNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Manzil va joylashuv';
      case 1:
        return 'Oila boshlig\'i ma\'lumotlari';
      default:
        return 'Qo\'shimcha oila a\'zolari';
    }
  }

  Widget _buildStepsIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: current ? 28 : 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done || current
                        ? AppColors.govNavy
                        : const Color(0xFFE5EAF0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: current
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppColors.govNavy : const Color(0xFFE5EAF0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0Location();
      case 1:
        return _buildStep1Head();
      default:
        return _buildStep2Members();
    }
  }

  // ── Step 0 — Location ──
  Widget _buildStep0Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          SurveyorFormWidgets.card(
            icon: Icons.house_outlined,
            title: 'Mulk turi',
            child: _propertyTypeToggle(),
          ),
          const SizedBox(height: 12),
          SurveyorFormWidgets.card(
            icon: Icons.location_on_outlined,
            title: 'Hudud ma\'lumotlari',
            child: LocationPickerSection(
              initialTuman: _tuman,
              initialMfy: _mfy,
              initialStreet: _street,
              onAddressChanged: (t, q, m, s, a) {
                setState(() {
                  _tuman = t;
                  _qfy = q;
                  _mfy = m;
                  _street = s;
                  _officialAddress = a;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          SurveyorFormWidgets.card(
            icon: _propertyType == kHouse
                ? Icons.home_outlined
                : Icons.apartment_outlined,
            title: _propertyType == kHouse
                ? 'Uy ma\'lumotlari'
                : 'Kvartira ma\'lumotlari',
            child: _buildPropertyDetails(),
          ),
          const SizedBox(height: 12),
          if (_propertyType == kApartment && _copiedFromBuildingKey != null)
            _selectedBuildingBanner()
          else
            _mapSection(),
        ],
      ),
    );
  }

  Widget _propertyTypeToggle() {
    return Row(
      children: [
        _propTypeBtn(kHouse, Icons.home_outlined, 'Xonadon\n(alohida uy)'),
        const SizedBox(width: 10),
        _propTypeBtn(
          kApartment,
          Icons.apartment_outlined,
          'Kvartira\n(ko\'p qavatli)',
        ),
      ],
    );
  }

  Widget _propTypeBtn(String type, IconData icon, String label) {
    final active = _propertyType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _propertyType = type;
          _houseCtrl.clear();
          _buildingCtrl.clear();
          _apartmentCtrl.clear();
          _floorCtrl.clear();
          _copiedFromBuildingKey = null;
        }),
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

  Widget _buildPropertyDetails() {
    if (_propertyType == kHouse) {
      return SurveyorFormWidgets.field(
        label: 'Uy raqami (masalan: 45A)',
        icon: Icons.home_outlined,
        controller: _houseCtrl,
      );
    } else {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final existingBuildings = <String, HouseholdModel>{};
      for (final h in provider.households) {
        if (h.propertyType != kApartment) continue;
        if (h.tumanName != _tuman ||
            h.mfyName != _mfy ||
            h.streetName != _street)
          continue;
        final key =
            '${h.buildingNumber ?? "?"}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
        existingBuildings.putIfAbsent(key, () => h);
      }
      return Column(
        children: [
          if (existingBuildings.isNotEmpty) ...[
            _buildingDropdown(existingBuildings),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SurveyorFormWidgets.field(
                  label: 'Bino raqami',
                  icon: Icons.apartment_outlined,
                  controller: _buildingCtrl,
                  readOnly: _copiedFromBuildingKey != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SurveyorFormWidgets.field(
                  label: 'Qavat',
                  icon: Icons.stairs_outlined,
                  keyboardType: TextInputType.number,
                  controller: _floorCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SurveyorFormWidgets.field(
            label: 'Kvartira raqami',
            icon: Icons.door_front_door_outlined,
            controller: _apartmentCtrl,
          ),
        ],
      );
    }
  }

  Widget _buildingDropdown(Map<String, HouseholdModel> buildings) {
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
            value: _copiedFromBuildingKey,
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
              setState(() {
                _copiedFromBuildingKey = key;
                if (key != null) {
                  final src = buildings[key]!;
                  _position = LatLng(src.latitude, src.longitude);
                  _buildingCtrl.text = src.buildingNumber ?? '';
                  _tuman = src.tumanName;
                  _qfy = src.qfyName;
                  _mfy = src.mfyName;
                  _street = src.streetName;
                  _officialAddress = src.officialAddress;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _selectedBuildingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF1976D2)),
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
            onPressed: () => setState(() => _copiedFromBuildingKey = null),
            child: const Text('O\'zgartirish'),
          ),
        ],
      ),
    );
  }

  Widget _mapSection() {
    return SurveyorFormWidgets.card(
      icon: Icons.map_outlined,
      title: 'Geolokatsiya',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openFullScreenMap,
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
                '${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)}',
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
                initialPosition: _position,
                onPositionChanged: (p) => setState(() => _position = p),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 head ──
  Widget _buildStep1Head() {
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
                    _headLastCtrl,
                    'Familiyasi',
                    required: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SurveyorFormWidgets.formField(
                    _headFirstCtrl,
                    'Ismi',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SurveyorFormWidgets.formField(
              _headMiddleCtrl,
              'Sharifi (Otchestvasi)',
            ),
            const SizedBox(height: 10),
            _genderSelector(
              value: _headGender,
              onChanged: (v) => setState(() => _headGender = v),
            ),
            const SizedBox(height: 12),
            SurveyorFormWidgets.formField(
              _headPhoneCtrl,
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

  Widget _genderSelector({
    required String value,
    required void Function(String) onChanged,
  }) {
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

  // ── Step 2 members ──
  Widget _buildStep2Members() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _members.add(_Member())),
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
            itemCount: _members.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCardWidget(
                index: i,
                firstCtrl: _members[i].firstCtrl,
                lastCtrl: _members[i].lastCtrl,
                middleCtrl: _members[i].middleCtrl,
                phoneCtrl: _members[i].phoneCtrl,
                gender: _members[i].gender,
                role: _members[i].role,
                showPhone: _members[i].showPhone,
                roles: _roles,
                onRemove: () => setState(() => _members.removeAt(i)),
                onGenderChanged: (g) => setState(() => _members[i].gender = g),
                onRoleChanged: (r) => setState(() => _members[i].role = r),
                onPhoneToggle: (v) => setState(() => _members[i].showPhone = v),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: const Text('Orqaga'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_step == 0) {
                        if (_tuman == null || _mfy == null || _street == null) {
                          _snack("Hudud ma'lumotlarini to'liq tanlang");
                          return;
                        }
                        if (_propertyType == kHouse &&
                            _houseCtrl.text.isEmpty) {
                          _snack("Uy raqamini kiriting");
                          return;
                        }
                        if (_propertyType == kApartment &&
                            _copiedFromBuildingKey == null &&
                            (_buildingCtrl.text.isEmpty ||
                                _apartmentCtrl.text.isEmpty)) {
                          _snack("Bino va kvartira raqamini kiriting");
                          return;
                        }
                        if (_propertyType == kApartment &&
                            _copiedFromBuildingKey != null &&
                            _apartmentCtrl.text.isEmpty) {
                          _snack("Kvartira raqamini kiriting");
                          return;
                        }
                        setState(() => _step++);
                      } else if (_step == 1) {
                        if (_headFirstCtrl.text.isEmpty ||
                            _headLastCtrl.text.isEmpty) {
                          _snack('Ism va familiyani kiriting');
                          return;
                        }
                        setState(() => _step++);
                      } else {
                        _save();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.govNavy,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_step < 2 ? 'Davom etish' : 'Saqlash'),
            ),
          ),
        ],
      ),
    );
  }
}
