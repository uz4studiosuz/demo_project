import '../models/household_model.dart';
import '../models/resident_model.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http; // TODO: REAL_API_INTEGRATION - http yoki dio paketlari orqali

class ApiService {
  // TODO: REAL_API_INTEGRATION - Haqiqiy backend API manzili
  // static const String baseUrl = "http://localhost:3000/api/v1";

  // MOCK DATA
  final List<HouseholdModel> _mockHouseholds = [
    HouseholdModel(
      id: 1,
      regionId: 1,
      districtId: 1,
      createdByAgentId: 1,
      officialAddress: "Farg'ona shahri, Mustang ko'chasi, 45-uy",
      latitude: 40.3860,
      longitude: 71.7825,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      residents: [
        ResidentModel(
          id: 1,
          householdId: 1,
          firstName: 'Alisher',
          lastName: 'Sodikov',
          phonePrimary: '+998901234567',
          isHighRiskMock: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ResidentModel(
          id: 2,
          householdId: 1,
          firstName: 'Nargiza',
          lastName: 'Sodikova',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ],
    ),
    HouseholdModel(
      id: 2,
      regionId: 1,
      districtId: 2,
      createdByAgentId: 1,
      officialAddress: "Marg'ilon shahri, B.Marg'iloniy ko'chasi, 12-uy",
      latitude: 40.4515,
      longitude: 71.7310,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      residents: [
        ResidentModel(
          id: 3,
          householdId: 2,
          firstName: 'Dilshod',
          lastName: 'Toshmatov',
          phonePrimary: '+998939876543',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ],
    ),
  ];

  /// Hamma householdlarni olib kelish
  /// TODO: REAL_API_INTEGRATION - NestJS-dagi `HouseholdController` va uning `@Get()` endpointi bilan ulanadi
  Future<List<HouseholdModel>> getHouseholds() async {
    /* 
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/households'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => HouseholdModel.fromJson(e)).toList();
      }
    } catch(e) {
      print(e);
    }
    */
    await Future.delayed(const Duration(seconds: 1));
    return [..._mockHouseholds];
  }

  /// Yangi xonadon (Household) yaratish
  /// TODO: REAL_API_INTEGRATION - NestJS-dagi `HouseholdController` `@Post()` bilan ulanadi
  Future<HouseholdModel?> createHousehold(HouseholdModel household) async {
    /*
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households'),
        body: jsonEncode(household.toJson()),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 201) {
        return HouseholdModel.fromJson(jsonDecode(response.body));
      }
    } catch(e) {
      // print("Save error: $e");
    }
    return null;
    */
    await Future.delayed(const Duration(seconds: 1));
    final newId = _mockHouseholds.isEmpty ? 1 : _mockHouseholds.last.id + 1;
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
    _mockHouseholds.add(newHh);
    // print("ApiService (Mock): Xonadon saqlandi: ${newHh.id}");
    return newHh;
  }

  /// Xonadonga yangi yashovchi (Resident) qo'shish
  /// TODO: REAL_API_INTEGRATION - NestJS-dagi `ResidentController` `@Post()` bilan ulanadi
  Future<ResidentModel?> createResident(ResidentModel resident) async {
    /*
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/residents'),
        body: jsonEncode(resident.toJson()),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 201) {
        return ResidentModel.fromJson(jsonDecode(response.body));
      }
      // print("Save error: $e");
    }
    return null;
    */
    await Future.delayed(const Duration(seconds: 1));
    final hhIndex = _mockHouseholds.indexWhere((h) => h.id == resident.householdId);
    if (hhIndex != -1) {
      final hh = _mockHouseholds[hhIndex];
      final newId = hh.residents.isEmpty ? (hh.id * 100) : hh.residents.last.id + 1; // mock ID gen
      
      final newRes = ResidentModel(
        id: newId,
        householdId: hh.id,
        firstName: resident.firstName,
        lastName: resident.lastName,
        phonePrimary: resident.phonePrimary,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      hh.residents.add(newRes);
      // print("ApiService (Mock): Yashovchi saqlandi: ${newRes.id}");
      return newRes;
    }
    return null;
  }

  /// Xonadonni o'chirish
  /// TODO: REAL_API_INTEGRATION - NestJS-dagi `HouseholdController` `@Delete(':id')` bilan ulanadi
  Future<bool> deleteHousehold(int id) async {
    /*
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/households/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch(e) {
      return false;
    }
    */
    await Future.delayed(const Duration(seconds: 1));
    _mockHouseholds.removeWhere((h) => h.id == id);
    // print("ApiService (Mock): Xonadon o'chirildi: $id");
    return true;
  }

  // TODO: REAL_API_INTEGRATION - Interceptor logikasi (Token qo'shish uchun xizmat qiladi)
  /*
  Future<Map<String, String>> _getHeaders() async {
    // Shoxobcha: auth_service dan accessToken ni olib kelib headerga uramiz
    // final token = await authService.getToken(); 
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }
  */
}
