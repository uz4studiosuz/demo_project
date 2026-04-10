import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_provider.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';
import '../../additional/map_border.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  bool _isMapView = true;
  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchPatients();
    });
  }

  void _editPatient(BuildContext context, Patient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPatientSheet(patient: patient),
    );
  }

  void _showFamilyDetails(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(child: Text(patient.fullName)),
            if (patient.isHighRisk)
              const Icon(Icons.warning, color: Colors.red),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, 'Manzil:', patient.address),
            _infoRow(Icons.phone, 'Telefon:', patient.phone),
            _infoRow(
              Icons.family_restroom,
              'A\'zolar soni:',
              patient.familyMembersCount.toString(),
            ),
            if (patient.isHighRisk)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Qizil hudud xavfi',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editPatient(context, patient);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Tahrirlash'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiritilgan Oilalar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            tooltip: _isMapView ? 'Ro\'yxat ko\'rinishi' : 'Xarita ko\'rinishi',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.patients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.patients.isEmpty) {
            return const Center(child: Text('Hozircha oilalar yo\'q'));
          }

          if (_isMapView) {
            return _buildMapView(provider.patients);
          } else {
            return _buildListView(provider.patients);
          }
        },
      ),
    );
  }

  Widget _buildMapView(List<Patient> patients) {
    // Agar bemorlar bo'lsa o'rtacha koordinatani olamiz, yo'qsa default Farg'ona
    double centerLat = 40.3864;
    double centerLng = 71.7825;

    if (patients.isNotEmpty) {
      double avgLat = 0;
      double avgLng = 0;
      for (var p in patients) {
        avgLat += p.lat;
        avgLng += p.lng;
      }
      centerLat = avgLat / patients.length;
      centerLng = avgLng / patients.length;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onPositionChanged: (position, hasGesture) => constrainMap(position, _mapController),
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
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            maxZoom: 15,
            markers: patients.map((patient) {
              return Marker(
                point: LatLng(patient.lat, patient.lng),
                width: 45,
                height: 45,
                rotate: true,
                child: GestureDetector(
                  onTap: () => _showFamilyDetails(patient),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: patient.isHighRisk
                            ? Colors.red
                            : AppColors.primary,
                        size: 45,
                      ),
                      Positioned(
                        top: 8,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.family_restroom,
                            size: 12,
                            color: patient.isHighRisk
                                ? Colors.red
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildListView(List<Patient> patients) {
    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: patient.isHighRisk
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.family_restroom,
                color: patient.isHighRisk ? Colors.red : AppColors.primary,
              ),
            ),
            title: Text(
              patient.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  patient.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (patient.isHighRisk)
                  const Text(
                    'Qizil hudud',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editPatient(context, patient),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteConfirm(patient),
                ),
              ],
            ),
            onTap: () => _showFamilyDetails(patient),
          ),
        );
      },
    );
  }

  Future<void> _deleteConfirm(Patient patient) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirish'),
        content: const Text(
          'Haqiqatdan ham ushbu oila ma\'lumotlarini o\'chirmoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (mounted) {
        Provider.of<AppProvider>(
          context,
          listen: false,
        ).deletePatient(patient.id);
      }
    }
  }
}

class EditPatientSheet extends StatefulWidget {
  final Patient patient;
  const EditPatientSheet({super.key, required this.patient});

  @override
  State<EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends State<EditPatientSheet> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late bool _isHighRisk;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.fullName);
    _addressController = TextEditingController(text: widget.patient.address);
    _isHighRisk = widget.patient.isHighRisk;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ma\'lumotni tahrirlash',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'F.I.SH'),
          ),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Manzil'),
          ),
          CheckboxListTile(
            title: const Text('Xavf guruhi'),
            value: _isHighRisk,
            onChanged: (val) => setState(() => _isHighRisk = val!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              final updated = Patient(
                id: widget.patient.id,
                fullName: _nameController.text,
                phone: widget.patient.phone,
                address: _addressController.text,
                familyMembersCount: widget.patient.familyMembersCount,
                isHighRisk: _isHighRisk,
                lat: widget.patient.lat,
                lng: widget.patient.lng,
              );
              await provider.updatePatient(updated);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Yangilash'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
