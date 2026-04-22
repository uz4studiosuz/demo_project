class NamesData {
  // Barcha ismlar uchun asos (Base names)
  static const List<String> baseNames = [
    'Abbos',
    'Abdulla',
    'Abduvohid',
    'Abror',
    'Adham',
    'Akmal',
    'Akram',
    'Ali',
    'Alisher',
    'Anvar',
    'Asad',
    'Aziz',
    'Azamat',
    'Bahodir',
    'Baxtiyor',
    'Bobur',
    'Botir',
    'Davron',
    'Dilmurod',
    'Dilshod',
    'Doniyor',
    'Elyor',
    'Erali',
    'Ergash',
    'Farhod',
    'Farrux',
    'Fayzullo',
    'G\'ulom',
    'G\'ayrat',
    'Hakim',
    'Hamid',
    'Hasan',
    'Husan',
    'Ibrohim',
    'Iqbol',
    'Ismoil',
    'Isroil',
    'Izzat',
    'Jahongir',
    'Jalol',
    'Jamshid',
    'Jasur',
    'Javohir',
    'Kamol',
    'Karim',
    'Komil',
    'Laziz',
    'Mahmud',
    'Mansur',
    'Mirza',
    'Murod',
    'Muzaffar',
    'Nazar',
    'Nodir',
    'Norbek',
    'Obid',
    'Odil',
    'Olim',
    'Omon',
    'Orif',
    'Otabek',
    'Oybek',
    'Polat',
    'Qobil',
    'Qodir',
    'Qahramon',
    'Rahim',
    'Rahmon',
    'Ravshan',
    'Rustam',
    'Samat',
    'Sardor',
    'Sarvar',
    'Sherzod',
    'Shoxrux',
    'Shuhrat',
    'Sobir',
    'Sulton',
    'Tohir',
    'To\'lqin',
    'Umar',
    'Umid',
    'Usmon',
    'Vali',
    'Vohid',
    'Xalil',
    'Xurshid',
    'Yoqub',
    'Yo\'ldosh',
    'Zafar',
    'Zokir',
    'Ziyod',
  ];

  // Barcha variantlarni generatsiya qilish (Ism, Familiya, Sharif)
  static List<String> getAllVariants() {
    final List<String> variants = [];

    for (final name in baseNames) {
      // 1. Ism o'zi
      variants.add(name);

      // Suffixlarni aniqlash (oxirgi harfga qarab)
      final lastChar = name.substring(name.length - 1).toLowerCase();
      final isVowel = 'aeiou'.contains(
        lastChar,
      ); // o' undosh hisoblanadi suffix uchun

      String lastSuffix;
      String middleSuffix;

      if (isVowel) {
        // Unli bilan tugasa (Ali, Abdulla)
        lastSuffix = 'yev'; // Aliyev, Abdullayev
        middleSuffix = 'yevich';
      } else {
        // Undosh bilan tugasa (Karim, Rustam)
        lastSuffix = 'ov';
        middleSuffix = 'ovich';
      }

      // 2. Familiyalar (O'g'il bolalar)
      variants.add('$name$lastSuffix');
      // 3. Familiyalar (Qiz bolalar)
      variants.add('${name}${lastSuffix}a');

      // 4. Shariflar (O'g'il bolalar)
      variants.add('$name$middleSuffix'); // Karimovich
      variants.add('$name o\'g\'li'); // Karim o'g'li

      // 5. Shariflar (Qiz bolalar)
      variants.add(
        '${name}${middleSuffix.replaceAll('ich', 'na')}',
      ); // Karimovna
      variants.add('$name qizi'); // Karim qizi
    }

    return variants.toSet().toList(); // Dublikatlarni olib tashlash
  }

  // Eski listlarni saqlab turamiz (kodning boshqa joylari buzilmasligi uchun),
  // lekin ularni yangi algoritm asosida to'ldiramiz.
  static List<String> get defaultFirstNames => baseNames;

  static List<String> get defaultLastNames {
    final List<String> list = [];
    for (final name in baseNames) {
      final lastChar = name.substring(name.length - 1).toLowerCase();
      final isVowel = 'aeiou'.contains(lastChar);
      final suffix = isVowel ? 'yev' : 'ov';
      list.add('$name$suffix');
      list.add('${name}${suffix}a');
    }
    return list;
  }

  static List<String> get defaultMiddleNames {
    final List<String> list = ['O\'g\'li', 'Qizi'];
    for (final name in baseNames) {
      final lastChar = name.substring(name.length - 1).toLowerCase();
      final isVowel = 'aeiou'.contains(lastChar);
      final suffix = isVowel ? 'yevich' : 'ovich';
      list.add('$name$suffix');
      list.add('$name o\'g\'li');
      list.add('${name}${suffix.replaceAll('ich', 'na')}');
      list.add('$name qizi');
    }
    return list;
  }
}
