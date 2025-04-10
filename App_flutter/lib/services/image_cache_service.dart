import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, String> _memoryCache = {};
  final http.Client _httpClient = http.Client();
  static const int _maxMemoryCacheSize = 50;
  static const int _maxFileCacheSize = 100;
  Directory? _cacheDir;

  Future<String?> getCachedImage(String url) async {
    // 메모리 캐시 확인
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // 파일 캐시 확인
    final cacheDir = await _getCacheDir();
    final fileName = _generateFileName(url);
    final file = File('${cacheDir.path}/$fileName');

    if (await file.exists()) {
      final cachedPath = file.path;
      _addToMemoryCache(url, cachedPath);
      return cachedPath;
    }

    // 캐시에 없는 경우 다운로드
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _addToMemoryCache(url, file.path);
        await _cleanupOldCacheFiles();
        return file.path;
      }
    } catch (e) {
      print('이미지 캐싱 오류: $e');
    }

    return null;
  }

  Future<Directory> _getCacheDir() async {
    if (_cacheDir == null) {
      _cacheDir = await getTemporaryDirectory();
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.cache';
  }

  void _addToMemoryCache(String url, String filePath) {
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[url] = filePath;
  }

  Future<void> _cleanupOldCacheFiles() async {
    final cacheDir = await _getCacheDir();
    final files = await cacheDir.list().toList();
    
    if (files.length > _maxFileCacheSize) {
      // 파일 수정 시간 기준으로 정렬
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return aStat.modified.compareTo(bStat.modified);
      });

      // 오래된 파일 삭제
      for (var i = 0; i < files.length - _maxFileCacheSize; i++) {
        await files[i].delete();
      }
    }
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }
  }

  void dispose() {
    _httpClient.close();
  }
} 