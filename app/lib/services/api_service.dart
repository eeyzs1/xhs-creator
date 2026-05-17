import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/post.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token?.isNotEmpty ?? false) 'Authorization': 'Bearer $_token',
      };

  Future<User> registerWithUsername(String username, String password, {String? nickname}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        ...?nickname != null ? {'nickname': nickname} : null,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String?;
      if (accessToken != null) {
        _token = accessToken;
      }
      final userJson = data['user'] as Map<String, dynamic>;
      userJson['token'] = accessToken;
      return User.fromJson(userJson);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Registration failed';
      throw ApiException(response.statusCode, detail);
    }
  }

  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String?;
      if (accessToken != null) {
        _token = accessToken;
      }
      final userJson = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userJson);
      return User(
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        token: accessToken ?? user.token,
        createdAt: user.createdAt,
      );
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Login failed';
      throw ApiException(response.statusCode, detail);
    }
  }

  Future<Post> createPost({
    required Uint8List garmentImageBytes,
    required Uint8List streetPhotoBytes,
    required String description,
    required String tone,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}'),
    );

    request.headers.addAll({
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    request.fields['description'] = description;
    request.fields['tone'] = tone;

    request.files.add(http.MultipartFile.fromBytes(
      'garment_image',
      garmentImageBytes,
      filename: 'garment.jpg',
    ));
    request.files.add(http.MultipartFile.fromBytes(
      'street_photo',
      streetPhotoBytes,
      filename: 'street.jpg',
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw ApiException(response.statusCode, 'Invalid response format');
      }
      return Post.fromJson(data);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Post> generateTryOn(String postId, {String garmentType = 'tops'}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateTryOnEndpoint}'),
      headers: _headers,
      body: jsonEncode({
        'post_id': postId,
        'garment_type': garmentType,
      }),
    );

    if (response.statusCode == 200) {
      return await getPost(postId);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Post> generateCopywriting(String postId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateCopywritingEndpoint}'),
      headers: _headers,
      body: jsonEncode({'post_id': postId}),
    );

    if (response.statusCode == 200) {
      return await getPost(postId);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Post> editPost({
    required String postId,
    required String instruction,
    required String editType,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.editPostEndpoint}'),
      headers: _headers,
      body: jsonEncode({
        'post_id': postId,
        'instruction': instruction,
        'edit_type': editType,
      }),
    );

    if (response.statusCode == 200) {
      return await getPost(postId);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<List<Post>> getUserPosts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userPostsEndpoint}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> postsJson = data['posts'] as List<dynamic>? ?? [];
      return postsJson.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Post> getPost(String postId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}/$postId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw ApiException(response.statusCode, 'Invalid response format');
      }
      return Post.fromJson(data);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<String> downloadAndCacheImage(String url) async {
    if (kIsWeb) return url;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw ApiException(response.statusCode, 'Failed to download image');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}