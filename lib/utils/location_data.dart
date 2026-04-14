import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Farg'ona viloyati — To'liq hudud ma'lumotlari (Supabase + Local Cache)
class LocationData {
  // ─── Joylashuv turi (Fallback static data) ──────────────────────
  static Map<String, bool> locationTypes = {
    "Farg'ona sh.":       true,
    "Marg'ilon sh.":      true,
    "Qo'qon sh.":         true,
    "Quvasoy sh.":        true,
    "O'zbekiston tumani": false,
    "Farg'ona tumani":    false,
    "Rishton tumani":     false,
    "Quva tumani":        false,
    "Toshloq tumani":     false,
    "Oltiariq tumani":    false,
    "Beshariq tumani":    false,
    "Bog'dod tumani":     false,
    "Dang'ara tumani":    false,
    "Qo'shtepa tumani":   false,
    "So'x tumani":        false,
    "Uchko'prik tumani":  false,
    "Yozyovon tumani":    false,
  };

  /// Barcha tuman/shaharlar ro'yxati
  static List<String> get allLocations => locationTypes.keys.toList();

  /// Faqat shaharlar
  static List<String> get cities =>
      locationTypes.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Faqat tumanlar
  static List<String> get districts =>
      locationTypes.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Berilgan joy shaharmi?
  static bool isCity(String name) => locationTypes[name] ?? false;

  // ─── MFY lar (Fallback static data) ──────────────────────────────
  static Map<String, List<String>> mfylar = {
    "Farg'ona sh.": [
      "Bag'ishamol MFY", "Bahor MFY", "Bog'ishamol MFY", "Darvozaqo'rg'on MFY",
      "Do'stlik MFY", "Fayz MFY", "G'alaba MFY", "Guliston MFY", "Hamkor MFY",
      "Istiqbol MFY", "Kirgili MFY", "Ko'hna shahar MFY", "Marifat MFY",
      "Milliy bog' MFY", "Mustaqillik MFY", "Navoiy MFY", "Navro'z MFY",
      "Niyozbekhoja MFY", "Oydin MFY", "Sarbon MFY", "Tinchlik MFY",
      "To'ytepa MFY", "Uychi MFY", "Vodil MFY", "Yangi Farg'ona MFY",
      "Yangi hayot MFY", "Yashillik MFY",
    ],
    "Marg'ilon sh.": [
      "Asaka MFY", "Atlas MFY", "Bog'boqcha MFY", "Bogiston MFY", "Chilonzor MFY",
      "Guliston MFY", "Hamza MFY", "Hisor MFY", "Markaziy MFY", "Mustaqillik MFY",
      "Navro'z MFY", "Pahlavon MFY", "Rizma MFY", "Soliqo'rg'on MFY", "Yangiariq MFY",
      "Yipak yo'li MFY",
    ],
    "Qo'qon sh.": [
      "Bog'ishamol MFY", "Do'stlik MFY", "G'ovsar MFY", "Guliston MFY", "Istiqbol MFY",
      "Ko'kdala MFY", "Markaziy MFY", "Mustakillik MFY", "Navoiy MFY", "Uchko'prik MFY",
      "Yangi hayot MFY",
    ],
    "Quvasoy sh.": [
      "Chimyon MFY", "Do'stlik MFY", "Markaziy MFY", "Navro'z MFY", "Tinchlik MFY",
      "Yangi MFY",
    ],
    "Farg'ona tumani": [
      "Axunboboev MFY", "Bog'dod MFY", "Daminobod MFY", "Evchi MFY", "Janubiy MFY",
      "Kuyibozor MFY", "Mindon MFY", "Mustakillik MFY", "Poytovvoq MFY", "Sarbon MFY",
      "Shoximardon MFY", "Vodil MFY", "Yangiobod MFY",
    ],
    "O'zbekiston tumani": [
      "Bo'ston MFY", "G'ulomlar MFY", "Ittifoq MFY", "Mehnat MFY", "Mustaqillik MFY",
      "Navoiy MFY", "Nursux MFY", "Qudash MFY", "Sho'rsuv MFY", "Tinchlik MFY", "Yakkatut MFY",
    ],
    "Rishton tumani": [
      "Buloqboshi MFY", "Do'stlik MFY", "Istiqlol MFY", "Kulolchilar MFY", "Markaziy MFY",
      "Navro'z MFY", "Oqmachit MFY", "Oqyer MFY", "Zohidon MFY",
    ],
    "Quva tumani": [
      "Bahor MFY", "G'alaba MFY", "Ko'rg'oncha MFY", "Markaz MFY", "Pastxalfa MFY",
      "Qoraqum MFY", "Tinchlik MFY", "Tolmozor MFY",
    ],
    "Toshloq tumani": [
      "Bo'ston MFY", "Do'stlik MFY", "Nayman MFY", "Sadda MFY", "Tinchlik MFY", "Zarkent MFY",
    ],
    "Oltiariq tumani": [
      "Azizbek MFY", "Bog'li MFY", "Do'stlik MFY", "Guliston MFY", "Mustaqillik MFY", "Tinchlik MFY",
    ],
    "Beshariq tumani": [
      "Baxt MFY", "Gulshan MFY", "Mehribon MFY", "Mustaqillik MFY", "Obod MFY", "Tinchlik MFY",
    ],
    "Bog'dod tumani": [
      "Do'stlik MFY", "G'alaba MFY", "Markaziy MFY", "Navro'z MFY", "Yangi hayot MFY",
    ],
    "Dang'ara tumani": [
      "Bog'iston MFY", "Do'stlik MFY", "Markaziy MFY", "Tinchlik MFY",
    ],
    "Qo'shtepa tumani": [
      "Bahor MFY", "Do'stlik MFY", "Markaziy MFY", "Navro'z MFY",
    ],
    "So'x tumani": [
      "Markaziy MFY", "Oqsoy MFY", "So'x MFY", "Yangi hayot MFY",
    ],
    "Uchko'prik tumani": [
      "Bog'ishamol MFY", "Do'stlik MFY", "Markaziy MFY", "Navro'z MFY",
    ],
    "Yozyovon tumani": [
      "Bahor MFY", "G'alaba MFY", "Markaziy MFY", "Tinchlik MFY",
    ],
  };

  // ─── Ko'chalar (Fallback static data, MFY ga bog'langan) ───────
  static Map<String, List<String>> kochalar = {
    "Bag'ishamol MFY": ["Amir Temur ko'chasi", "A. Navoiy ko'chasi", "Asaka ko'chasi"],
    "Bahor MFY": ["Bahor ko'chasi", "Bog'ishamol ko'chasi", "Do'stlik ko'chasi"],
    "Darvozaqo'rg'on MFY": ["Fayz ko'chasi", "G'alaba ko'chasi", "Go'zal diyor ko'chasi"],
    "Asaka MFY": ["Guliston ko'chasi", "Hamza ko'chasi", "Istiqlol ko'chasi"],
    "Ko'hna shahar MFY": ["Ko'hna shahar ko'chasi", "Markaziy ko'cha", "Murabbiylar ko'chasi"],
  };

  // ─── SUPABASE TASKS ───
  static const String _cacheKeyDistricts = 'location_cache_districts';
  static const String _cacheKeyNeighborhoods = 'location_cache_neighborhoods';
  static const String _cacheKeyStreets = 'location_cache_streets';

  /// Ilova ochilganda `main.dart` dan chaqiriladi.
  /// Keshdan (SharedPrefs) datani o'qiydi va fon rejimida Supabase dan yangilaydi.
  static Future<void> initConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final districtsStr = prefs.getString(_cacheKeyDistricts);
      final neighborhoodsStr = prefs.getString(_cacheKeyNeighborhoods);
      final streetsStr = prefs.getString(_cacheKeyStreets);

      if (districtsStr != null && neighborhoodsStr != null && streetsStr != null) {
        _parseAndApplyData(
            jsonDecode(districtsStr),
            jsonDecode(neighborhoodsStr),
            jsonDecode(streetsStr)
        );
      }

      // Fon rejimida yangilash
      _syncWithSupabase();
    } catch (e) {
      debugPrint("LocationData init xatosi: \$e");
    }
  }

  static Future<void> _syncWithSupabase() async {
    try {
      final supabase = Supabase.instance.client;

      final responses = await Future.wait([
        supabase.from('districts').select('id, name, is_city'),
        supabase.from('neighborhoods').select('id, district_id, name'),
        supabase.from('streets').select('id, neighborhood_id, name').order('name', ascending: true),
      ]);

      final districtsData = responses[0] as List<dynamic>;
      final neighborhoodsData = responses[1] as List<dynamic>;
      final streetsData = responses[2] as List<dynamic>;

      // Xotiradagi o'zgaruvchilarni yangilaymiz
      _parseAndApplyData(districtsData, neighborhoodsData, streetsData);

      // Cache'ga saqlab qo'yamiz
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyDistricts, jsonEncode(districtsData));
      await prefs.setString(_cacheKeyNeighborhoods, jsonEncode(neighborhoodsData));
      await prefs.setString(_cacheKeyStreets, jsonEncode(streetsData));

      debugPrint("LocationData Supabase dan yangilandi.");
    } catch (e) {
      debugPrint("LocationData_sync xatosi (Internet yo'q bo'lishi mumkin): \$e");
    }
  }

  static void _parseAndApplyData(List<dynamic> districtsData, List<dynamic> neighborhoodsData, List<dynamic> streetsData) {
    Map<String, bool> tempLocationTypes = {};
    Map<int, String> districtIdToName = {};

    for (var d in districtsData) {
      final name = d['name'].toString();
      tempLocationTypes[name] = d['is_city'] ?? false;
      districtIdToName[d['id'] as int] = name;
    }

    Map<int, String> neighborhoodIdToName = {};
    Map<String, List<String>> tempMfylar = {};
    for (var n in neighborhoodsData) {
      final nId = n['id'] as int;
      final nName = n['name'].toString();
      neighborhoodIdToName[nId] = nName;

      int? dId = n['district_id'] as int?;
      if (dId != null && districtIdToName.containsKey(dId)) {
        String dName = districtIdToName[dId]!;
        tempMfylar.putIfAbsent(dName, () => []);
        tempMfylar[dName]!.add(nName);
      }
    }

    Map<String, List<String>> tempKochalar = {};
    for (var s in streetsData) {
      int? nId = s['neighborhood_id'] as int?;
      if (nId != null && neighborhoodIdToName.containsKey(nId)) {
        String nName = neighborhoodIdToName[nId]!;
        tempKochalar.putIfAbsent(nName, () => []);
        tempKochalar[nName]!.add(s['name'].toString());
      }
    }

    // Faqatgina bo'sh bo'lmasa o'zlashtiramiz (xavfsizlik)
    if (tempLocationTypes.isNotEmpty) locationTypes = tempLocationTypes;
    if (tempMfylar.isNotEmpty) mfylar = tempMfylar;
    if (tempKochalar.isNotEmpty) kochalar = tempKochalar;
    
    // Alifbo tartibida sortirovka
    for (var key in mfylar.keys) {
      mfylar[key]?.sort();
    }
  }
}

