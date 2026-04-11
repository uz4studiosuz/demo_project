import 'package:flutter/material.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  
  UserRole get currentUserRole => _currentUser?.role ?? UserRole.none;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<HouseholdModel> _households = [];
  List<HouseholdModel> get households => _households;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final role = await _authService.login(username, password);
    if (role != UserRole.none) {
      _currentUser = UserModel(
        id: 1, 
        firstName: 'Test', 
        lastName: 'User', 
        username: username, 
        role: role, 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now()
      );
    }

    _isLoading = false;
    notifyListeners();

    return role != UserRole.none;
  }

  // Load Households
  Future<void> fetchHouseholds() async {
    _isLoading = true;
    notifyListeners();

    _households = await _apiService.getHouseholds();

    _isLoading = false;
    notifyListeners();
  }

  // Save Household and its Residents
  Future<bool> saveHouseholdWithResidents(HouseholdModel household, List<ResidentModel> residents) async {
    _isLoading = true;
    notifyListeners();

    // 1. Create Household
    final newHh = await _apiService.createHousehold(household);
    
    if (newHh != null) {
      // 2. Create residents for this household
      for (var res in residents) {
        final resToSave = ResidentModel(
          id: 0,
          householdId: newHh.id,
          firstName: res.firstName,
          lastName: res.lastName,
          phonePrimary: res.phonePrimary,
          gender: res.gender,
          role: res.role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _apiService.createResident(resToSave);
      }
      
      // Refresh list
      await fetchHouseholds();
      
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update Household
  Future<bool> updateHousehold(HouseholdModel household) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.updateHousehold(household);
    if (result != null) {
      await fetchHouseholds();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Delete Household
  Future<bool> deleteHousehold(int id) async {
    _isLoading = true;
    notifyListeners();
    
    bool success = await _apiService.deleteHousehold(id);
    if (success) {
      _households.removeWhere((element) => element.id == id);
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Delete Resident
  Future<bool> deleteResident(int residentId) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _apiService.deleteResident(residentId);
    if (success) {
      // Lokal ro'yxatdan ham olib tashlash
      for (var hh in _households) {
        hh.residents.removeWhere((r) => r.id == residentId);
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Update Resident
  Future<bool> updateResident(ResidentModel resident) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.updateResident(resident);
    if (result != null) {
      await fetchHouseholds();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    _households = [];
    notifyListeners();
  }
}
