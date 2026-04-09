import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_provider.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';
import '../login.dart';
import 'patient_list_page.dart';
import 'full_screen_map_picker.dart';

class SurveyorDashboard extends StatefulWidget {
  const SurveyorDashboard({super.key});

  @override
  State<SurveyorDashboard> createState() => _SurveyorDashboardState();
}

class _SurveyorDashboardState extends State<SurveyorDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _familyCountController = TextEditingController();
  final List<TextEditingController> _memberNamesControllers = [];
  bool _isHighRisk = false;
  bool _isLoadingLocation = false;

  final MapController _mapController = MapController();
  LatLng _centerPosition = const LatLng(40.3864, 71.7825); // Farg'ona shahri markazi

  @override
  void initState() {
    super.initState();
    _familyCountController.addListener(_onFamilyCountChanged);
  }

  void _onFamilyCountChanged() {
    final count = int.tryParse(_familyCountController.text) ?? 0;
    if (count > 20) return; // Cheklov

    setState(() {
      if (_memberNamesControllers.length < count) {
        for (int i = _memberNamesControllers.length; i < count; i++) {
          _memberNamesControllers.add(TextEditingController());
        }
      } else if (_memberNamesControllers.length > count) {
        for (int i = _memberNamesControllers.length - 1; i >= count; i--) {
          _memberNamesControllers[i].dispose();
          _memberNamesControllers.removeAt(i);
        }
      }
    });
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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _familyCountController.dispose();
    for (var c in _memberNamesControllers) {
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

      final patient = Patient(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        familyMembersCount: int.tryParse(_familyCountController.text) ?? 1,
        isHighRisk: _isHighRisk,
        lat: _centerPosition.latitude,
        lng: _centerPosition.longitude,
      );

      bool success = await provider.savePatient(patient);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ma\'lumot muvaffaqiyatli saqlandi!')),
        );
        // Clear form
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _familyCountController.clear();
        setState(() {
          _isHighRisk = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatlovchi Ekroni'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ro\'yxatni boshqarish',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientListPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              provider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Oila Qo\'shish',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'F.I.SH',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'F.I.SH kiritilishi shart' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Raqam',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Telefon majburiy' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Yashash Manzili (Uy/Kvartira)',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Manzil majburiy' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _familyCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Xonadon a\'zolari soni',
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dinamik a'zolar ro'yxati
                      ...List.generate(_memberNamesControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextFormField(
                            controller: _memberNamesControllers[index],
                            decoration: InputDecoration(
                              labelText: '${index + 1}-inson F.I.SH',
                              prefixIcon: const Icon(
                                Icons.person_add,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text(
                          'Xavf Guruhiga kiradimi? (Qizil hudud)',
                        ),
                        value: _isHighRisk,
                        activeColor: AppColors.error,
                        onChanged: (val) {
                          setState(() {
                            _isHighRisk = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Joylashuvni tanlang',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _openFullScreenMap,
                            icon: const Icon(Icons.fullscreen, size: 20),
                            label: const Text('To\'liq ekran'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
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
                                    _constrainMap(position);
                                    if (hasGesture) {
                                      _centerPosition = position.center;
                                    }
                                  },
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://mt1.google.com/vt/lyrs=y&hl=uz&x={x}&y={y}&z={z}',
                                    userAgentPackageName:
                                        'com.example.demoproject',
                                    maxZoom: 20,
                                  ),
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _ferganaBorder,
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
                                  color: Colors.pink,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: FloatingActionButton.small(
                                  heroTag: 'dashboard_location_btn',
                                  onPressed: _isLoadingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  backgroundColor: Colors.white,
                                  child: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location,
                                          color: Colors.blue,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Saqlash va Yuborish'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Farg'ona viloyati aniq chegaralari (Google Maps asosida o'lchangan)
  final List<LatLng> _ferganaBorder = const [
    LatLng(40.612, 70.435), // Beshariq West
    LatLng(40.678, 70.618), // Beshariq North
    LatLng(40.732, 70.825), // Dangara North
    LatLng(40.781, 71.014), // Buvayda North
    LatLng(40.854, 71.218), // Yazyavan North-West
    LatLng(40.902, 71.450), // Yazyavan North
    LatLng(40.835, 71.720), // Quva North-West
    LatLng(40.755, 71.950), // Quva North
    LatLng(40.686, 72.185), // Quva East
    LatLng(40.551, 72.368), // Quvasoy East
    LatLng(40.415, 72.215), // Quvasoy South
    LatLng(40.292, 71.954), // Farg'ona South-East
    LatLng(40.150, 71.850), // Vadil East
    LatLng(39.954, 71.848), // Shoximardon East
    LatLng(39.851, 71.745), // Shoximardon South
    LatLng(39.945, 71.650), // Shoximardon West
    LatLng(40.114, 71.642), // Vadil West
    LatLng(40.155, 71.450), // Rishton South-East
    LatLng(40.245, 71.285), // Rishton South
    LatLng(40.285, 71.120), // Bagdod South
    LatLng(40.315, 70.950), // Uchkuprik South
    LatLng(40.355, 70.785), // Yaypan South
    LatLng(40.415, 70.655), // Yaypan West
    LatLng(40.455, 70.515), // Beshariq South
    LatLng(40.525, 70.420), // Beshariq South-West
    LatLng(40.612, 70.435), // Close loop
  ];

  void _constrainMap(MapCamera camera) {
    if (_ferganaBorder.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(_ferganaBorder);
    
    if (!bounds.contains(camera.center)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(
              const LatLng(40.3864, 71.7825), _mapController.camera.zoom);
        } catch (e) {
          debugPrint("Move error: $e");
        }
      });
    }
  }
}
