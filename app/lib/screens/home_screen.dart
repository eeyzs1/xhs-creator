import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../services/auth_service.dart';
import '../theme/xhs_theme.dart';
import '../widgets/xhs_post_card.dart';
import 'create_post_screen.dart';
import 'login_screen.dart';
import 'post_preview_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XhsTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📕 '),
            const Text(
              '小红书创作助手',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (context.mounted) {
                context.read<PostProvider>().fetchPosts();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().logout();
                if (!context.mounted) return;
                context.read<PostProvider>().clearAll();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: XhsTheme.textSecondary),
                    SizedBox(width: 8),
                    Text('退出登录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.posts.isEmpty) {
            return _buildLoadingGrid();
          }

          if (provider.error != null && provider.posts.isEmpty) {
            return _buildErrorState(provider);
          }

          if (provider.posts.isEmpty) {
            return _buildEmptyState(provider);
          }

          return RefreshIndicator(
            color: XhsTheme.primaryRed,
            onRefresh: () => provider.fetchPosts(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: provider.posts.length,
                itemBuilder: (context, index) {
                  return XhsPostCard(
                    post: provider.posts[index],
                    onTap: () => _navigateToPreview(context, provider.posts[index]),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(PostProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            '还没有创作内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: XhsTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮开始你的第一篇创作',
            style: TextStyle(fontSize: 13, color: XhsTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreate(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('开始创作'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PostProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: XhsTheme.textTertiary),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: XhsTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? '请检查网络连接或服务器地址',
            style: const TextStyle(fontSize: 13, color: XhsTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchPosts(),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('重试'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('检查服务器设置'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            height: (index % 3 + 2) * 80.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: XhsTheme.divider,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: XhsTheme.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: XhsTheme.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<PostProvider>(),
          child: const CreatePostScreen(),
        ),
      ),
    );
    if (context.mounted) {
      context.read<PostProvider>().fetchPosts();
    }
  }

  void _navigateToPreview(BuildContext context, Post post) async {
    final provider = context.read<PostProvider>();
    provider.setCurrentPost(post);
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const PostPreviewScreen(),
        ),
      ),
    );
    if (result == true && context.mounted) {
      provider.fetchPosts();
    }
  }
}
