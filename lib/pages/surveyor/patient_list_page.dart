import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchPatients();
    });
  }

  void _editPatient(BuildContext context, Patient patient) {
    // Tahrirlash uchun oddiy dialog yoki formani qayta ochish mantiqi
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPatientSheet(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiritilgan Bemorlar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.patients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.patients.isEmpty) {
            return const Center(child: Text('Hozircha bemorlar yo\'q'));
          }
          return ListView.builder(
            itemCount: provider.patients.length,
            itemBuilder: (context, index) {
              final patient = provider.patients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(patient.fullName),
                  subtitle: Text(patient.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPatient(context, patient),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('O\'chirish'),
                              content: const Text('Haqiqatdan ham o\'chirmoqchimisiz?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yo\'q')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ha')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await provider.deletePatient(patient.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ma\'lumotni tahrirlash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'F.I.SH')),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Manzil')),
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
