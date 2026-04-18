import 'dart:io';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

class MapCacheService {
  static CacheStore? _cacheStore;

  static Future<CacheStore> get cacheStore async {
    if (_cacheStore != null) return _cacheStore!;
    
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/map_tiles_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    // http_cache_file_store paketidag FileCacheStore ishlatiladi
    _cacheStore = FileCacheStore(cacheDir.path);
    return _cacheStore!;
  }

  static Future<CacheOptions> getCacheOptions() async {
    final store = await cacheStore;
    return CacheOptions(
      store: store,
      policy: CachePolicy.forceCache,
      maxStale: const Duration(days: 30),
      priority: CachePriority.high,
    );
  }
}
