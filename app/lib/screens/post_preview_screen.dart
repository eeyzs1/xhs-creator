import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../theme/xhs_theme.dart';
import '../widgets/loading_overlay.dart';
import 'edit_post_screen.dart';

class PostPreviewScreen extends StatefulWidget {
  const PostPreviewScreen({super.key});

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostProvider>();
      if (!provider.isGenerating) {
        provider.refreshCurrentPost();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getImages(Post? post) {
    final images = <String>[];
    if (post == null) return images;
    if (post.tryOnImageUrl != null && post.tryOnImageUrl!.isNotEmpty) {
      images.add(post.tryOnImageUrl!);
    }
    if (post.garmentImageUrl != null && post.garmentImageUrl!.isNotEmpty) {
      images.add(post.garmentImageUrl!);
    }
    if (post.streetPhotoUrl != null && post.streetPhotoUrl!.isNotEmpty) {
      images.add(post.streetPhotoUrl!);
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        final post = provider.currentPost;
        final images = _getImages(post);

        return LoadingOverlay(
          isLoading: provider.isGenerating,
          message: provider.generatingStep ?? (provider.isGenerating ? 'AI正在处理中...' : null),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 420,
                  pinned: true,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download, size: 18, color: Colors.white),
                      ),
                      onPressed: images.isNotEmpty && images[_currentImageIndex].isNotEmpty
                          ? () => _saveCurrentImageToGallery(images[_currentImageIndex])
                          : null,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: images.isNotEmpty
                        ? Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return Container(
                                    color: XhsTheme.background,
                                    child: CachedNetworkImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(XhsTheme.primaryRed),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: XhsTheme.background,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (images.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(images.length, (index) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        width: _currentImageIndex == index ? 20 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentImageIndex == index
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: XhsTheme.background,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('暂无图片', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPostContent(post),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(post),
          ),
        );
      },
    );
  }

  Widget _buildPostContent(Post? post) {
    if (post == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无内容')),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [XhsTheme.primaryRed, XhsTheme.primaryRedLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('📕', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '小红书创作助手',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: XhsTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(fontSize: 11, color: XhsTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: XhsTheme.tagBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.tone,
                  style: const TextStyle(fontSize: 11, color: XhsTheme.tagText, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (post.title.isNotEmpty)
            SelectableText(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: XhsTheme.textPrimary,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          if (post.content.isNotEmpty)
            SelectableText(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                color: XhsTheme.textPrimary,
                height: 1.8,
              ),
            ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.map((tag) {
                final colors = [
                  (XhsTheme.tagBackground, XhsTheme.tagText),
                  (XhsTheme.chipBlue, XhsTheme.chipBlueText),
                  (XhsTheme.chipGreen, XhsTheme.chipGreenText),
                  (XhsTheme.chipOrange, XhsTheme.chipOrangeText),
                  (XhsTheme.chipPurple, XhsTheme.chipPurpleText),
                ];
                final colorPair = colors[tag.hashCode.abs() % colors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorPair.$1,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorPair.$2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: XhsTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: XhsTheme.primaryRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '此内容由AI生成，你可以通过编辑指令进行调整',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: XhsTheme.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(Icons.favorite_border, '喜欢', Colors.grey),
              _buildActionButton(Icons.star_border, '收藏', Colors.grey),
              _buildActionButton(Icons.chat_bubble_outline, '评论', Colors.grey),
              _buildActionButton(Icons.copy_outlined, '复制', Colors.grey, onTap: () => _copyAllContent(post)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Post? post) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: XhsTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: post != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: context.read<PostProvider>(),
                              child: const EditPostScreen(),
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('编辑'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('即将上线'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAllContent(Post? post) {
    if (post == null) return;
    final buffer = StringBuffer();
    if (post.title.isNotEmpty) {
      buffer.writeln(post.title);
      buffer.writeln();
    }
    if (post.content.isNotEmpty) {
      buffer.writeln(post.content);
      buffer.writeln();
    }
    if (post.tags.isNotEmpty) {
      buffer.write(post.tags.map((t) => '#$t').join(' '));
    }
    final text = buffer.toString().trim();
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveCurrentImageToGallery(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await Gal.putImageBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已保存到相册'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存失败，请检查权限'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}
