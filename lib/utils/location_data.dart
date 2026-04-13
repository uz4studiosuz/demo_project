/// TODO: REAL_API_INTEGRATION
/// Ushbu ma'lumotlar hozircha demo holatda turibdi. Tizim to'liq backendga ulanganda
/// bu ro'yxatlar API dan (masalan, `/api/regions`, `/api/districts`, `/api/neighborhoods`)
/// orqali asinxron ravishda kelishi kerak. Hozirgi holat faqat UI ni sinash uchun mo'ljallangan.

class LocationData {
  static const List<String> tumanlar = [
    "Farg'ona sh.",
    "Marg'ilon sh.",
    "Qo'qon sh.",
    "Quvasoy sh.",
    "O'zbekiston tumani",
    "Farg'ona tumani",
    "Rishton tumani",
    "Quva tumani",
    "Toshloq tumani",
  ];

  static const Map<String, List<String>> qfylar = {
    "O'zbekiston tumani": ["Yakkatut", "Qudash", "Nursux", "Sho'rsuv"],
    "Quva tumani": ["Markaz", "Tolmozor", "Qoraqum", "Pastxalfa"],
    "Rishton tumani": ["Oqyer", "Bo'jay", "Zohidon"],
    "Farg'ona tumani": ["Vodil", "Mindon", "Shoximardon"],
  };

  static const Map<String, List<String>> mfylar = {
    "Farg'ona sh.": ["Tinchlik", "Oydin", "Marifat", "Kirgili"],
    "Marg'ilon sh.": ["Guliston", "Yangiariq", "Chilonzor"],
    "Qo'qon sh.": ["Bog'ishamol", "Navoiy", "Uchko'prik"],
    "O'zbekiston tumani": ["Navoiy", "Mustaqillik", "Bo'ston", "Ittifoq"],
    "Quva tumani": ["G'alaba", "Bahor", "Tinchlik"],
    "Toshloq tumani": ["Zarkent", "Sadda", "Nayman"],
    "Rishton tumani": ["Kulolchilar", "Markaziy", "Buloqboshi"],
  };

  static const List<String> kochalar = [
    "Go'zal diyor",
    "S. Temur",
    "Murabbiylar",
    "Navoiy",
    "Turkiston",
    "Guliston",
    "Markaziy",
    "Yangi hayot",
    "Mustaqillik",
    "A. Yassaviy",
  ];
}
