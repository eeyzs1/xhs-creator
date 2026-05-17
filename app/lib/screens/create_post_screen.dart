import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../theme/xhs_theme.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_overlay.dart';
import 'post_preview_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _currentStep = 0;
  Uint8List? _garmentImageBytes;
  Uint8List? _streetPhotoBytes;
  final _descriptionController = TextEditingController();
  String _selectedTone = '种草';
  final List<String> _tones = ['种草', '穿搭', '日常', '高级感', '甜美'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _garmentImageBytes != null;
      case 1:
        return _streetPhotoBytes != null;
      case 2:
        return _descriptionController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submitPost() async {
    if (_garmentImageBytes == null || _streetPhotoBytes == null) return;

    final provider = context.read<PostProvider>();
    final post = await provider.createPost(
      garmentImageBytes: _garmentImageBytes!,
      streetPhotoBytes: _streetPhotoBytes!,
      description: _descriptionController.text.trim(),
      tone: _selectedTone,
    );

    if (!mounted) return;

    if (post != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const PostPreviewScreen(),
          ),
        ),
      );
      provider.generateAllContent(post.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '创建失败，请重试'),
          backgroundColor: XhsTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: context.watch<PostProvider>().isLoading,
      message: context.watch<PostProvider>().isLoading ? '正在上传...' : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('创建笔记'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SingleChildScrollView(
                    key: ValueKey(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? XhsTheme.primaryRed
                          : XhsTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: XhsTheme.tagBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '步骤 1/3',
                style: TextStyle(fontSize: 12, color: XhsTheme.tagText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '上传服装图片 👗',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XhsTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          '选择你想要试穿的服装，AI将帮你生成上身效果',
          style: TextStyle(fontSize: 13, color: XhsTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        ImagePickerWidget(
          label: '服装图片',
          hint: '点击上传服装图片',
          initialImageBytes: _garmentImageBytes,
          onImageSelected: (bytes) {
            setState(() => _garmentImageBytes = bytes);
          },
          height: 280,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: XhsTheme.chipBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '步骤 2/3',
                style: TextStyle(fontSize: 12, color: XhsTheme.chipBlueText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '上传街拍照片 📸',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XhsTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          '上传一张你的街拍或人像照片，AI将把服装穿到你身上',
          style: TextStyle(fontSize: 13, color: XhsTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        ImagePickerWidget(
          label: '街拍照片',
          hint: '点击上传街拍照片',
          initialImageBytes: _streetPhotoBytes,
          onImageSelected: (bytes) {
            setState(() => _streetPhotoBytes = bytes);
          },
          height: 280,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: XhsTheme.chipPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '步骤 3/3',
                style: TextStyle(fontSize: 12, color: XhsTheme.chipPurpleText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '描述你的笔记 ✍️',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XhsTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          '简单描述一下，AI将为你生成精美的文案',
          style: TextStyle(fontSize: 13, color: XhsTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '描述一下这件衣服的风格、场合、搭配想法...',
            hintStyle: const TextStyle(color: XhsTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: XhsTheme.divider),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        const Text(
          '选择文案风格',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: XhsTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _tones.map((tone) {
            final isSelected = tone == _selectedTone;
            return GestureDetector(
              onTap: () => setState(() => _selectedTone = tone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? XhsTheme.primaryRed : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? XhsTheme.primaryRed : XhsTheme.divider,
                  ),
                ),
                child: Text(
                  tone,
                  style: TextStyle(
                    color: isSelected ? Colors.white : XhsTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: XhsTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('上一步'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: _canProceed
                    ? () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _submitPost();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed ? XhsTheme.primaryRed : XhsTheme.divider,
                  foregroundColor: _canProceed ? Colors.white : XhsTheme.textTertiary,
                ),
                child: Text(_currentStep < 2 ? '下一步' : '✨ AI生成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
