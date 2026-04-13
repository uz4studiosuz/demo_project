import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import '../../widgets/section_box.dart';
import 'widgets/map_preview_picker.dart';
import 'widgets/location_picker_section.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({super.key});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _mainFirstNameController = TextEditingController();
  final _mainLastNameController = TextEditingController();
  final _mainPhoneController = TextEditingController();
  final _familyCountController = TextEditingController(text: '1');

  String? _selectedTuman;
  String? _selectedQfy;
  String? _selectedMfy;
  String? _selectedStreet;
  String _officialAddress = '';

  bool _hasAdditionalMembers = false;

  String _mainGender = 'MALE';

  // Controllers and state lists
  final List<TextEditingController> _memberFirstNameControllers = [];
  final List<TextEditingController> _memberLastNameControllers = [];
  final List<String> _memberGenders = [];
  final List<String> _memberRoles = [];

  final List<String> _roleOptions = [
    'Farzandi',
    'Turmush o\'rtog\'i',
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

  bool _isLoadingLocation = false;
  final MapController _mapController = MapController();
  LatLng _centerPosition = const LatLng(40.3864, 71.7825);

  @override
  void initState() {
    super.initState();
    _familyCountController.addListener(_onFamilyCountChanged);
  }

  void _onFamilyCountChanged() {
    if (!_hasAdditionalMembers) {
      if (_memberFirstNameControllers.isNotEmpty) {
        setState(() {
          for (int i = 0; i < _memberFirstNameControllers.length; i++) {
            _memberFirstNameControllers[i].dispose();
            _memberLastNameControllers[i].dispose();
          }
          _memberFirstNameControllers.clear();
          _memberLastNameControllers.clear();
          _memberGenders.clear();
          _memberRoles.clear();
          _familyCountController.text = '1';
        });
      }
      return;
    }

    final text = _familyCountController.text;
    if (text.isEmpty) return;

    final count = int.tryParse(text) ?? 1;
    final additionalCount = count - 1 > 0 ? count - 1 : 0;

    if (additionalCount > 50) return; // Chegara

    if (_memberFirstNameControllers.length != additionalCount) {
      setState(() {
        if (_memberFirstNameControllers.length < additionalCount) {
          // Faqat yetishmayotganlarni qo'shamiz
          int toAdd = additionalCount - _memberFirstNameControllers.length;
          for (int i = 0; i < toAdd; i++) {
            _memberFirstNameControllers.add(TextEditingController());
            _memberLastNameControllers.add(TextEditingController());
            _memberGenders.add('MALE');
            _memberRoles.add('Farzandi');
          }
        } else {
          // Faqat ortiqchalarni olib tashlaymiz
          int toRemove = _memberFirstNameControllers.length - additionalCount;
          for (int i = 0; i < toRemove; i++) {
            int lastIndex = _memberFirstNameControllers.length - 1;
            _memberFirstNameControllers[lastIndex].dispose();
            _memberLastNameControllers[lastIndex].dispose();
            _memberFirstNameControllers.removeAt(lastIndex);
            _memberLastNameControllers.removeAt(lastIndex);
            _memberGenders.removeAt(lastIndex);
            _memberRoles.removeAt(lastIndex);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mainFirstNameController.dispose();
    _mainLastNameController.dispose();
    _mainPhoneController.dispose();
    _familyCountController.dispose();
    for (var c in _memberFirstNameControllers) {
      c.dispose();
    }
    for (var c in _memberLastNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final household = HouseholdModel(
        id: 0,
        regionId: 1,
        districtId: 1,
        createdByAgentId: provider.currentUser?.id ?? 0,
        officialAddress: _officialAddress,
        tumanName: _selectedTuman,
        qfyName: _selectedQfy,
        mfyName: _selectedMfy,
        streetName: _selectedStreet,
        latitude: _centerPosition.latitude,
        longitude: _centerPosition.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      List<ResidentModel> residents = [
        ResidentModel(
          id: 0,
          householdId: 0,
          firstName: _mainFirstNameController.text,
          lastName: _mainLastNameController.text,
          phonePrimary: _mainPhoneController.text,
          gender: _mainGender,
          role: 'Oila boshlig\'i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (int i = 0; i < _memberFirstNameControllers.length; i++) {
        if (_memberFirstNameControllers[i].text.isNotEmpty) {
          residents.add(
            ResidentModel(
              id: 0,
              householdId: 0,
              firstName: _memberFirstNameControllers[i].text,
              lastName: _memberLastNameControllers[i].text,
              gender: _memberGenders[i],
              role: _memberRoles[i],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      bool success = await provider.saveHouseholdWithResidents(
        household,
        residents,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ma\'lumot muvaffaqiyatli saqlandi!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yangi Xatlov'),
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: false,
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 60,
                ),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionBox(
                          title: 'Moddiy Joylashuv',
                          icon: Icons.location_on_outlined,
                          children: [
                            LocationPickerSection(
                              onAddressChanged:
                                  (tuman, qfy, mfy, street, address) {
                                    _selectedTuman = tuman;
                                    _selectedQfy = qfy;
                                    _selectedMfy = mfy;
                                    _selectedStreet = street;
                                    _officialAddress = address;
                                  },
                            ),
                            const SizedBox(height: 20),
                            MapPreviewPicker(
                              initialPosition: _centerPosition,
                              onPositionChanged: (pos) => _centerPosition = pos,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SectionBox(
                          title: 'Oila boshlig\'i',
                          icon: Icons.person_outline,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _mainLastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Familiyasi',
                                    ),
                                    validator: (val) =>
                                        val!.isEmpty ? 'Majburiy' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _mainFirstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ismi',
                                    ),
                                    validator: (val) =>
                                        val!.isEmpty ? 'Majburiy' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _mainPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon Raqami',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                    validator: (val) => val!.isEmpty
                                        ? 'Telefon majburiy'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _mainGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Jinsi',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'MALE',
                                        child: Text('Erkak'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'FEMALE',
                                        child: Text('Ayol'),
                                      ),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _mainGender = val!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SectionBox(
                          title: 'Qo\'shimcha Oila A\'zolari',
                          icon: Icons.group_outlined,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Qo\'shimcha oila a\'zolari mavjudmi?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Switch(
                                  value: _hasAdditionalMembers,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _hasAdditionalMembers = val;
                                      if (!val) {
                                        _familyCountController.text = '1';
                                      } else {
                                        _familyCountController.text =
                                            '2'; // At least 2 if additional members exist
                                      }
                                      _onFamilyCountChanged();
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_hasAdditionalMembers) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _familyCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Umumiy a\'zolar soni (Siz bilan birga)',
                                  prefixIcon: Icon(Icons.family_restroom),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...List.generate(_memberFirstNameControllers.length, (
                                index,
                              ) {
                                return Container(
                                  key: ValueKey(
                                    'member_$index',
                                  ), // Stabil identifikator
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}-Oila a\'zosi',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _memberLastNameControllers[index],
                                              decoration: const InputDecoration(
                                                labelText: 'Familiyasi',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _memberFirstNameControllers[index],
                                              decoration: const InputDecoration(
                                                labelText: 'Ismi',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                                  initialValue:
                                                      _memberGenders[index],
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Jinsi',
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'MALE',
                                                      child: Text('Erkak'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'FEMALE',
                                                      child: Text('Ayol'),
                                                    ),
                                                  ],
                                                  onChanged: (val) => setState(
                                                    () =>
                                                        _memberGenders[index] =
                                                            val!,
                                                  ),
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                                  initialValue:
                                                      _memberRoles[index],
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Oila ro\'li',
                                                      ),
                                                  items: _roleOptions.map((
                                                    role,
                                                  ) {
                                                    return DropdownMenuItem(
                                                      value: role,
                                                      child: Text(role),
                                                    );
                                                  }).toList(),
                                                  onChanged: (val) => setState(
                                                    () => _memberRoles[index] =
                                                        val!,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                          ),
                          child: const Text(
                            'Saqlash va Yuborish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
