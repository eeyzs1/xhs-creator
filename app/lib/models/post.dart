import '../config/api_config.dart';

class Post {
  final String id;
  final String userId;
  final String? garmentImagePath;
  final String? streetPhotoPath;
  final String? tryonImagePath;
  final String description;
  final String tone;
  final String title;
  final String content;
  final List<String> tags;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    this.garmentImagePath,
    this.streetPhotoPath,
    this.tryonImagePath,
    this.description = '',
    this.tone = '种草',
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  String? get garmentImageUrl =>
      garmentImagePath != null ? ApiConfig.imageUrl(garmentImagePath!) : null;
  String? get streetPhotoUrl =>
      streetPhotoPath != null ? ApiConfig.imageUrl(streetPhotoPath!) : null;
  String? get tryOnImageUrl =>
      tryonImagePath != null ? ApiConfig.imageUrl(tryonImagePath!) : null;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      garmentImagePath: json['garment_image_path'] as String?,
      streetPhotoPath: json['street_photo_path'] as String?,
      tryonImagePath: json['tryon_image_path'] as String?,
      description: json['description'] as String? ?? '',
      tone: json['tone'] as String? ?? '种草',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'garment_image_path': garmentImagePath,
      'street_photo_path': streetPhotoPath,
      'tryon_image_path': tryonImagePath,
      'description': description,
      'tone': tone,
      'title': title,
      'content': content,
      'tags': tags,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? garmentImagePath,
    String? streetPhotoPath,
    String? tryonImagePath,
    String? description,
    String? tone,
    String? title,
    String? content,
    List<String>? tags,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      garmentImagePath: garmentImagePath ?? this.garmentImagePath,
      streetPhotoPath: streetPhotoPath ?? this.streetPhotoPath,
      tryonImagePath: tryonImagePath ?? this.tryonImagePath,
      description: description ?? this.description,
      tone: tone ?? this.tone,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
