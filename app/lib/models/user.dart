class User {
  final String id;
  final String username;
  final String nickname;
  final String? avatar;
  final String token;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    required this.token,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '小红书用户',
      avatar: json['avatar'] as String?,
      token: json['token'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'token': token,
      'created_at': createdAt.toIso8601String(),
    };
  }
}