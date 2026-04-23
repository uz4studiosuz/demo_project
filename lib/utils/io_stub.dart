// Web platformasi uchun dart:io stub.
// Conditional import: `dart:io` o'rniga ushbu fayl ishlatiladi.
// `Directory.systemTemp` faqat `kIsWeb ? null : ...` ichida ishlatilgani uchun
// bu class hech qachon chaqirilmaydi, lekin compile xatosini oldini oladi.

class Directory {
  final String path;
  const Directory(this.path);

  static Directory get systemTemp => const Directory('/tmp');
}
