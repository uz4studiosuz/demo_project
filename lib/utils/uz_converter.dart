class UzConverter {
  static const _latToCyr = {
    'sh': 'ш',
    'Sh': 'Ш',
    'sH': 'ш',
    'SH': 'Ш',
    'ch': 'ч',
    'Ch': 'Ч',
    'cH': 'ч',
    'CH': 'Ч',
    'yo': 'ё',
    'Yo': 'Ё',
    'yO': 'ё',
    'YO': 'Ё',
    'yu': 'ю',
    'Yu': 'Ю',
    'yU': 'ю',
    'YU': 'Ю',
    'ya': 'я',
    'Ya': 'Я',
    'yA': 'я',
    'YA': 'Я',
    'ye': 'е',
    'Ye': 'Е',
    'yE': 'е',
    'YE': 'Е',
    'o\'': 'ў',
    'O\'': 'Ў',
    'o’': 'ў',
    'O’': 'Ў',
    'o`': 'ў',
    'O`': 'Ў',
    'g\'': 'ғ',
    'G\'': 'Ғ',
    'g’': 'ғ',
    'G’': 'Ғ',
    'g`': 'ғ',
    'G`': 'Ғ',
    'a': 'а',
    'A': 'А',
    'b': 'б',
    'B': 'Б',
    'd': 'д',
    'D': 'Д',
    'e': 'е',
    'E': 'Е',
    'f': 'ф',
    'F': 'Ф',
    'g': 'г',
    'G': 'Г',
    'h': 'ҳ',
    'H': 'Ҳ',
    'i': 'и',
    'I': 'И',
    'j': 'ж',
    'J': 'Ж',
    'k': 'к',
    'K': 'К',
    'l': 'л',
    'L': 'Л',
    'm': 'м',
    'M': 'М',
    'n': 'н',
    'N': 'Н',
    'o': 'о',
    'O': 'О',
    'p': 'п',
    'P': 'П',
    'q': 'қ',
    'Q': 'Қ',
    'r': 'р',
    'R': 'Р',
    's': 'с',
    'S': 'С',
    't': 'т',
    'T': 'Т',
    'u': 'у',
    'U': 'У',
    'v': 'в',
    'V': 'В',
    'x': 'х',
    'X': 'Х',
    'y': 'й',
    'Y': 'Й',
    'z': 'з',
    'Z': 'З',
  };

  static const _cyrToLat = {
    'ш': 'sh',
    'Ш': 'Sh',
    'ч': 'ch',
    'Ч': 'Ch',
    'ё': 'yo',
    'Ё': 'Yo',
    'ю': 'yu',
    'Ю': 'Yu',
    'я': 'ya',
    'Я': 'Ya',
    'ў': 'o\'',
    'Ў': 'O\'',
    'ғ': 'g\'',
    'Ғ': 'G\'',
    'а': 'a',
    'А': 'A',
    'б': 'b',
    'Б': 'B',
    'в': 'v',
    'В': 'V',
    'г': 'g',
    'Г': 'G',
    'д': 'd',
    'Д': 'D',
    'е': 'e',
    'Е': 'E',
    'ж': 'j',
    'Ж': 'J',
    'з': 'z',
    'З': 'Z',
    'и': 'i',
    'И': 'I',
    'й': 'y',
    'Й': 'Y',
    'к': 'k',
    'К': 'K',
    'л': 'l',
    'Л': 'L',
    'м': 'm',
    'М': 'M',
    'н': 'n',
    'Н': 'N',
    'о': 'o',
    'О': 'O',
    'п': 'p',
    'П': 'P',
    'р': 'r',
    'Р': 'R',
    'с': 's',
    'С': 'S',
    'т': 't',
    'Т': 'T',
    'у': 'u',
    'У': 'U',
    'ф': 'f',
    'Ф': 'F',
    'х': 'x',
    'Х': 'X',
    'ц': 'ts',
    'Ц': 'Ts',
    'щ': 'shch',
    'Щ': 'Shch',
    'ь': '',
    'Ь': '',
    'ы': 'i',
    'Ы': 'I',
    'э': 'e',
    'Э': 'E',
    'қ': 'q',
    'Қ': 'Q',
    'ҳ': 'h',
    'Ҳ': 'H',
  };

  /// Lotin -> Krill
  static String toCyrillic(String text) {
    if (text.isEmpty) return text;
    String res = text;
    // 1. Sh, Ch, Yo kabi birikmalarni almashtiramiz
    final sortedKeys = _latToCyr.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (var key in sortedKeys) {
      if (key.length > 1) {
        res = res.replaceAll(key, _latToCyr[key]!);
      }
    }
    // 2. Bir harfliklarni almashtiramiz
    for (var key in sortedKeys) {
      if (key.length == 1) {
        res = res.replaceAll(key, _latToCyr[key]!);
      }
    }
    return res;
  }

  /// Krill -> Lotin
  static String toLatin(String text) {
    if (text.isEmpty) return text;
    String res = text;
    _cyrToLat.forEach((key, value) {
      res = res.replaceAll(key, value);
    });
    return res;
  }

  /// Avtomatik tarzda ikkinchi variantni qaytaradi
  static String convert(String text) {
    if (text.isEmpty) return "";
    bool isCyrillic = text.contains(RegExp(r'[а-яА-ЯқҳғўҚҲҒЎ]'));
    return isCyrillic ? toLatin(text) : toCyrillic(text);
  }
}
