import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../theme/xhs_theme.dart';
import '../widgets/loading_overlay.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _instructionController = TextEditingController();
  String _editType = '修改文案';
  final List<String> _editTypes = ['修改文案', '修改图片', '同时修改'];
  final List<String> _quickEdits = ['换一种风格', '更活泼一些', '更专业', '添加更多细节'];

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) return;

    final provider = context.read<PostProvider>();
    final post = provider.currentPost;
    if (post == null) return;

    String editTypeKey;
    switch (_editType) {
      case '修改文案':
        editTypeKey = 'text';
        break;
      case '修改图片':
        editTypeKey = 'image';
        break;
      default:
        editTypeKey = 'both';
    }

    final result = await provider.editPost(
      postId: post.id,
      instruction: instruction,
      editType: editTypeKey,
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ 编辑成功！'),
          backgroundColor: XhsTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '编辑失败，请重试'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final post = provider.currentPost;

    return LoadingOverlay(
      isLoading: provider.isGenerating,
      message: provider.isGenerating ? 'AI正在根据你的指令修改...\n请稍候' : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑笔记'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: XhsTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.article_outlined, size: 18, color: XhsTheme.primaryRed),
                          const SizedBox(width: 6),
                          const Text(
                            '当前内容',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: XhsTheme.primaryRed),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (post.title.isNotEmpty)
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: XhsTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (post.content.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 13, color: XhsTheme.textSecondary, height: 1.6),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: post.tags.take(5).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: XhsTheme.tagBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(fontSize: 10, color: XhsTheme.tagText),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                '编辑指令 ✍️',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: XhsTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                '用自然语言告诉AI你想怎么修改',
                style: TextStyle(fontSize: 13, color: XhsTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '例如：把文案改得更活泼一些，加入更多emoji...',
                  hintStyle: const TextStyle(color: XhsTheme.textTertiary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '快捷指令',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: XhsTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickEdits.map((edit) {
                  return ActionChip(
                    label: Text(edit),
                    onPressed: () {
                      _instructionController.text = edit;
                      setState(() {});
                    },
                    backgroundColor: XhsTheme.tagBackground,
                    labelStyle: const TextStyle(color: XhsTheme.tagText, fontSize: 13),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                '编辑类型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: XhsTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: _editTypes.map((type) {
                  final isSelected = type == _editType;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _editType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? XhsTheme.primaryRed : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? XhsTheme.primaryRed : XhsTheme.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.white : XhsTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isGenerating
                      ? null
                      : (_instructionController.text.trim().isNotEmpty ? _submitEdit : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _instructionController.text.trim().isNotEmpty
                        ? XhsTheme.primaryRed
                        : XhsTheme.divider,
                    foregroundColor: _instructionController.text.trim().isNotEmpty
                        ? Colors.white
                        : XhsTheme.textTertiary,
                  ),
                  child: provider.isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('AI 正在处理...'),
                          ],
                        )
                      : const Text('✨ 提交编辑'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
