/// Farg'ona viloyati — To'liq hudud ma'lumotlari (Mock, demo uchun)
/// REAL_API: Keyinchalik /api/districts, /api/neighborhoods dan keladi

class LocationData {
  // ─── Joylashuv turi ─────────────────────────────────────────────
  // isCity = true → bu shahar (MFY ro'yxati shahar uchun ko'rsatiladi)
  // isCity = false → bu tuman (qishloq MFY lari ko'rsatiladi)

  static const Map<String, bool> locationTypes = {
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

  // ─── MFY lar ─────────────────────────────────────────────────────
  // Shaharlar uchun - shahar MFY lari
  // Tumanlar uchun  - qishloq/mahalla MFY lari

  static const Map<String, List<String>> mfylar = {
    // ── SHAHARLAR ─────────────────────────────
    "Farg'ona sh.": [
      "Bag'ishamol MFY",
      "Bahor MFY",
      "Bog'ishamol MFY",
      "Darvozaqo'rg'on MFY",
      "Do'stlik MFY",
      "Fayz MFY",
      "G'alaba MFY",
      "Guliston MFY",
      "Hamkor MFY",
      "Istiqbol MFY",
      "Kirgili MFY",
      "Ko'hna shahar MFY",
      "Marifat MFY",
      "Milliy bog' MFY",
      "Mustaqillik MFY",
      "Navoiy MFY",
      "Navro'z MFY",
      "Niyozbekhoja MFY",
      "Oydin MFY",
      "Sarbon MFY",
      "Tinchlik MFY",
      "To'ytepa MFY",
      "Uychi MFY",
      "Vodil MFY",
      "Yangi Farg'ona MFY",
      "Yangi hayot MFY",
      "Yashillik MFY",
    ],
    "Marg'ilon sh.": [
      "Asaka MFY",
      "Atlas MFY",
      "Bog'boqcha MFY",
      "Bogiston MFY",
      "Chilonzor MFY",
      "Guliston MFY",
      "Hamza MFY",
      "Hisor MFY",
      "Markaziy MFY",
      "Mustaqillik MFY",
      "Navro'z MFY",
      "Pahlavon MFY",
      "Rizma MFY",
      "Soliqo'rg'on MFY",
      "Yangiariq MFY",
      "Yipak yo'li MFY",
    ],
    "Qo'qon sh.": [
      "Bog'ishamol MFY",
      "Do'stlik MFY",
      "G'ovsar MFY",
      "Guliston MFY",
      "Istiqbol MFY",
      "Ko'kdala MFY",
      "Markaziy MFY",
      "Mustakillik MFY",
      "Navoiy MFY",
      "Uchko'prik MFY",
      "Yangi hayot MFY",
    ],
    "Quvasoy sh.": [
      "Chimyon MFY",
      "Do'stlik MFY",
      "Markaziy MFY",
      "Navro'z MFY",
      "Tinchlik MFY",
      "Yangi MFY",
    ],

    // ── TUMANLAR ──────────────────────────────
    "Farg'ona tumani": [
      "Axunboboev MFY",
      "Bog'dod MFY",
      "Daminobod MFY",
      "Evchi MFY",
      "Janubiy MFY",
      "Kuyibozor MFY",
      "Mindon MFY",
      "Mustakillik MFY",
      "Poytovvoq MFY",
      "Sarbon MFY",
      "Shoximardon MFY",
      "Vodil MFY",
      "Yangiobod MFY",
    ],
    "O'zbekiston tumani": [
      "Bo'ston MFY",
      "G'ulomlar MFY",
      "Ittifoq MFY",
      "Mehnat MFY",
      "Mustaqillik MFY",
      "Navoiy MFY",
      "Nursux MFY",
      "Qudash MFY",
      "Sho'rsuv MFY",
      "Tinchlik MFY",
      "Yakkatut MFY",
    ],
    "Rishton tumani": [
      "Buloqboshi MFY",
      "Do'stlik MFY",
      "Istiqlol MFY",
      "Kulolchilar MFY",
      "Markaziy MFY",
      "Navro'z MFY",
      "Oqmachit MFY",
      "Oqyer MFY",
      "Zohidon MFY",
    ],
    "Quva tumani": [
      "Bahor MFY",
      "G'alaba MFY",
      "Ko'rg'oncha MFY",
      "Markaz MFY",
      "Pastxalfa MFY",
      "Qoraqum MFY",
      "Tinchlik MFY",
      "Tolmozor MFY",
    ],
    "Toshloq tumani": [
      "Bo'ston MFY",
      "Do'stlik MFY",
      "Nayman MFY",
      "Sadda MFY",
      "Tinchlik MFY",
      "Zarkent MFY",
    ],
    "Oltiariq tumani": [
      "Azizbek MFY",
      "Bog'li MFY",
      "Do'stlik MFY",
      "Guliston MFY",
      "Mustaqillik MFY",
      "Tinchlik MFY",
    ],
    "Beshariq tumani": [
      "Baxt MFY",
      "Gulshan MFY",
      "Mehribon MFY",
      "Mustaqillik MFY",
      "Obod MFY",
      "Tinchlik MFY",
    ],
    "Bog'dod tumani": [
      "Do'stlik MFY",
      "G'alaba MFY",
      "Markaziy MFY",
      "Navro'z MFY",
      "Yangi hayot MFY",
    ],
    "Dang'ara tumani": [
      "Bog'iston MFY",
      "Do'stlik MFY",
      "Markaziy MFY",
      "Tinchlik MFY",
    ],
    "Qo'shtepa tumani": [
      "Bahor MFY",
      "Do'stlik MFY",
      "Markaziy MFY",
      "Navro'z MFY",
    ],
    "So'x tumani": [
      "Markaziy MFY",
      "Oqsoy MFY",
      "So'x MFY",
      "Yangi hayot MFY",
    ],
    "Uchko'prik tumani": [
      "Bog'ishamol MFY",
      "Do'stlik MFY",
      "Markaziy MFY",
      "Navro'z MFY",
    ],
    "Yozyovon tumani": [
      "Bahor MFY",
      "G'alaba MFY",
      "Markaziy MFY",
      "Tinchlik MFY",
    ],
  };

  // ─── Ko'chalar (umumiy) ──────────────────────────────────────────
  // Keyinchalik MFY bo'yicha ham filtrlash mumkin

  static const List<String> kochalar = [
    "Amir Temur ko'chasi",
    "A. Navoiy ko'chasi",
    "Asaka ko'chasi",
    "Bahor ko'chasi",
    "Bog'ishamol ko'chasi",
    "Do'stlik ko'chasi",
    "Fayz ko'chasi",
    "G'alaba ko'chasi",
    "Go'zal diyor ko'chasi",
    "Guliston ko'chasi",
    "Hamza ko'chasi",
    "Istiqlol ko'chasi",
    "Ko'hna shahar ko'chasi",
    "Markaziy ko'cha",
    "Murabbiylar ko'chasi",
    "Mustaqillik ko'chasi",
    "Navro'z ko'chasi",
    "Navoiy ko'chasi",
    "Niyozbekhoja ko'chasi",
    "Sarbon ko'chasi",
    "Sulton Murodbek ko'chasi",
    "Tinchlik ko'chasi",
    "Turkiston ko'chasi",
    "Uychi ko'chasi",
    "Yangi hayot ko'chasi",
    "Yangi ko'cha",
    "Yashillik ko'chasi",
    "Yipak yo'li ko'chasi",
  ];
}
