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
import '../../additional/map_border.dart';

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
  LatLng _centerPosition = const LatLng(
    40.3864,
    71.7825,
  ); // Farg'ona shahri markazi

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
                                    constrainMap(position, _mapController);
                                    if (hasGesture) {
                                      _centerPosition = position.center;
                                    }
                                  },
                                  interactionOptions: const InteractionOptions(
                                    flags:
                                        InteractiveFlag.all &
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

  // Farg'ona viloyati aniq chegaralari (OSM asosida o'lchangan)
  //   final List<LatLng> _ferganaBorder = const [
  //     LatLng(40.4551648, 70.3281721),
  //     LatLng(40.380107, 70.403696),
  //     LatLng(40.3597413, 70.4587825),
  //     LatLng(40.3478821, 70.5625151),
  //     LatLng(40.3059275, 70.5630025),
  //     LatLng(40.2757337, 70.5750552),
  //     LatLng(40.258251, 70.5812361),
  //     LatLng(40.2459105, 70.5957434),
  //     LatLng(40.184815, 70.691624),
  //     LatLng(40.2021394, 70.793518),
  //     LatLng(40.220391, 70.8611865),
  //     LatLng(40.2584562, 70.9745777),
  //     LatLng(40.2883516, 70.9657635),
  //     LatLng(40.2947689, 71.0143816),
  //     LatLng(40.3050707, 71.0868092),
  //     LatLng(40.3376154, 71.1886214),
  //     LatLng(40.3258322, 71.2457714),
  //     LatLng(40.3233338, 71.2480653),
  //     LatLng(40.3339771, 71.2618738),
  //     LatLng(40.3414502, 71.2827626),
  //     LatLng(40.317913, 71.2969499),
  //     LatLng(40.317971, 71.3252637),
  //     LatLng(40.3197085, 71.3496042),
  //     LatLng(40.3183036, 71.3698978),
  //     LatLng(40.3063252, 71.3715955),
  //     LatLng(40.3043087, 71.3981562),
  //     LatLng(40.278593, 71.4547506),
  //     LatLng(40.2782367, 71.4862213),
  //     LatLng(40.2793037, 71.4933766),
  //     LatLng(40.2767842, 71.5020901),
  //     LatLng(40.2707071, 71.5100396),
  //     LatLng(40.2635901, 71.512613),
  //     LatLng(40.2484643, 71.512679),
  //     LatLng(40.2261464, 71.5204514),
  //     LatLng(40.2195084, 71.5526181),
  //     LatLng(40.2160803, 71.5745691),
  //     LatLng(40.2187459, 71.5839547),
  //     LatLng(40.2107824, 71.5980632),
  //     LatLng(40.2076068, 71.6136763),
  //     LatLng(40.2164604, 71.6156214),
  //     LatLng(40.2187242, 71.6272972),
  //     LatLng(40.2361721, 71.6214354),
  //     LatLng(40.2518418, 71.618625),
  //     LatLng(40.2556499, 71.6181719),
  //     LatLng(40.2668087, 71.6201316),
  //     LatLng(40.2679712, 71.6435958),
  //     LatLng(40.2636551, 71.6808915),
  //     LatLng(40.2501736, 71.6887908),
  //     LatLng(40.2333599, 71.700084),
  //     LatLng(40.2187135, 71.6982271),
  //     LatLng(40.2081417, 71.7040147),
  //     LatLng(40.2069798, 71.6982837),
  //     LatLng(40.1976831, 71.6955623),
  //     LatLng(40.1915296, 71.7012155),
  //     LatLng(40.1957219, 71.6869947),
  //     LatLng(40.1959124, 71.6771076),
  //     LatLng(40.1891983, 71.6845244),
  //     LatLng(40.1842784, 71.6923555),
  //     LatLng(40.1775065, 71.7090533),
  //     LatLng(40.1511682, 71.7236231),
  //     LatLng(40.1536735, 71.732024),
  //     LatLng(40.1671625, 71.7451247),
  //     LatLng(40.1778391, 71.7552422),
  //     LatLng(40.2072643, 71.8042644),
  //     LatLng(40.2044014, 71.8157475),
  //     LatLng(40.2065715, 71.8321975),
  //     LatLng(40.2521948, 71.8391874),
  //     LatLng(40.2574466, 71.8595968),
  //     LatLng(40.2624898, 71.8787564),
  //     LatLng(40.2604052, 71.8910071),
  //     LatLng(40.2570574, 71.9039825),
  //     LatLng(40.2514669, 71.9268647),
  //     LatLng(40.2401585, 71.9354609),
  //     LatLng(40.2381175, 71.9465441),
  //     LatLng(40.2457795, 71.9623418),
  //     LatLng(40.2565838, 71.9785256),
  //     LatLng(40.2687308, 72.0171613),
  //     LatLng(40.2746719, 72.037558),
  //     LatLng(40.2787712, 72.0520993),
  //     LatLng(40.2911133, 72.0351882),
  //     LatLng(40.2918194, 72.0294206),
  //     LatLng(40.293267, 72.021881),
  //     LatLng(40.2950125, 72.0122143),
  //     LatLng(40.2969759, 72.0041355),
  //     LatLng(40.29814, 71.9960145),
  //     LatLng(40.300947, 71.9895261),
  //     LatLng(40.3021703, 71.9838037),
  //     LatLng(40.3108299, 71.9723077),
  //     LatLng(40.320443, 71.9654099),
  //     LatLng(40.3255474, 71.9721653),
  //     LatLng(40.3543236, 72.0194648),
  //     LatLng(40.3901716, 72.0632979),
  //     LatLng(40.4103467, 72.0929647),
  //     LatLng(40.4179204, 72.1017923),
  //     LatLng(40.429076, 72.1078215),
  //     LatLng(40.4419383, 72.1038029),
  //     LatLng(40.4574867, 72.1213632),
  //     LatLng(40.4924813, 72.1764959),
  //     LatLng(40.5390354, 72.2345647),
  //     LatLng(40.5567245, 72.211868),
  //     LatLng(40.5648637, 72.1645878),
  //     LatLng(40.5958695, 72.1084642),
  //     LatLng(40.6162491, 72.0726138),
  //     LatLng(40.6134312, 72.0638323),
  //     LatLng(40.6121118, 72.0607531),
  //     LatLng(40.6117779, 72.0589399),
  //     LatLng(40.6115437, 72.0571187),
  //     LatLng(40.611843, 72.0537579),
  //     LatLng(40.6121729, 72.050668),
  //     LatLng(40.612405, 72.0466608),
  //     LatLng(40.6127919, 72.0420581),
  //     LatLng(40.6130362, 72.0386463),
  //     LatLng(40.6135615, 72.0299989),
  //     LatLng(40.6139443, 72.0246506),
  //     LatLng(40.6146549, 72.0151475),
  //     LatLng(40.61343, 71.9880422),
  //     LatLng(40.6211191, 71.9743216),
  //     LatLng(40.6218032, 71.9602561),
  //     LatLng(40.6226297, 71.938675),
  //     LatLng(40.6453917, 71.8586991),
  //     LatLng(40.668927, 71.8269848),
  //     LatLng(40.7116913, 71.7415805),
  //     LatLng(40.7281055, 71.6740317),
  //     LatLng(40.7005646, 71.631655),
  //     LatLng(40.6504944, 71.5801672),
  //     LatLng(40.7284892, 71.4813107),
  //     LatLng(40.6878307, 71.351324),
  //     LatLng(40.6824598, 71.1614969),
  //     LatLng(40.7495602, 71.0707067),
  //     LatLng(40.739921, 70.9738993),
  //     LatLng(40.7541161, 70.9448823),
  //     LatLng(40.7534986, 70.9238068),
  //     LatLng(40.7408293, 70.8951371),
  //     LatLng(40.7335534, 70.8389533),
  //     LatLng(40.7175278, 70.7783572),
  //     LatLng(40.6838515, 70.7472528),
  //     LatLng(40.6549488, 70.7282424),
  //     LatLng(40.6390859, 70.6692633),
  //     LatLng(40.5974604, 70.616801),
  //     LatLng(40.5543623, 70.5532202),
  //     LatLng(40.5140484, 70.4936537),
  //     LatLng(40.4815448, 70.3995832),
  //     LatLng(40.4551648, 70.3281721),
  //   ];

  //   void _constrainMap(MapCamera camera) {
  //     if (_ferganaBorder.isEmpty) return;

  //     final bounds = LatLngBounds.fromPoints(_ferganaBorder);

  //     if (!bounds.contains(camera.center)) {
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         try {
  //           _mapController.move(
  //               const LatLng(40.3864, 71.7825), _mapController.camera.zoom);
  //         } catch (e) {
  //           debugPrint("Move error: $e");
  //         }
  //       });
  //     }
  //   }
  //
}
