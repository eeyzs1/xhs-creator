import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Post> _posts = [];
  Post? _currentPost;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<Post> get posts => _posts;
  Post? get currentPost => _currentPost;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _apiService.getUserPosts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Post?> createPost({
    required Uint8List garmentImageBytes,
    required Uint8List streetPhotoBytes,
    required String description,
    required String tone,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _apiService.createPost(
        garmentImageBytes: garmentImageBytes,
        streetPhotoBytes: streetPhotoBytes,
        description: description,
        tone: tone,
      );
      _currentPost = post;

      List<String> errors = [];
      try {
        final tryonPost = await _apiService.generateTryOn(post.id);
        _currentPost = tryonPost;
      } catch (e) {
        errors.add('试穿生成失败: $e');
      }

      try {
        final copyPost = await _apiService.generateCopywriting(_currentPost?.id ?? post.id);
        _currentPost = copyPost;
      } catch (e) {
        errors.add('文案生成失败: $e');
      }

      if (errors.isNotEmpty) {
        _error = errors.join('\n');
      }

      _isGenerating = false;
      notifyListeners();
      return _currentPost ?? post;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  Future<Post?> generateTryOn(String postId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _apiService.generateTryOn(postId);
      _currentPost = post;
      _isGenerating = false;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  Future<Post?> generateCopywriting(String postId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _apiService.generateCopywriting(postId);
      _currentPost = post;
      _isGenerating = false;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  Future<Post?> editPost({
    required String postId,
    required String instruction,
    required String editType,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _apiService.editPost(
        postId: postId,
        instruction: instruction,
        editType: editType,
      );
      _currentPost = post;
      _isGenerating = false;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  void setCurrentPost(Post post) {
    _currentPost = post;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentPost() {
    _currentPost = null;
    notifyListeners();
  }

  void clearAll() {
    _posts = [];
    _currentPost = null;
    _error = null;
    _isLoading = false;
    _isGenerating = false;
    notifyListeners();
  }
}
