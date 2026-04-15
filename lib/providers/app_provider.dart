import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  static const String _kUserKey = 'saved_user_data';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  UserRole get currentUserRole => _currentUser?.role ?? UserRole.none;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HouseholdModel> _households = [];
  List<HouseholdModel> get households => _households;

  /// Ilova ishga tushganda saqlangan session bormi tekshiradi
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_kUserKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Session yuklashda xato: $e');
        await prefs.remove(_kUserKey);
      }
    }
  }

  /// Sessionni keshga saqlash
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
  }

  /// Sessionni tozalash
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }

  // ─────────────────────────────────────────────────────────────────
  //  AUTH
  // ─────────────────────────────────────────────────────────────────

  /// Supabase app_users jadvalidan username/password tekshiradi.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await SupabaseService.login(username, password);
      if (user != null) {
        _currentUser = user;
        await _saveSession(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login yoki parol noto\'g\'ri';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on PostgrestException catch (e) {
      _errorMessage = 'Server xatoligi: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Tarmoq xatoligi. Internet aloqasini tekshiring.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _currentUser = null;
    _households = [];
    _errorMessage = null;
    await _clearSession();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  //  HOUSEHOLDS
  // ─────────────────────────────────────────────────────────────────

  Future<void> fetchHouseholds() async {
    _isLoading = true;
    notifyListeners();

    try {
      _households = await SupabaseService.getHouseholds();
    } catch (e) {
      _errorMessage = 'Ma\'lumotlarni yuklashda xatolik';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveHouseholdWithResidents(
    HouseholdModel household,
    List<ResidentModel> residents,
  ) async {
    _isLoading = true;
    notifyListeners();

    // 1. Xonadon yaratish
    final newHh = await SupabaseService.createHousehold(household);

    if (newHh != null) {
      // 2. Residentlarni yaratish
      for (final res in residents) {
        await SupabaseService.createResident(
          ResidentModel(
            id: 0,
            householdId: newHh.id,
            firstName: res.firstName,
            lastName: res.lastName,
            middleName: res.middleName,
            phonePrimary: res.phonePrimary,
            gender: res.gender,
            role: res.role,
            birthDate: res.birthDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      await fetchHouseholds();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Xonadon saqlashda xatolik';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateHousehold(HouseholdModel household) async {
    _isLoading = true;
    notifyListeners();

    final result = await SupabaseService.updateHousehold(household);
    if (result != null) {
      await fetchHouseholds();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Yangilashda xatolik';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateHouseholdWithResidents(
    HouseholdModel household,
    List<ResidentModel> residents,
  ) async {
    _isLoading = true;
    notifyListeners();

    print('🔵 [AppProvider.updateHouseholdWithResidents] ID: ${household.id}');

    // 1. Xonadonni yangilash
    final updated = await SupabaseService.updateHousehold(household);
    if (updated == null) {
      print('❌ [AppProvider] Xonadonni yangilashda xatolik (updated == null)');
      _errorMessage = 'Xonadonni yangilashda xatolik';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // 2. Eski residentlarni o'chirish
    await SupabaseService.deleteResidentsByHousehold(updated.id);

    // 3. Yangi residentlar qo'shish
    for (final res in residents) {
      await SupabaseService.createResident(
        ResidentModel(
          id: 0,
          householdId: updated.id,
          firstName: res.firstName,
          lastName: res.lastName,
          middleName: res.middleName,
          phonePrimary: res.phonePrimary,
          gender: res.gender,
          role: res.role,
          birthDate: res.birthDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    await fetchHouseholds();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteHousehold(int id) async {
    _isLoading = true;
    notifyListeners();

    final success = await SupabaseService.deleteHousehold(id);
    if (success) {
      _households.removeWhere((h) => h.id == id);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // ─────────────────────────────────────────────────────────────────
  //  RESIDENTS
  // ─────────────────────────────────────────────────────────────────

  Future<bool> deleteResident(int residentId) async {
    _isLoading = true;
    notifyListeners();

    final success = await SupabaseService.deleteResident(residentId);
    if (success) {
      for (final hh in _households) {
        hh.residents.removeWhere((r) => r.id == residentId);
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateResident(ResidentModel resident) async {
    _isLoading = true;
    notifyListeners();

    final result = await SupabaseService.updateResident(resident);
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
