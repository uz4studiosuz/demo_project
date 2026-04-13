import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';

/// Lokal saqlash bilan ishlaydigan API service.
/// SharedPreferences orqali ma'lumotlarni disk'ga saqlaydi.
/// Ilova qayta ishga tushirilsa ham barcha xatlovlar saqlanib qoladi.
class ApiService {
  // SharedPreferences kalit nomi
  static const String _storageKey = 'households_data';

  // Xotiradagi cache — har safar diskdan o'qimaslik uchun
  List<HouseholdModel>? _cache;

  // ─── Boshlang'ich demo ma'lumotlar ────────────────────────────
  List<HouseholdModel> _getDefaultData() {
    return [
      HouseholdModel(
        id: 1,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "O'zbekiston tumani, Yakkatut, Go'zal diyor 156",
        latitude: 40.440239,
        longitude: 70.883328,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 1,
            householdId: 1,
            firstName: 'Alisher',
            lastName: 'Sodikov',
            phonePrimary: '+998901234567',
            isHighRiskMock: false,
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ResidentModel(
            id: 2,
            householdId: 1,
            firstName: 'Nargiza',
            lastName: 'Sodikova',
            gender: 'FEMALE',
            role: 'Turmush o\'rtog\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 2,
        regionId: 1,
        districtId: 2,
        createdByAgentId: 1,
        officialAddress: "O'zbekiston tumani, Qudash, Mustaqillik 23",
        latitude: 40.429293,
        longitude: 70.877771,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 3,
            householdId: 2,
            firstName: 'Dilshod',
            lastName: 'Toshmatov',
            phonePrimary: '+998939876543',
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 3,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Farg'ona sh., S. Temur ko'chasi, 45-uy",
        latitude: 40.3842,
        longitude: 71.7825,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 4,
            householdId: 3,
            firstName: 'Bobur',
            lastName: 'Karimov',
            phonePrimary: '+998901112233',
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 4,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Farg'ona sh., Murabbiylar ko'chasi, 12-uy",
        latitude: 40.3885,
        longitude: 71.7890,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 5,
            householdId: 4,
            firstName: 'Malika',
            lastName: 'Azimova',
            phonePrimary: '+998912223344',
            gender: 'FEMALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 5,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Marg'ilon sh., Navoiy ko'chasi, 88-uy",
        latitude: 40.4685,
        longitude: 71.7330,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 6,
            householdId: 5,
            firstName: 'Jasur',
            lastName: 'Hamidov',
            phonePrimary: '+998943334455',
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 6,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Qo'qon sh., Turkiston ko'chasi, 5-uy",
        latitude: 40.5315,
        longitude: 70.9410,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 7,
            householdId: 6,
            firstName: 'Bekzod',
            lastName: 'Ismoilov',
            phonePrimary: '+998974445566',
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 7,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Quva tumani, Markaz, Guliston ko'chasi",
        latitude: 40.5210,
        longitude: 72.0120,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 8,
            householdId: 7,
            firstName: 'Ziyoda',
            lastName: 'Umarova',
            phonePrimary: '+998991110099',
            gender: 'FEMALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      HouseholdModel(
        id: 8,
        regionId: 1,
        districtId: 1,
        createdByAgentId: 1,
        officialAddress: "Rishton tumani, Kulolchilar mahallasi",
        latitude: 40.3560,
        longitude: 71.2850,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        residents: [
          ResidentModel(
            id: 9,
            householdId: 8,
            firstName: 'G\'olib',
            lastName: 'Rahmonov',
            phonePrimary: '+998905556677',
            gender: 'MALE',
            role: 'Oila boshlig\'i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  //  DISK BILAN ISHLASH
  // ═══════════════════════════════════════════════════════════════

  /// SharedPreferences'dan barcha xatlovlarni o'qiydi
  Future<List<HouseholdModel>> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    final defaults = _getDefaultData();

    if (jsonStr == null) {
      // Birinchi marta — demo ma'lumotlarni saqlaymiz
      await _saveToDisk(defaults);
      return defaults;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      final List<HouseholdModel> diskData = jsonList
          .map((e) => HouseholdModel.fromJson(e))
          .toList();

      // Yangi qo'shilgan demo ma'lumotlarni tekshiramiz va qo'shamiz
      bool changed = false;
      for (var defHh in defaults) {
        if (!diskData.any((h) => h.id == defHh.id)) {
          diskData.add(defHh);
          changed = true;
        }
      }

      if (changed) {
        await _saveToDisk(diskData);
      }

      return diskData;
    } catch (e) {
      // Agar JSON buzilgan bo'lsa — qaytadan default
      await _saveToDisk(defaults);
      return defaults;
    }
  }

  /// Barcha xatlovlarni diskka saqlaydi
  Future<void> _saveToDisk(List<HouseholdModel> households) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(households.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Cache'ni yangilaydi va diskka saqlaydi
  Future<void> _syncToDisk() async {
    if (_cache != null) {
      await _saveToDisk(_cache!);
    }
  }

  /// Cache'ni yuklaydi (lazy initialization)
  Future<List<HouseholdModel>> _getCache() async {
    _cache ??= await _loadFromDisk();
    return _cache!;
  }

  // ═══════════════════════════════════════════════════════════════
  //  CRUD OPERATSIYALAR
  // ═══════════════════════════════════════════════════════════════

  /// Hamma householdlarni olib kelish
  /// TODO: REAL_API_INTEGRATION - NestJS-dagi `HouseholdController` va uning `@Get()` endpointi bilan ulanadi
  Future<List<HouseholdModel>> getHouseholds() async {
    final data = await _getCache();
    return [...data]; // Copy qaytarish (tashqi mutatsiyani oldini olish uchun)
  }

  /// Yangi xonadon yaratish
  /// TODO: REAL_API_INTEGRATION - NestJS `@Post()`
  Future<HouseholdModel?> createHousehold(HouseholdModel household) async {
    final data = await _getCache();
    final newId = data.isEmpty
        ? 1
        : data.fold<int>(0, (max, h) => h.id > max ? h.id : max) + 1;
    final newHh = HouseholdModel(
      id: newId,
      regionId: household.regionId,
      districtId: household.districtId,
      createdByAgentId: household.createdByAgentId,
      officialAddress: household.officialAddress,
      latitude: household.latitude,
      longitude: household.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      residents: [],
    );
    data.add(newHh);
    await _syncToDisk();
    return newHh;
  }

  /// Xonadonni tahrirlash (yangilash)
  /// TODO: REAL_API_INTEGRATION - NestJS `@Patch(':id')`
  Future<HouseholdModel?> updateHousehold(HouseholdModel household) async {
    final data = await _getCache();
    final idx = data.indexWhere((h) => h.id == household.id);
    if (idx == -1) return null;

    final updated = HouseholdModel(
      id: household.id,
      regionId: household.regionId,
      districtId: household.districtId,
      createdByAgentId: household.createdByAgentId,
      officialAddress: household.officialAddress,
      latitude: household.latitude,
      longitude: household.longitude,
      createdAt: data[idx].createdAt,
      updatedAt: DateTime.now(),
      residents: household.residents,
    );
    data[idx] = updated;
    await _syncToDisk();
    return updated;
  }

  /// Xonadonni o'chirish
  /// TODO: REAL_API_INTEGRATION - NestJS `@Delete(':id')`
  Future<bool> deleteHousehold(int id) async {
    final data = await _getCache();
    data.removeWhere((h) => h.id == id);
    await _syncToDisk();
    return true;
  }

  /// Yashovchi qo'shish
  /// TODO: REAL_API_INTEGRATION - NestJS `@Post()`
  Future<ResidentModel?> createResident(ResidentModel resident) async {
    final data = await _getCache();
    final hhIndex = data.indexWhere((h) => h.id == resident.householdId);
    if (hhIndex == -1) return null;

    final hh = data[hhIndex];
    // Yangi ID generatsiya
    int maxId = 0;
    for (var h in data) {
      for (var r in h.residents) {
        if (r.id > maxId) maxId = r.id;
      }
    }
    final newId = maxId + 1;

    final newRes = ResidentModel(
      id: newId,
      householdId: hh.id,
      firstName: resident.firstName,
      lastName: resident.lastName,
      phonePrimary: resident.phonePrimary,
      gender: resident.gender,
      role: resident.role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    hh.residents.add(newRes);
    await _syncToDisk();
    return newRes;
  }

  /// Yashovchini tahrirlash
  Future<ResidentModel?> updateResident(ResidentModel resident) async {
    final data = await _getCache();
    for (var hh in data) {
      final rIdx = hh.residents.indexWhere((r) => r.id == resident.id);
      if (rIdx != -1) {
        hh.residents[rIdx] = resident;
        await _syncToDisk();
        return resident;
      }
    }
    return null;
  }

  /// Yashovchini o'chirish
  Future<bool> deleteResident(int residentId) async {
    final data = await _getCache();
    for (var hh in data) {
      final rIdx = hh.residents.indexWhere((r) => r.id == residentId);
      if (rIdx != -1) {
        hh.residents.removeAt(rIdx);
        await _syncToDisk();
        return true;
      }
    }
    return false;
  }

  // TODO: REAL_API_INTEGRATION - Interceptor logikasi
  /*
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }
  */
}
