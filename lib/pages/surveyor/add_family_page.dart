import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import 'widgets/map_preview_picker.dart';
import 'widgets/location_picker_section.dart';

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
  final TextEditingController phoneCtrl;
  String gender;
  String role;

  _Member({
    String firstName = '',
    String lastName = '',
    String phone = '',
    this.gender = 'MALE',
    this.role = 'Turmush o\'rtog\'i',
  })  : firstCtrl = TextEditingController(text: firstName),
        lastCtrl = TextEditingController(text: lastName),
        phoneCtrl = TextEditingController(text: phone);

  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  // Steps: 0 = manzil, 1 = oila boshlig'i, 2 = a'zolar, 3 = tasdiqlash
  int _step = 0;
  bool get _isEdit => widget.existing != null;

  // ── Joylashuv ────────────────────────────────────────────────────
  String _propertyType = kHouse; // 'HOUSE' yoki 'APARTMENT'
  String? _tuman;
  String? _qfy;
  String? _mfy;
  String? _street;
  String? _houseNumber;
  String? _buildingNumber;
  String? _apartmentNumber;
  int?    _floor;
  String _officialAddress = '';
  LatLng _position = const LatLng(40.3864, 71.7825);
  bool _isLocationLoading = false;
  // Mavjud bino kalit (Apartment uchun) — null → yangi lokatsiya
  String? _copiedFromBuildingKey;

  // ── Oila boshlig'i ───────────────────────────────────────────────
  final _headFirstCtrl = TextEditingController();
  final _headLastCtrl  = TextEditingController();
  final _headPhoneCtrl = TextEditingController();
  String _headGender   = 'MALE';

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
    _propertyType   = h.propertyType;
    _tuman          = h.tumanName;
    _qfy            = h.qfyName;
    _mfy            = h.mfyName;
    _street         = h.streetName;
    _houseNumber    = h.houseNumber;
    _buildingNumber = h.buildingNumber;
    _apartmentNumber = h.apartment;
    _floor          = h.floor;
    _officialAddress = h.officialAddress;
    _position = LatLng(h.latitude, h.longitude);

    // Oila boshlig'i
    final residents = h.residents;
    if (residents.isNotEmpty) {
      final head = residents.first;
      _headFirstCtrl.text = head.firstName;
      _headLastCtrl.text  = head.lastName;
      _headPhoneCtrl.text = head.phonePrimary ?? '';
      _headGender          = head.gender;
    }

    // Qolgan a'zolar
    for (int i = 1; i < residents.length; i++) {
      final r = residents[i];
      _members.add(_Member(
        firstName: r.firstName,
        lastName:  r.lastName,
        phone:     r.phonePrimary ?? '',
        gender:    r.gender,
        role:      r.role ?? 'Boshqa',
      ));
    }
  }

  @override
  void dispose() {
    _headFirstCtrl.dispose();
    _headLastCtrl.dispose();
    _headPhoneCtrl.dispose();
    for (final m in _members) m.dispose();
    super.dispose();
  }

  // ─── GPS auto-fill ────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        if (mounted) _snack('Joylashuv xizmati o\'chirilgan');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) _snack('Joylashuvga ruxsat berilmadi');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _position = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      if (mounted) _snack('Xatolik: $e');
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    // Validation
    if (_headFirstCtrl.text.trim().isEmpty || _headLastCtrl.text.trim().isEmpty) {
      _snack('Oila boshlig\'i ismini kiriting');
      setState(() => _step = 1);
      return;
    }

    setState(() => _saving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    final household = HouseholdModel(
      id: _isEdit ? widget.existing!.id : 0,
      regionId: 1,
      districtId: 1,
      createdByAgentId: provider.currentUser?.id ?? 0,
      officialAddress: _officialAddress.isEmpty ? '${_tuman ?? ''}, ${_street ?? ''}'.trim() : _officialAddress,
      propertyType: _propertyType,
      tumanName: _tuman,
      qfyName: _qfy,
      mfyName: _mfy,
      streetName: _street,
      houseNumber: _houseNumber,
      buildingNumber: _buildingNumber,
      apartment: _apartmentNumber,
      floor: _floor,
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
        phonePrimary: _headPhoneCtrl.text.trim().isEmpty ? null : _headPhoneCtrl.text.trim(),
        gender: _headGender,
        role: 'Oila boshlig\'i',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ..._members.where((m) => m.firstCtrl.text.trim().isNotEmpty).map((m) => ResidentModel(
        id: 0,
        householdId: household.id,
        firstName: m.firstCtrl.text.trim(),
        lastName: m.lastCtrl.text.trim(),
        phonePrimary: m.phoneCtrl.text.trim().isEmpty ? null : m.phoneCtrl.text.trim(),
        gender: m.gender,
        role: m.role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )),
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
        _snack(_isEdit ? 'Muvaffaqiyatli yangilandi!' : 'Muvaffaqiyatli saqlandi!',
            success: true);
        Navigator.pop(context, true);
      } else {
        _snack('Saqlashda xatolik yuz berdi');
      }
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
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
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
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

  // ─── Top bar ──────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.govNavy, size: 20),
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
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Step count indicator
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
                  color: AppColors.govNavy),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0: return 'Manzil va joylashuv';
      case 1: return 'Oila boshlig\'i ma\'lumotlari';
      default: return 'Qo\'shimcha oila a\'zolari';
    }
  }

  // ─── Steps indicator ──────────────────────────────────────────────
  Widget _buildStepsIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(3, (i) {
          final done    = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: current ? 28 : 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done || current ? AppColors.govNavy : const Color(0xFFE5EAF0),
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
                                color: current ? Colors.white : AppColors.textSecondary),
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

  // ─── Step content router ──────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0Location();
      case 1: return _buildStep1Head();
      default: return _buildStep2Members();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STEP 0 — MANZIL
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStep0Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // ── Mulk turi tanlash ──────────────────────────────
          _card(
            icon: Icons.house_outlined,
            title: 'Mulk turi',
            child: _propertyTypeToggle(),
          ),
          const SizedBox(height: 12),

          _card(
            icon: Icons.location_on_outlined,
            title: 'Hudud ma\'lumotlari',
            child: LocationPickerSection(
              initialTuman: _tuman,
              initialMfy: _mfy,
              initialStreet: _street,
              onAddressChanged: (tuman, qfy, mfy, street, address) {
                setState(() {
                  _tuman = tuman;
                  _qfy = qfy;
                  _mfy = mfy;
                  _street = street;
                  _officialAddress = address;
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Uy / Kvartira raqamlari ────────────────────────
          _card(
            icon: _propertyType == kHouse ? Icons.home_outlined : Icons.apartment_outlined,
            title: _propertyType == kHouse ? 'Uy ma\'lumotlari' : 'Kvartira ma\'lumotlari',
            child: _buildPropertyDetails(),
          ),
          const SizedBox(height: 12),

          // Geolokatsiya — Kvartira + bino tanlangan bo'lsa lokatsiyani ko'rsatish (o'zgartirish shart emas)
          if (_propertyType == kApartment && _copiedFromBuildingKey != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lokatsiya binoning manzilidan olindi',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                        Text(
                          '${_position.latitude.toStringAsFixed(5)}, ${_position.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _copiedFromBuildingKey = null),
                    child: const Text('O\'zgartirish', style: TextStyle(fontSize: 11, color: Color(0xFF1976D2))),
                  ),
                ],
              ),
            )
          else
            // Xarita + GPS
            _card(
              icon: Icons.map_outlined,
              title: 'Geolokatsiya',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLocationLoading ? null : _getLocation,
                          icon: _isLocationLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.govNavy))
                              : const Icon(Icons.my_location, color: AppColors.govNavy, size: 18),
                          label: Text(
                            _isLocationLoading ? 'Aniqlanmoqda...' : 'GPS orqali',
                            style: const TextStyle(color: AppColors.govNavy),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.govNavy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            ),
        ],
      ),
    );
  }

  // ── Mulk turi toggle ─────────────────────────────────────────────
  Widget _propertyTypeToggle() {
    return Row(
      children: [
        _propTypeBtn(kHouse,     Icons.home_outlined,     'Xonadon\n(alohida uy)'),
        const SizedBox(width: 10),
        _propTypeBtn(kApartment, Icons.apartment_outlined, 'Kvartira\n(ko\'p qavatli)'),
      ],
    );
  }

  Widget _propTypeBtn(String type, IconData icon, String label) {
    final active = _propertyType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _propertyType = type;
          _houseNumber = null;
          _buildingNumber = null;
          _apartmentNumber = null;
          _floor = null;
          _copiedFromBuildingKey = null; // bino tanlovini tozalash
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.govNavy : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: active ? Colors.white : AppColors.textSecondary),
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

  // ── Mulk turiga qarab maydonlar ──────────────────────────────────
  Widget _buildPropertyDetails() {
    if (_propertyType == kHouse) {
      return _field(
        label: 'Uy raqami (masalan: 45A)',
        icon: Icons.home_outlined,
        initial: _houseNumber,
        onChanged: (v) => setState(() => _houseNumber = v.isEmpty ? null : v),
      );
    } else {
      // ── Mavjud binoni tanlash (Apartment rejimi) ──
      final provider = Provider.of<AppProvider>(context, listen: false);
      final existingBuildings = <String, HouseholdModel>{}; // key -> first apt
      for (final h in provider.households) {
        if (h.propertyType != kApartment) continue;
        if (widget.existing != null && h.id == widget.existing!.id) continue;
        final key = '${h.buildingNumber ?? "?"}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
        existingBuildings.putIfAbsent(key, () => h);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mavjud bino tanlov
          if (existingBuildings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF388E3C)),
                    SizedBox(width: 6),
                    Text('Mavjud binoni tanlang (lokatsiyani qaytadan kiritmang)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF388E3C), fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _copiedFromBuildingKey,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Bino tanlang...',
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Yangi bino (yangi lokatsiya)')),
                      ...existingBuildings.entries.map((e) {
                        final h = e.value;
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            '${h.buildingNumber ?? "?"}-bino | ${h.streetName ?? h.officialAddress}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (key) {
                      setState(() => _copiedFromBuildingKey = key);
                      if (key != null && existingBuildings.containsKey(key)) {
                        final src = existingBuildings[key]!;
                        setState(() {
                          _position = LatLng(src.latitude, src.longitude);
                          _buildingNumber = src.buildingNumber;
                          // Address ma'lumotlarini ham ko'chirish
                          _tuman = src.tumanName;
                          _qfy = src.qfyName;
                          _mfy = src.mfyName;
                          _street = src.streetName;
                          _officialAddress = src.officialAddress;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Qavat va kvartira raqamlari
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Bino raqami',
                  icon: Icons.apartment_outlined,
                  initial: _buildingNumber,
                  onChanged: (v) => setState(() => _buildingNumber = v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: 'Qavat',
                  icon: Icons.stairs_outlined,
                  keyboardType: TextInputType.number,
                  initial: _floor?.toString(),
                  onChanged: (v) => setState(() => _floor = int.tryParse(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            label: 'Kvartira raqami',
            icon: Icons.door_front_door_outlined,
            initial: _apartmentNumber,
            onChanged: (v) => setState(() => _apartmentNumber = v.isEmpty ? null : v),
          ),
        ],
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STEP 1 — OILA BOSHLIG'I
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStep1Head() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: _card(
        icon: Icons.person_outline_rounded,
        title: 'Oila boshlig\'i',
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _formField(_headLastCtrl, 'Familiyasi', required: true)),
                const SizedBox(width: 10),
                Expanded(child: _formField(_headFirstCtrl, 'Ismi', required: true)),
              ],
            ),
            const SizedBox(height: 12),
            _formField(
              _headPhoneCtrl,
              'Telefon raqami',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Gender selector
            _genderSelector(
              value: _headGender,
              onChanged: (v) => setState(() => _headGender = v),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STEP 2 — A'ZOLAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStep2Members() {
    return Column(
      children: [
        // Add member button — top fixed
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _members.add(_Member())),
              icon: const Icon(Icons.person_add_outlined,
                  color: AppColors.govNavy, size: 20),
              label: const Text('A\'zo qo\'shish',
                  style: TextStyle(color: AppColors.govNavy, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.govNavy),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined,
                          size: 56, color: AppColors.govNavy.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text(
                        'Qo\'shimcha a\'zo yo\'q',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Yuqoridagi tugma orqali qo\'shishingiz mumkin',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _members.length,
                  itemBuilder: (_, i) => _memberCard(i),
                ),
        ),
      ],
    );
  }

  Widget _memberCard(int i) {
    final m = _members[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.govNavy)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Oila a\'zosi',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.govNavy,
                        fontSize: 13)),
                const Spacer(),
                // Role dropdown compact
                DropdownButton<String>(
                  value: m.role,
                  underline: const SizedBox(),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMain),
                  isDense: true,
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => m.role = v!),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _members[i].dispose();
                    _members.removeAt(i);
                  }),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.danger, size: 18),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _formField(m.lastCtrl, 'Familiyasi')),
                    const SizedBox(width: 10),
                    Expanded(child: _formField(m.firstCtrl, 'Ismi')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _formField(m.phoneCtrl, 'Telefon',
                          icon: Icons.phone_outlined,
                          keyboard: TextInputType.phone),
                    ),
                    const SizedBox(width: 10),
                    // Gender pill
                    _miniGenderSelector(
                      value: m.gender,
                      onChanged: (v) => setState(() => m.gender = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────────
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
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.govNavy),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Orqaga',
                    style: TextStyle(
                        color: AppColors.govNavy, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _save();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.govNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _step < 2
                          ? 'Davom etish'
                          : (_isEdit ? 'Saqlash' : 'Yakunlash va saqlash'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.govNavy, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.govNavy)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.govNavy) : null,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.govNavy, width: 1.5),
        ),
      ),
    );
  }

  // Simple plain field with onChanged
  Widget _field({
    required String label,
    required IconData icon,
    String? initial,
    TextInputType keyboardType = TextInputType.text,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initial,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.govNavy),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.govNavy, width: 1.5),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: g == 'MALE' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    g == 'MALE' ? Icons.man_rounded : Icons.woman_rounded,
                    color: active ? Colors.white : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    g == 'MALE' ? 'Erkak' : 'Ayol',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniGenderSelector({
    required String value,
    required void Function(String) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['MALE', 'FEMALE'].map((g) {
        final active = value == g;
        return GestureDetector(
          onTap: () => onChanged(g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(left: g == 'FEMALE' ? 4 : 0),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              g == 'MALE' ? Icons.man_rounded : Icons.woman_rounded,
              color: active ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
        );
      }).toList(),
    );
  }
}
