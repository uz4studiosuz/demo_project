import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../utils/mock_data.dart';

/// Lokal saqlash bilan ishlaydigan API service.
/// SharedPreferences orqali ma'lumotlarni disk'ga saqlaydi.
class ApiService {
  static const String _storageKey = 'households_data';
  static const int _mockVersion = 7; // Oshirish orqali keshni tozalab qayta yuklanadi
  static const String _versionKey = 'mock_data_version';

  List<HouseholdModel>? _cache;

  // ═══════════════════════════════════════════════════════════════
  //  DISK BILAN ISHLASH
  // ═══════════════════════════════════════════════════════════════

  Future<List<HouseholdModel>> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();

    // Version check — eski keshni tozalash
    final savedVersion = prefs.getInt(_versionKey) ?? 0;
    if (savedVersion < _mockVersion) {
      // Yangi mock data yuklaymiz
      final defaults = _parseMockData();
      await _saveToDisk(prefs, defaults);
      await prefs.setInt(_versionKey, _mockVersion);
      return defaults;
    }

    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaults = _parseMockData();
      await _saveToDisk(prefs, defaults);
      return defaults;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((e) => HouseholdModel.fromJson(e)).toList();
    } catch (_) {
      final defaults = _parseMockData();
      await _saveToDisk(prefs, defaults);
      return defaults;
    }
  }

  List<HouseholdModel> _parseMockData() {
    final List<dynamic> jsonList = json.decode(kMockHouseholdsJson);
    return jsonList.map((e) => HouseholdModel.fromJson(e)).toList();
  }

  Future<void> _saveToDisk(SharedPreferences prefs, List<HouseholdModel> households) async {
    final jsonStr = json.encode(households.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  Future<void> _syncCache(SharedPreferences prefs) async {
    if (_cache != null) await _saveToDisk(prefs, _cache!);
  }

  Future<List<HouseholdModel>> _getCache() async {
    _cache ??= await _loadFromDisk();
    return _cache!;
  }

  // ═══════════════════════════════════════════════════════════════
  //  CRUD OPERATSIYALAR
  // ═══════════════════════════════════════════════════════════════

  Future<List<HouseholdModel>> getHouseholds() async {
    final data = await _getCache();
    return [...data];
  }

  Future<HouseholdModel?> createHousehold(HouseholdModel household) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    final newId = data.isEmpty
        ? 100
        : data.fold<int>(0, (max, h) => h.id > max ? h.id : max) + 1;
    final newHh = HouseholdModel(
      id: newId,
      regionId: household.regionId,
      districtId: household.districtId,
      createdByAgentId: household.createdByAgentId,
      officialAddress: household.officialAddress,
      tumanName: household.tumanName,
      mfyName: household.mfyName,
      qfyName: household.qfyName,
      streetName: household.streetName,
      latitude: household.latitude,
      longitude: household.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      residents: [],
    );
    data.add(newHh);
    await _syncCache(prefs);
    return newHh;
  }

  Future<HouseholdModel?> updateHousehold(HouseholdModel household) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    final idx = data.indexWhere((h) => h.id == household.id);
    if (idx == -1) return null;
    final updated = HouseholdModel(
      id: household.id,
      regionId: household.regionId,
      districtId: household.districtId,
      createdByAgentId: household.createdByAgentId,
      officialAddress: household.officialAddress,
      tumanName: household.tumanName,
      mfyName: household.mfyName,
      qfyName: household.qfyName,
      streetName: household.streetName,
      latitude: household.latitude,
      longitude: household.longitude,
      createdAt: data[idx].createdAt,
      updatedAt: DateTime.now(),
      residents: household.residents,
    );
    data[idx] = updated;
    await _syncCache(prefs);
    return updated;
  }

  Future<bool> deleteHousehold(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    data.removeWhere((h) => h.id == id);
    await _syncCache(prefs);
    return true;
  }

  Future<ResidentModel?> createResident(ResidentModel resident) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    final hhIndex = data.indexWhere((h) => h.id == resident.householdId);
    if (hhIndex == -1) return null;
    int maxId = 0;
    for (var h in data) {
      for (var r in h.residents) {
        if (r.id > maxId) maxId = r.id;
      }
    }
    final newRes = ResidentModel(
      id: maxId + 1,
      householdId: data[hhIndex].id,
      firstName: resident.firstName,
      lastName: resident.lastName,
      phonePrimary: resident.phonePrimary,
      gender: resident.gender,
      role: resident.role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    data[hhIndex].residents.add(newRes);
    await _syncCache(prefs);
    return newRes;
  }

  Future<ResidentModel?> updateResident(ResidentModel resident) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    for (var hh in data) {
      final rIdx = hh.residents.indexWhere((r) => r.id == resident.id);
      if (rIdx != -1) {
        hh.residents[rIdx] = resident;
        await _syncCache(prefs);
        return resident;
      }
    }
    return null;
  }

  Future<bool> deleteResident(int residentId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _getCache();
    for (var hh in data) {
      final rIdx = hh.residents.indexWhere((r) => r.id == residentId);
      if (rIdx != -1) {
        hh.residents.removeAt(rIdx);
        await _syncCache(prefs);
        return true;
      }
    }
    return false;
  }

  /// Keshni qayta yuklashga majbur qilish (debug uchun)
  void resetCache() => _cache = null;
}
