// ═══════════════════════════════════════════════════════════════════════════
//  SUPABASE SERVICE  —  Barcha DB amallari
//  • households  jadvaldan o'qish/yozish
//  • residents   jadvaldan o'qish/yozish
//  • app_users   jadvaldan foydalanuvchi tekshirish (Auth)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/household_model.dart';
import '../models/resident_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseClient _db = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────
  //  AUTH
  // ─────────────────────────────────────────────────────────────────

  /// Login: app_users jadvaldan username va password tekshiradi.
  /// Parol DB da plain-text saqlanadi (demo rejim).
  /// Qaytaradi: UserModel yoki null (xato bo'lsa)
  static Future<UserModel?> login(String username, String password) async {
    try {
      final res = await _db
          .from('app_users')
          .select()
          .eq('username', username)
          .eq('password_hash', password)
          .eq('is_active', true)
          .maybeSingle();

      if (res == null) return null;
      return UserModel.fromJson(res);
    } catch (e) {
      // ignore: avoid_print
      print('[SupabaseService.login] Error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  HOUSEHOLDS
  // ─────────────────────────────────────────────────────────────────

  /// Barcha xonadonlarni residents bilan birga yuklaydi.
  static Future<List<HouseholdModel>> getHouseholds() async {
    try {
      final res = await _db
          .from('households')
          .select('*, residents(*)')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (res as List<dynamic>)
          .map((e) => HouseholdModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[SupabaseService.getHouseholds] Error: $e');
      return [];
    }
  }

  /// Millionlab ma'lumotlar uchun server-side qidiruv.
  /// Faqat qidiruvga mos keladigan 50 ta natijani qaytaradi.
  static Future<List<HouseholdModel>> searchHouseholdsRemote(String query) async {
    try {
      final res = await _db
          .from('households')
          .select('*, residents(*)')
          .or('official_address.ilike.%$query%,tuman_name.ilike.%$query%,mfy_name.ilike.%$query%,street_name.ilike.%$query%,house_number.ilike.%$query%')
          .eq('is_active', true)
          .limit(50);

      final list = (res as List<dynamic>)
          .map((e) => HouseholdModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Agar xonadondan topilmasa, residentlar ismidan ham qidirib ko'rishimiz mumkin
      // (Eslatma: Murakkab qidiruvlar uchun DB da View yoki RPC ishlatish tavsiya etiladi)
      return list;
    } catch (e) {
      print('[SupabaseService.searchHouseholdsRemote] Error: $e');
      return [];
    }
  }

  /// Yangi xonadon yaratadi. Qaytaradi: yaratilgan HouseholdModel yoki null.
  static Future<HouseholdModel?> createHousehold(HouseholdModel h) async {
    try {
      final payload = {
        'region_id': h.regionId,
        'district_id': h.districtId,
        if (h.branchId != null) 'branch_id': h.branchId,
        'created_by_agent_id': h.createdByAgentId,
        if (h.cadastralNumber != null) 'cadastral_number': h.cadastralNumber,
        'official_address': h.officialAddress,
        if (h.houseNumber != null) 'house_number': h.houseNumber,
        if (h.apartment != null) 'apartment': h.apartment,
        if (h.buildingNumber != null) 'building_number': h.buildingNumber,
        if (h.floor != null) 'floor': h.floor,
        if (h.landmark != null) 'landmark': h.landmark,
        'latitude': h.latitude,
        'longitude': h.longitude,
        'is_verified': h.isVerified,
        'is_active': h.isActive,
        'property_type': h.propertyType,
        if (h.tumanName != null) 'tuman_name': h.tumanName,
        if (h.qfyName != null) 'qfy_name': h.qfyName,
        if (h.mfyName != null) 'mfy_name': h.mfyName,
        if (h.streetName != null) 'street_name': h.streetName,
      };

      final res = await _db
          .from('households')
          .insert(payload)
          .select()
          .single();

      return HouseholdModel.fromJson({...res, 'residents': []});
    } catch (e) {
      print('[SupabaseService.createHousehold] Error: $e');
      return null;
    }
  }

  /// Xonadonni yangilaydi.
  static Future<HouseholdModel?> updateHousehold(HouseholdModel h) async {
    try {
      print('🔵 [SupabaseService.updateHousehold] ID: ${h.id}');
      final payload = {
        'official_address': h.officialAddress,
        if (h.houseNumber != null) 'house_number': h.houseNumber,
        if (h.apartment != null) 'apartment': h.apartment,
        if (h.buildingNumber != null) 'building_number': h.buildingNumber,
        if (h.floor != null) 'floor': h.floor,
        if (h.landmark != null) 'landmark': h.landmark,
        'latitude': h.latitude,
        'longitude': h.longitude,
        'property_type': h.propertyType,
        if (h.tumanName != null) 'tuman_name': h.tumanName,
        if (h.qfyName != null) 'qfy_name': h.qfyName,
        if (h.mfyName != null) 'mfy_name': h.mfyName,
        if (h.streetName != null) 'street_name': h.streetName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final res = await _db
          .from('households')
          .update(payload)
          .eq('id', h.id)
          .select('*, residents(*)')
          .single();

      return HouseholdModel.fromJson(res);
    } catch (e) {
      print('[SupabaseService.updateHousehold] Error: $e');
      return null;
    }
  }

  /// Xonadonni soft-delete qiladi (is_active = false).
  static Future<bool> deleteHousehold(int id) async {
    try {
      await _db
          .from('households')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('[SupabaseService.deleteHousehold] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  RESIDENTS
  // ─────────────────────────────────────────────────────────────────

  /// Yangi resident yaratadi.
  static Future<ResidentModel?> createResident(ResidentModel r) async {
    try {
      final payload = {
        'household_id': r.householdId,
        'first_name': r.firstName,
        'last_name': r.lastName,
        if (r.middleName != null) 'middle_name': r.middleName,
        if (r.fullName != null) 'full_name': r.fullName,
        if (r.phonePrimary != null) 'phone_primary': r.phonePrimary,
        if (r.phoneSecondary != null) 'phone_secondary': r.phoneSecondary,
        if (r.birthDate != null)
          'birth_date': r.birthDate!.toIso8601String().split('T')[0],
        'gender': r.gender,
        if (r.role != null) 'role': r.role,
        'is_active': true,
      };

      final res = await _db.from('residents').insert(payload).select().single();

      return ResidentModel.fromJson(res);
    } catch (e) {
      print('[SupabaseService.createResident] Error: $e');
      return null;
    }
  }

  /// Residentni yangilaydi.
  static Future<ResidentModel?> updateResident(ResidentModel r) async {
    try {
      final payload = {
        'first_name': r.firstName,
        'last_name': r.lastName,
        if (r.middleName != null) 'middle_name': r.middleName,
        if (r.fullName != null) 'full_name': r.fullName,
        if (r.phonePrimary != null) 'phone_primary': r.phonePrimary,
        if (r.phoneSecondary != null) 'phone_secondary': r.phoneSecondary,
        if (r.birthDate != null)
          'birth_date': r.birthDate!.toIso8601String().split('T')[0],
        'gender': r.gender,
        if (r.role != null) 'role': r.role,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final res = await _db
          .from('residents')
          .update(payload)
          .eq('id', r.id)
          .select()
          .single();

      return ResidentModel.fromJson(res);
    } catch (e) {
      print('[SupabaseService.updateResident] Error: $e');
      return null;
    }
  }

  /// Residentni soft-delete qiladi.
  static Future<bool> deleteResident(int id) async {
    try {
      await _db
          .from('residents')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('[SupabaseService.deleteResident] Error: $e');
      return false;
    }
  }

  /// Xonadon uchun barcha residentlarni o'chiradi (soft-delete).
  static Future<void> deleteResidentsByHousehold(int householdId) async {
    try {
      await _db
          .from('residents')
          .delete()
          .eq('household_id', householdId);
    } catch (e) {
      print('[SupabaseService.deleteResidentsByHousehold] Error: $e');
    }
  }
}
