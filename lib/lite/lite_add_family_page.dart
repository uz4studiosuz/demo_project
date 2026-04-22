import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../providers/app_provider.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../utils/names_data.dart';
import '../pages/surveyor/widgets/surveyor_form_widgets.dart';
import '../pages/surveyor/widgets/location_picker_section.dart';
import '../pages/surveyor/widgets/map_preview_picker.dart';
import '../pages/surveyor/full_screen_map_picker.dart';

class LiteAddFamilyPage extends StatefulWidget {
  const LiteAddFamilyPage({super.key});

  @override
  State<LiteAddFamilyPage> createState() => _LiteAddFamilyPageState();
}

class _LiteAddFamilyPageState extends State<LiteAddFamilyPage> {
  // ── Manzil va Mulk ──────────────────────────────────────────────
  String _propertyType = kHouse;
  String? _tuman;
  String? _qfy;
  String? _mfy;
  String? _street;
  String _officialAddress = '';
  final _houseCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  LatLng _position = const LatLng(40.3864, 71.7825);

  // ── Oila boshlig'i ──────────────────────────────────────────────
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+998 ');
  String _gender = 'MALE';
  
  bool _saving = false;

  // ── Suggestion listlar ──────────────────────────────────────────
  List<String> _cachedFirstNames = [];
  List<String> _cachedLastNames = [];
  List<String> _cachedMiddleNames = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          // Manzil va pozitsiyani saqlangan holatdan yuklash
          _propertyType = prefs.getString('tpl_property') ?? kHouse;
          _tuman = prefs.getString('tpl_tuman') ?? _tuman;
          _qfy = prefs.getString('tpl_qfy') ?? _qfy;
          _mfy = prefs.getString('tpl_mfy') ?? _mfy;
          _street = prefs.getString('tpl_street') ?? _street;
          _position = LatLng(
            prefs.getDouble('tpl_lat') ?? _position.latitude,
            prefs.getDouble('tpl_lng') ?? _position.longitude,
          );

          // Ism-familiya suggesterlar
          final loadedFirst = prefs.getStringList('tpl_first') ?? [];
          final loadedLast = prefs.getStringList('tpl_last') ?? [];
          final loadedMiddle = prefs.getStringList('tpl_middle') ?? [];
          
          _cachedFirstNames = {
            ...NamesData.defaultFirstNames,
            ...loadedFirst,
          }.toList();
          _cachedLastNames = {
            ...NamesData.defaultLastNames,
            ...loadedLast,
          }.toList();
          _cachedMiddleNames = {
            ...NamesData.defaultMiddleNames,
            ...loadedMiddle,
          }.toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _houseCtrl.dispose();
    _buildingCtrl.dispose();
    _apartmentCtrl.dispose();
    _floorCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _middleCtrl.dispose();
    _phoneCtrl.dispose();
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

  Future<void> _save() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();

    if (first.isEmpty || last.isEmpty) {
      _snack('Iltimos, ism va familiyani kiriting');
      return;
    }

    if (_tuman == null || _mfy == null || _street == null) {
      _snack('Iltimos, hudud ma\'lumotlarini to\'liq tanlang');
      return;
    }

    if (_propertyType == kHouse && _houseCtrl.text.trim().isEmpty) {
      _snack('Uy raqamini kiriting');
      return;
    }

    setState(() => _saving = true);
    
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      // ── Duplicate Check ──
      // Check if a household with the same location or address already exists
      final isDuplicate = provider.households.any((h) {
        // Location check (exact match or very close)
        final sameLocation = (h.latitude - _position.latitude).abs() < 0.0001 && 
                            (h.longitude - _position.longitude).abs() < 0.0001;
        
        // Address check
        bool sameAddress = false;
        if (h.tumanName == _tuman && h.mfyName == _mfy && h.streetName == _street) {
          if (_propertyType == kHouse && h.propertyType == kHouse) {
            sameAddress = h.houseNumber == _houseCtrl.text.trim();
          } else if (_propertyType == kApartment && h.propertyType == kApartment) {
            sameAddress = h.buildingNumber == _buildingCtrl.text.trim() && 
                          h.apartment == _apartmentCtrl.text.trim();
          }
        }

        return sameLocation || sameAddress;
      });

      if (isDuplicate) {
        setState(() => _saving = false);
        _snack('Ushbu manzil yoki lokatsiyada xonadon allaqachon mavjud!');
        return;
      }
      
      final household = HouseholdModel(
        id: 0,
        regionId: 1,
        districtId: 1,
        createdByAgentId: provider.currentUser?.id ?? 0,
        officialAddress: _officialAddress,
        propertyType: _propertyType,
        tumanName: _tuman,
        qfyName: _qfy,
        mfyName: _mfy,
        streetName: _street,
        houseNumber: _propertyType == kHouse ? _houseCtrl.text.trim() : null,
        buildingNumber: _propertyType == kApartment ? _buildingCtrl.text.trim() : null,
        apartment: _propertyType == kApartment ? _apartmentCtrl.text.trim() : null,
        floor: int.tryParse(_floorCtrl.text.trim()),
        latitude: _position.latitude,
        longitude: _position.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final head = ResidentModel(
        id: 0,
        householdId: 0,
        firstName: first,
        lastName: last,
        middleName: _middleCtrl.text.trim().isEmpty ? null : _middleCtrl.text.trim(),
        phonePrimary: _phoneCtrl.text.trim() == '+998' ? null : _phoneCtrl.text.trim(),
        role: 'Oila boshlig\'i',
        gender: _gender,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final ok = await provider.saveHouseholdWithResidents(household, [head]);

      if (mounted) {
        setState(() => _saving = false);
        if (ok) {
          // Template larni saqlash
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('tpl_property', _propertyType);
            if (_tuman != null) await prefs.setString('tpl_tuman', _tuman!);
            if (_qfy != null) await prefs.setString('tpl_qfy', _qfy!);
            if (_mfy != null) await prefs.setString('tpl_mfy', _mfy!);
            if (_street != null) await prefs.setString('tpl_street', _street!);
            await prefs.setDouble('tpl_lat', _position.latitude);
            await prefs.setDouble('tpl_lng', _position.longitude);

            final Set<String> fNames = prefs.getStringList('tpl_first')?.toSet() ?? {};
            final Set<String> lNames = prefs.getStringList('tpl_last')?.toSet() ?? {};
            final Set<String> mNames = prefs.getStringList('tpl_middle')?.toSet() ?? {};
            
            fNames.add(first);
            lNames.add(last);
            if (head.middleName != null) mNames.add(head.middleName!);
            
            await prefs.setStringList('tpl_first', fNames.toList());
            await prefs.setStringList('tpl_last', lNames.toList());
            await prefs.setStringList('tpl_middle', mNames.toList());
            
            // Mahalliy suggesterlarni ham yangilash (sahifadan chiqmasdan keyingi kirish uchun)
            _loadTemplates();
          } catch (_) {}

          _clearForm();
          _snack('Muvaffaqiyatli saqlandi!', success: true);
        } else {
          _snack('Saqlashda xatolik yuz berdi');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Xatolik: $e');
      }
    }
  }

  void _clearForm() {
    _firstCtrl.clear();
    _lastCtrl.clear();
    _middleCtrl.clear();
    _phoneCtrl.text = '+998 ';
    // Izoh: Manzil va mulk turi tozalab tashlanmaydi, chunki user odatda bitta hududda ishlaydi.
    // Pro versiyada ham shunday.
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tezkor xatlov (Lite)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.govNavy,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── 1. Hudud ma'lumotlari ──────────────────────────────
            SurveyorFormWidgets.card(
              icon: Icons.location_on_outlined,
              title: 'Hudud ma\'lumotlari',
              child: LocationPickerSection(
                onAddressChanged: (t, q, m, s, addr) {
                  setState(() {
                    _tuman = t;
                    _qfy = q;
                    _mfy = m;
                    _street = s;
                    _officialAddress = addr;
                  });
                },
                initialTuman: _tuman,
                initialMfy: _mfy,
                initialStreet: _street,
              ),
            ),
            const SizedBox(height: 12),

            // ── 2. Mulk turi va Tafsilotlari ────────────────────────
            SurveyorFormWidgets.card(
              icon: Icons.house_outlined,
              title: 'Mulk ma\'lumotlari',
              child: Column(
                children: [
                  _buildPropertyTypeToggle(),
                  const SizedBox(height: 16),
                  if (_propertyType == kHouse)
                    SurveyorFormWidgets.field(
                      label: 'Uy raqami',
                      icon: Icons.home_outlined,
                      controller: _houseCtrl,
                      required: true,
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SurveyorFormWidgets.field(
                                label: 'Bino',
                                icon: Icons.apartment_outlined,
                                controller: _buildingCtrl,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SurveyorFormWidgets.field(
                                label: 'Qavat',
                                icon: Icons.stairs_outlined,
                                controller: _floorCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SurveyorFormWidgets.field(
                          label: 'Kvartira raqami',
                          icon: Icons.door_front_door_outlined,
                          controller: _apartmentCtrl,
                          required: true,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 3. Geolokatsiya ────────────────────────────────────
            SurveyorFormWidgets.card(
              icon: Icons.map_outlined,
              title: 'Geolokatsiya',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openFullScreenMap,
                          icon: const Icon(
                            Icons.location_searching_rounded,
                            size: 18,
                          ),
                          label: const Text('Kartadan tanlash'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.govNavy,
                            side: const BorderSide(color: AppColors.govNavy),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MapPreviewPicker(
                      initialPosition: _position,
                      onPositionChanged: (p) => setState(() => _position = p),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 4. Oila boshlig'i ──────────────────────────────────
            SurveyorFormWidgets.card(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Oila boshlig\'i',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SurveyorFormWidgets.formField(
                          _lastCtrl,
                          'Familiyasi',
                          required: true,
                          icon: Icons.badge_outlined,
                          suggestions: _cachedLastNames,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SurveyorFormWidgets.formField(
                          _firstCtrl,
                          'Ismi',
                          required: true,
                          icon: Icons.person_outline_rounded,
                          suggestions: _cachedFirstNames,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SurveyorFormWidgets.formField(
                    _middleCtrl,
                    'Sharifi (Otchestvasi)',
                    icon: Icons.text_fields_rounded,
                    suggestions: _cachedMiddleNames,
                  ),
                  const SizedBox(height: 12),
                  _buildGenderSelector(),
                  const SizedBox(height: 12),
                  SurveyorFormWidgets.field(
                    label: 'Telefon',
                    icon: Icons.phone_android_rounded,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeToggle() {
    return Row(
      children: [
        _propTypeBtn(kHouse, Icons.home, 'Hovli uy'),
        const SizedBox(width: 10),
        _propTypeBtn(kApartment, Icons.apartment, 'Ko\'p qavatli'),
      ],
    );
  }

  Widget _propTypeBtn(String type, IconData icon, String label) {
    final active = _propertyType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _propertyType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.govNavy : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.govNavy : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : AppColors.textMain,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['MALE', 'FEMALE'].map((g) {
        final active = _gender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
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
                    g == 'MALE' ? Icons.man : Icons.woman,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    g == 'MALE' ? 'Erkak' : 'Ayol',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textMain,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.govNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _saving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded),
                  const SizedBox(width: 12),
                  const Text(
                    'SAQLASH',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
