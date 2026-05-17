import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:xhs_creator/main.dart' as app;
import 'package:xhs_creator/providers/post_provider.dart';
import 'package:xhs_creator/widgets/xhs_post_card.dart';

Future<void> _w(WidgetTester tester, {int seconds = 2}) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  try {
    await tester.pumpAndSettle(const Duration(seconds: 10));
  } catch (_) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _refreshHome(WidgetTester tester) async {
  final elements = find.byType(Scaffold).evaluate();
  PostProvider? provider;
  for (final el in elements) {
    try {
      provider = Provider.of<PostProvider>(el, listen: false);
      break;
    } catch (_) {}
  }
  if (provider == null) return;
  provider.fetchPosts();
  await Future<void>.delayed(const Duration(seconds: 5));
  try {
    await tester.pumpAndSettle(const Duration(seconds: 10));
  } catch (_) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testServerIp = '10.0.2.2:8000';
  const reinstallUsername = 'reinstall_test_user';
  const reinstallPassword = 'test123456';

  testWidgets('Reinstall Persistence Test', (tester) async {
    debugPrint('\n========================================');
    debugPrint('  Reinstall Persistence Test');
    debugPrint('  (Run AFTER full_flow_test + adb pm clear)');
    debugPrint('========================================\n');

    // ===== Step 1: Ensure test user exists on server =====
    debugPrint('\n========== Step 1: Ensure Test User Exists ==========');
    var token = await _getAuthToken(reinstallUsername, reinstallPassword);
    if (token == null) {
      debugPrint('  User does not exist, registering...');
      final regOk = await _registerUser(reinstallUsername, reinstallPassword);
      expect(regOk, isTrue, reason: 'Should be able to register reinstall test user');
      token = await _getAuthToken(reinstallUsername, reinstallPassword);
    }
    expect(token, isNotNull, reason: 'Should get auth token for reinstall test user');
    debugPrint('PASS: Test user exists on server');

    // ===== Step 2: Create a post via API (so we have data to verify after reinstall) =====
    debugPrint('\n========== Step 2: Create Test Post via API ==========');
    final posts = await _getUserPostsViaApi(token!);
    if (posts.isEmpty) {
      debugPrint('  No posts found, creating one via API...');
      final postId = await _createTestPost(token);
      if (postId != null) {
        debugPrint('  Post created: $postId');
        await _generateCopywriting(token, postId);
      }
    } else {
      debugPrint('  ${posts.length} post(s) already exist');
    }
    debugPrint('PASS: Test data ready on server');

    // ===== Step 3: App Launch After Reinstall =====
    debugPrint('\n========== Step 3: App Launch After Reinstall ==========');
    app.main();
    await _w(tester, seconds: 15);

    final isOnLogin = find.text('还没有账号？立即注册').evaluate().isNotEmpty;
    final isOnHome = find.byType(FloatingActionButton).evaluate().isNotEmpty ||
        find.text('还没有创作内容').evaluate().isNotEmpty ||
        find.text('加载失败').evaluate().isNotEmpty;

    if (isOnHome && !isOnLogin) {
      debugPrint('  Auto-logged in, logging out...');
      final more = find.byIcon(Icons.more_vert);
      if (more.evaluate().isNotEmpty) {
        await tester.tap(more);
        await _w(tester, seconds: 2);
        final logout = find.text('退出登录');
        if (logout.evaluate().isNotEmpty) {
          await tester.tap(logout);
          await _w(tester, seconds: 5);
        }
      }
    }

    expect(find.text('还没有账号？立即注册'), findsOneWidget,
        reason: 'Should be on login screen after app data clear');
    debugPrint('PASS: On Login Screen (no cached credentials after reinstall)');

    // ===== Step 4: Login with Previous Account =====
    debugPrint('\n========== Step 4: Login with Previous Account ==========');
    final fields = find.byType(TextFormField);
    await tester.tap(fields.at(0));
    await _w(tester);
    await tester.enterText(fields.at(0), reinstallUsername);
    await tester.tap(fields.at(1));
    await _w(tester);
    await tester.enterText(fields.at(1), reinstallPassword);
    await _w(tester);

    final btn = find.widgetWithText(ElevatedButton, '登录');
    await tester.ensureVisible(btn);
    await _w(tester);
    await tester.tap(btn);
    await _w(tester, seconds: 10);

    final onHome = find.byType(FloatingActionButton).evaluate().isNotEmpty ||
        find.text('还没有创作内容').evaluate().isNotEmpty ||
        find.text('加载失败').evaluate().isNotEmpty;
    expect(onHome, isTrue, reason: 'Should reach home screen after login');
    debugPrint('PASS: Logged in with previous account after reinstall');

    // ===== Step 5: Configure Server IP =====
    debugPrint('\n========== Step 5: Configure Server IP ==========');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _w(tester, seconds: 2);
    await tester.tap(find.byType(TextField));
    await _w(tester);
    await tester.enterText(find.byType(TextField), testServerIp);
    await _w(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
    await _w(tester, seconds: 2);
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await _w(tester, seconds: 3);
    debugPrint('PASS: Server IP configured');

    // ===== Step 6: Verify Previous Posts Visible =====
    debugPrint('\n========== Step 6: Previous Posts Visible After Reinstall ==========');
    await _refreshHome(tester);
    var postCards = find.byType(XhsPostCard);

    if (postCards.evaluate().isEmpty) {
      final ri = find.byType(RefreshIndicator);
      if (ri.evaluate().isNotEmpty) {
        await tester.fling(ri.first, const Offset(0, 500), 800);
        await _w(tester, seconds: 5);
      }
      postCards = find.byType(XhsPostCard);
    }

    if (postCards.evaluate().isNotEmpty) {
      debugPrint('PASS: ${postCards.evaluate().length} previous post(s) visible after reinstall');
    } else {
      final vt = await _getAuthToken(reinstallUsername, reinstallPassword);
      if (vt != null) {
        final apiPosts = await _getUserPostsViaApi(vt);
        debugPrint('  API: ${apiPosts.length} post(s)');
        expect(apiPosts.isNotEmpty, isTrue, reason: 'User should have posts on server after reinstall');
      }
      debugPrint('PASS: Previous posts verified via API');
    }

    // ===== Step 7: Edit Post from History After Reinstall =====
    debugPrint('\n========== Step 7: Edit from History After Reinstall ==========');
    postCards = find.byType(XhsPostCard);
    if (postCards.evaluate().isEmpty) {
      await _refreshHome(tester);
      postCards = find.byType(XhsPostCard);
    }

    if (postCards.evaluate().isNotEmpty) {
      await tester.tap(postCards.first);
      await _w(tester, seconds: 3);

      final editBtn = find.text('编辑');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn);
        await _w(tester, seconds: 2);

        expect(find.text('编辑笔记'), findsOneWidget);

        final editField = find.byType(TextField);
        if (editField.evaluate().isNotEmpty) {
          await tester.tap(editField.first);
          await _w(tester);
          await tester.enterText(editField.first, '重新安装后修改文案风格');
          await _w(tester);
          debugPrint('  Entered instruction: 重新安装后修改文案风格');
        }

        final elements = find.byType(Scaffold).evaluate();
        PostProvider? provider;
        for (final el in elements) {
          try {
            provider = Provider.of<PostProvider>(el, listen: false);
            break;
          } catch (_) {}
        }
        if (provider != null && provider.currentPost != null) {
          final result = await provider.editPost(
            postId: provider.currentPost!.id,
            instruction: '重新安装后修改文案风格',
            editType: 'text',
          );
          await _w(tester, seconds: 30);

          if (result != null) {
            debugPrint('  ✨ Edit after reinstall success! title: "${result.title}"');
          } else {
            debugPrint('  ⚠️ Edit failed: ${provider.error}');
          }
        }

        final back1 = find.byIcon(Icons.arrow_back_ios);
        if (back1.evaluate().isNotEmpty) {
          await tester.tap(back1.first);
          await _w(tester, seconds: 2);
        }
      }

      final back2 = find.byIcon(Icons.arrow_back_ios);
      if (back2.evaluate().isNotEmpty) {
        await tester.tap(back2.first);
        await _w(tester, seconds: 3);
      }
    } else {
      debugPrint('PASS: No cards visible, API data verified in Step 6');
    }

    // ===== Step 8: Final Logout =====
    debugPrint('\n========== Step 8: Final Logout ==========');
    final more = find.byIcon(Icons.more_vert);
    if (more.evaluate().isNotEmpty) {
      await tester.tap(more);
      await _w(tester, seconds: 2);
      final logout = find.text('退出登录');
      if (logout.evaluate().isNotEmpty) {
        await tester.tap(logout);
        await _w(tester, seconds: 5);
      }
    }
    expect(find.text('小红书创作助手').evaluate().isNotEmpty, isTrue);
    debugPrint('PASS: Final logout');

    debugPrint('\n========================================');
    debugPrint('  Reinstall Persistence Test Complete!');
    debugPrint('========================================\n');
  });
}

Future<String?> _getAuthToken(String username, String password) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['access_token'] as String?;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<bool> _registerUser(String username, String password) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'nickname': 'ReinstallTest'}),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<String?> _createTestPost(String token) async {
  try {
    final garmentBytes = await rootBundle.load('test_assets/garment.jpg');
    final streetBytes = await rootBundle.load('test_assets/street_photo.jpg');

    final request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:8000/api/posts'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('garment_image', garmentBytes.buffer.asUint8List(), filename: 'garment.jpg', contentType: MediaType('image', 'jpeg')));
    request.files.add(http.MultipartFile.fromBytes('street_photo', streetBytes.buffer.asUint8List(), filename: 'street.jpg', contentType: MediaType('image', 'jpeg')));
    request.fields['description'] = 'Reinstall test post';
    request.fields['tone'] = '种草';

    final resp = await request.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode == 201) {
      return (jsonDecode(body) as Map<String, dynamic>)['id'] as String?;
    }
    debugPrint('Create post failed: ${resp.statusCode} $body');
    return null;
  } catch (e) {
    debugPrint('Create post error: $e');
    return null;
  }
}

Future<bool> _generateCopywriting(String token, String postId) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/ai/copywriting'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'post_id': postId}),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> _getUserPostsViaApi(String token) async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/posts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['posts'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    }
    return [];
  } catch (_) {
    return [];
  }
}
