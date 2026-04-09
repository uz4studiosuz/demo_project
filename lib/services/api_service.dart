import '../models/patient.dart';

class ApiService {
  final List<Patient> _mockPatients = [
    Patient(
      id: '1',
      fullName: 'Sodikov Alisher',
      phone: '+998901234567',
      address: 'Chilanzar, 12-mavze, 45-uy',
      familyMembersCount: 4,
      isHighRisk: true,
      lat: 41.2858,
      lng: 69.2136,
    ),
    Patient(
      id: '2',
      fullName: 'Valiyeva Nargiza',
      phone: '+998939876543',
      address: 'Yunusobod, 4-kvartal, 12-uy',
      familyMembersCount: 2,
      isHighRisk: false,
      lat: 41.3644,
      lng: 69.2886,
    ),
    Patient(
      id: '3',
      fullName: 'Toshmatov Botir',
      phone: '+998971112233',
      address: 'Mirzo Ulugbek, 1-tor kocha, 5-uy',
      familyMembersCount: 6,
      isHighRisk: true,
      lat: 41.3283,
      lng: 69.3364,
    ),
  ];

  Future<List<Patient>> getPatients() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    return [..._mockPatients];
  }

  Future<bool> savePatient(Patient patient) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockPatients.add(patient);
    print("ApiService: Bemor saqlandi: ${patient.toMap()}");
    return true;
  }

  Future<bool> updatePatient(Patient updatedPatient) async {
    await Future.delayed(const Duration(seconds: 1));
    int index = _mockPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (index != -1) {
      _mockPatients[index] = updatedPatient;
      print("ApiService: Bemor yangilandi: ${updatedPatient.id}");
      return true;
    }
    return false;
  }

  Future<bool> deletePatient(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockPatients.removeWhere((p) => p.id == id);
    print("ApiService: Bemor o'chirildi: $id");
    return true;
  }
}
