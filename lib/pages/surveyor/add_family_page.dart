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
import 'full_screen_map_picker.dart';
import '../../additional/map_border.dart';

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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _centerPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(_centerPosition, 16);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
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
    _mapController.dispose();
    super.dispose();
  }

  void _openFullScreenMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenMapPicker(initialPosition: _centerPosition),
      ),
    );

    if (result != null) {
      setState(() {
        _centerPosition = result;
        _mapController.move(_centerPosition, 16);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final household = HouseholdModel(
        id: 0,
        regionId: 1,
        districtId: 1,
        createdByAgentId: provider.currentUser?.id ?? 0,
        officialAddress: _addressController.text,
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
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Xonadon manzili',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Manzil majburiy' : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Xaritadagi joy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openFullScreenMap,
                                  icon: const Icon(Icons.fullscreen, size: 20),
                                  label: const Text('To\'liq ekran'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildMapWidget(),
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
                            TextFormField(
                              controller: _familyCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Umumiy a\'zolar soni',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  () => _memberGenders[index] =
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
                                                      labelText: 'Oila ro\'li',
                                                    ),
                                                items: _roleOptions.map((role) {
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

  Widget _buildMapWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centerPosition,
                initialZoom: 14.0,
                minZoom: 5,
                maxZoom: 18,
                onPositionChanged: (position, hasGesture) {
                  constrainMap(position, _mapController);
                  if (hasGesture) _centerPosition = position.center;
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.demoproject',
                  maxZoom: 20,
                ),
                if (kShowMapBorder)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: kFerganaBorder,
                        color: Colors.redAccent,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
              ],
            ),
            const Center(
              child: Icon(
                Icons.location_pin,
                size: 30,
                color: AppColors.danger,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FloatingActionButton.small(
                heroTag: 'dashboard_location_btn',
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                backgroundColor: Colors.white,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
