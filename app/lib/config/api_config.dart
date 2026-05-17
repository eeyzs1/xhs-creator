import 'package:flutter/foundation.dart';

class ApiConfig {
  static String _customBaseUrl = '';

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static void resetBaseUrl() {
    _customBaseUrl = '';
  }

  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String meEndpoint = '/api/auth/me';
  static const String postsEndpoint = '/api/posts';
  static const String generateTryOnEndpoint = '/api/ai/tryon';
  static const String generateCopywritingEndpoint = '/api/ai/copywriting';
  static const String editPostEndpoint = '/api/ai/edit';
  static const String userPostsEndpoint = '/api/posts';

  static String imageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final normalizedPath = path.replaceAll('\\', '/');
    return '$baseUrl/uploads/$normalizedPath';
  }
}