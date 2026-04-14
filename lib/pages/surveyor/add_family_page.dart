import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../utils/names_data.dart';
import 'widgets/step0_location_step.dart';
import 'widgets/step1_head_step.dart';
import 'widgets/step2_members_step.dart';
import 'widgets/step3_preview_step.dart';
import 'full_screen_map_picker.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ADD / EDIT FAMILY PAGE  —  Step-by-step UX
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
  DateTime? birthDate;

  _Member({
    String firstName = '',
    String lastName = '',
    String middleName = '',
    String phone = '',
    this.gender = 'MALE',
    this.role = 'Turmush o\'rtog\'i',
    this.birthDate,
  }) : showPhone = phone.isNotEmpty && phone != '+998 ',
       firstCtrl = TextEditingController(text: firstName),
       lastCtrl = TextEditingController(text: lastName),
       middleCtrl = TextEditingController(text: middleName),
       phoneCtrl = TextEditingController(text: phone.isEmpty ? '+998 ' : phone);

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
  String _propertyType = kHouse;
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
  DateTime? _headBirthDate;

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

  List<String> _cachedFirstNames = [];
  List<String> _cachedLastNames = [];
  List<String> _cachedMiddleNames = [];

  @override
  void initState() {
    super.initState();
    _prefill();
    if (!_isEdit) {
      _loadTemplates();
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _propertyType = prefs.getString('tpl_property') ?? kHouse;
          _tuman = prefs.getString('tpl_tuman') ?? _tuman;
          _qfy = prefs.getString('tpl_qfy') ?? _qfy;
          _mfy = prefs.getString('tpl_mfy') ?? _mfy;
          _street = prefs.getString('tpl_street') ?? _street;
          _position = LatLng(
            prefs.getDouble('tpl_lat') ?? _position.latitude,
            prefs.getDouble('tpl_lng') ?? _position.longitude,
          );
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

  void _prefill() {
    final h = widget.existing;
    if (h == null) return;

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

    // Tahrirlash rejimida kvartira bo'lsa — mavjud binoni avtomatik tanlash
    // Dropdown da o'sha bino "selected" holatda ko'rinadi
    if (h.propertyType == kApartment && h.buildingNumber != null) {
      _copiedFromBuildingKey =
          '${h.buildingNumber}_${h.latitude.toStringAsFixed(4)}_${h.longitude.toStringAsFixed(4)}';
    }

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
      _headBirthDate = head.birthDate;
    }

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
          birthDate: r.birthDate,
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
        birthDate: _headBirthDate,
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
              birthDate: m.birthDate,
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
        if (!_isEdit) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('tpl_property', _propertyType);
            if (_tuman != null) await prefs.setString('tpl_tuman', _tuman!);
            if (_qfy != null) await prefs.setString('tpl_qfy', _qfy!);
            if (_mfy != null) await prefs.setString('tpl_mfy', _mfy!);
            if (_street != null) await prefs.setString('tpl_street', _street!);
            await prefs.setDouble('tpl_lat', _position.latitude);
            await prefs.setDouble('tpl_lng', _position.longitude);

            final Set<String> fNames =
                prefs.getStringList('tpl_first')?.toSet() ?? {};
            final Set<String> lNames =
                prefs.getStringList('tpl_last')?.toSet() ?? {};
            final Set<String> mNames =
                prefs.getStringList('tpl_middle')?.toSet() ?? {};
            for (final r in residents) {
              if (r.firstName.isNotEmpty) fNames.add(r.firstName);
              if (r.lastName.isNotEmpty) lNames.add(r.lastName);
              if (r.middleName != null && r.middleName!.isNotEmpty)
                mNames.add(r.middleName!);
            }
            await prefs.setStringList('tpl_first', fNames.toList());
            await prefs.setStringList('tpl_last', lNames.toList());
            await prefs.setStringList('tpl_middle', mNames.toList());
          } catch (_) {}
        }
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

  bool _hasChanges() {
    if (_isEdit)
      return false; // Tahrirlashda shart emas deb hisoblaymiz (ixtiyoriy)
    if (_step > 0) return true;
    if (_houseCtrl.text.isNotEmpty ||
        _buildingCtrl.text.isNotEmpty ||
        _apartmentCtrl.text.isNotEmpty ||
        _headFirstCtrl.text.isNotEmpty ||
        _headLastCtrl.text.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Diqqat!'),
            content: const Text(
              'Xatlovni tugatmasdan chiqmoqchimisiz? Kiritilgan ma\'lumotlar saqlanmaydi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Yo\'q, qolish',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),

                child: const Text(
                  'Ha, chiqish',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;
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
      child: PopScope(
        canPop: !_hasChanges(),
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showExitDialog();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
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
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (_hasChanges()) {
                final ok = await _showExitDialog();
                if (ok && mounted) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
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
              '${_step + 1} / 4',
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
      case 2:
        return 'Qo\'shimcha oila a\'zolari';
      default:
        return 'Ma\'lumotlarni tekshirish';
    }
  }

  Widget _buildStepsIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: current ? 24 : 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: done || current
                        ? AppColors.govNavy
                        : const Color(0xFFE5EAF0),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: current
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                if (i < 3)
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
        return Step0LocationStep(
          propertyType: _propertyType,
          tuman: _tuman,
          mfy: _mfy,
          street: _street,
          houseCtrl: _houseCtrl,
          buildingCtrl: _buildingCtrl,
          apartmentCtrl: _apartmentCtrl,
          floorCtrl: _floorCtrl,
          position: _position,
          copiedFromBuildingKey: _copiedFromBuildingKey,
          onPropertyTypeChanged: (type) => setState(() {
            _propertyType = type;
            _houseCtrl.clear();
            _buildingCtrl.clear();
            _apartmentCtrl.clear();
            _floorCtrl.clear();
            _copiedFromBuildingKey = null;
          }),
          onAddressChanged: (t, q, m, s, a) => setState(() {
            _tuman = t;
            _qfy = q;
            _mfy = m;
            _street = s;
            _officialAddress = a;
          }),
          onBuildingKeySelected: (key, src) => setState(() {
            _copiedFromBuildingKey = key;
            if (key != null && src != null) {
              _position = LatLng(src.latitude, src.longitude);
              _buildingCtrl.text = src.buildingNumber ?? '';
              _tuman = src.tumanName;
              _qfy = src.qfyName;
              _mfy = src.mfyName;
              _street = src.streetName;
              _officialAddress = src.officialAddress;
            }
          }),
          onPositionChanged: (p) => setState(() => _position = p),
          onOpenFullScreenMap: _openFullScreenMap,
        );
      case 1:
        return Step1HeadStep(
          headFirstCtrl: _headFirstCtrl,
          headLastCtrl: _headLastCtrl,
          headMiddleCtrl: _headMiddleCtrl,
          headPhoneCtrl: _headPhoneCtrl,
          headGender: _headGender,
          headBirthDate: _headBirthDate,
          cachedFirstNames: _cachedFirstNames,
          cachedLastNames: _cachedLastNames,
          cachedMiddleNames: _cachedMiddleNames,
          onGenderChanged: (v) => setState(() => _headGender = v),
          onBirthDateChanged: (d) => setState(() => _headBirthDate = d),
        );
      case 2:
        return Step2MembersStep(
          cachedFirstNames: _cachedFirstNames,
          cachedLastNames: _cachedLastNames,
          cachedMiddleNames: _cachedMiddleNames,
          members: _members
              .map(
                (m) => MemberData(
                  firstCtrl: m.firstCtrl,
                  lastCtrl: m.lastCtrl,
                  middleCtrl: m.middleCtrl,
                  phoneCtrl: m.phoneCtrl,
                  showPhone: m.showPhone,
                  gender: m.gender,
                  role: m.role,
                  birthDate: m.birthDate,
                ),
              )
              .toList(),
          roles: _roles,
          onAddMember: () => setState(() => _members.add(_Member())),
          onRemoveMember: (i) => setState(() => _members.removeAt(i)),
          onGenderChanged: (i, g) => setState(() => _members[i].gender = g),
          onRoleChanged: (i, r) => setState(() => _members[i].role = r),
          onPhoneToggle: (i, v) => setState(() => _members[i].showPhone = v),
          onBirthDateChanged: (i, d) => setState(() => _members[i].birthDate = d),
        );
      default:
        return Step3PreviewStep(
          data: {
            'propertyType': _propertyType,
            'tuman': _tuman,
            'mfy': _mfy,
            'street': _street,
            'houseNumber': _houseCtrl.text,
            'buildingNumber': _buildingCtrl.text,
            'apartment': _apartmentCtrl.text,
            'floor': _floorCtrl.text,
            'headFirst': _headFirstCtrl.text,
            'headLast': _headLastCtrl.text,
            'headMiddle': _headMiddleCtrl.text,
            'headGender': _headGender,
            'headPhone': _headPhoneCtrl.text != '+998 '
                ? _headPhoneCtrl.text
                : null,
            'members': _members
                .where((m) => m.firstCtrl.text.trim().isNotEmpty)
                .map(
                  (m) => {
                    'first': m.firstCtrl.text,
                    'last': m.lastCtrl.text,
                    'middle': m.middleCtrl.text,
                    'phone': m.phoneCtrl.text,
                    'gender': m.gender,
                    'role': m.role,
                  },
                )
                .toList(),
          },
        );
    }
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

                        // Dublikatlarni tekshirish (faqat 0-qadamda)
                        final provider = Provider.of<AppProvider>(context, listen: false);
                        final hNum = _houseCtrl.text.trim();
                        final bNum = _buildingCtrl.text.trim();
                        final aNum = _apartmentCtrl.text.trim();
                        bool isDuplicate = provider.households.any((h) {
                           if (_isEdit && widget.existing?.id == h.id) return false;
                           if (h.tumanName != _tuman) return false;
                           if (h.mfyName != _mfy) return false;
                           if (h.streetName != _street) return false;
                           if (h.propertyType != _propertyType) return false;

                           if (_propertyType == kHouse) {
                             return h.houseNumber == hNum;
                           } else {
                             return h.buildingNumber == bNum && h.apartment == aNum;
                           }
                        });

                        if (isDuplicate) {
                           _snack("Bunday manzilga ega xonadon allaqachon mavjud!");
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
                      } else if (_step == 2) {
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
                  : Text(_step < 3 ? 'Davom etish' : 'Bazaga yuklash'),
            ),
          ),
        ],
      ),
    );
  }
}
