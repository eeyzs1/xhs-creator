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
  String? _generatingStep;

  List<Post> get posts => _posts;
  Post? get currentPost => _currentPost;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String? get generatingStep => _generatingStep;

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
    _isLoading = true;
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
      _posts.insert(0, post);
      _isLoading = false;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> generateAllContent(String postId) async {
    _isGenerating = true;
    _error = null;
    _generatingStep = '正在生成试穿效果...';
    notifyListeners();

    try {
      final tryonPost = await _apiService.generateTryOn(postId);
      _currentPost = tryonPost;
      _syncPostToPosts(tryonPost);
      _generatingStep = '正在生成文案...';
      notifyListeners();
    } catch (e) {
      _error = '试穿生成失败: $e';
    }

    try {
      final copyPost = await _apiService.generateCopywriting(_currentPost?.id ?? postId);
      _currentPost = copyPost;
      _syncPostToPosts(copyPost);
    } catch (e) {
      final existingError = _error != null ? '${_error!}\n' : '';
      _error = '$existingError文案生成失败: $e';
    }

    _isGenerating = false;
    _generatingStep = null;
    notifyListeners();
  }

  Future<Post?> generateTryOn(String postId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _apiService.generateTryOn(postId);
      _currentPost = post;
      _syncPostToPosts(post);
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
      _syncPostToPosts(post);
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
      _syncPostToPosts(post);
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

  Future<void> refreshCurrentPost() async {
    if (_currentPost == null) return;
    try {
      final freshPost = await _apiService.getPost(_currentPost!.id);
      _currentPost = freshPost;
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _syncPostToPosts(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post;
    }
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
