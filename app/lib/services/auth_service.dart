import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _nicknameKey = 'user_nickname';
  static const String _createdAtKey = 'user_created_at';

  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _apiService.token != null;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);

    if (token != null && token.isNotEmpty && userId != null) {
      _apiService.setToken(token);
      final username = prefs.getString(_usernameKey) ?? '';
      final nickname = prefs.getString(_nicknameKey) ?? '小红书用户';
      final createdAtStr = prefs.getString(_createdAtKey);
      final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
      _currentUser = User(
        id: userId,
        username: username,
        nickname: nickname,
        token: token,
        createdAt: createdAt,
      );
      return true;
    }
    return false;
  }

  Future<User> register(String username, String password, {String? nickname}) async {
    final user = await _apiService.registerWithUsername(username, password, nickname: nickname);

    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _apiService.token ?? '');
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_nicknameKey, user.nickname);
    await prefs.setString(_createdAtKey, user.createdAt.toIso8601String());

    return user;
  }

  Future<User> login(String username, String password) async {
    final user = await _apiService.login(username, password);

    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _apiService.token ?? '');
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_nicknameKey, user.nickname);
    await prefs.setString(_createdAtKey, user.createdAt.toIso8601String());

    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nicknameKey);
    await prefs.remove(_createdAtKey);
    _currentUser = null;
    _apiService.setToken(null);
  }
}