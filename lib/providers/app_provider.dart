import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  UserRole _currentUserRole = UserRole.none;
  UserRole get currentUserRole => _currentUserRole;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    _currentUserRole = await _authService.login(username, password);

    _isLoading = false;
    notifyListeners();

    return _currentUserRole != UserRole.none;
  }

  // Load Patients
  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();

    _patients = await _apiService.getPatients();

    _isLoading = false;
    notifyListeners();
  }

  // Save Patient
  Future<bool> savePatient(Patient patient) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _apiService.savePatient(patient);

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // Update Patient
  Future<bool> updatePatient(Patient patient) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.updatePatient(patient);
    if (success) await fetchPatients();
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Delete Patient
  Future<bool> deletePatient(String id) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.deletePatient(id);
    if (success) await fetchPatients();
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void logout() {
    _currentUserRole = UserRole.none;
    notifyListeners();
  }
}
