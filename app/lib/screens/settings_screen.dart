import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme/xhs_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _serverIpKey = 'server_ip';
  final _controller = TextEditingController();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(_serverIpKey) ?? '';
    if (savedIp.isNotEmpty) {
      _controller.text = savedIp;
    } else {
      _controller.text = '10.0.2.2:8000';
    }
  }

  Future<void> _save() async {
    final ip = _controller.text.trim();
    if (ip.isEmpty) return;

    final url = ip.startsWith('http') ? ip : 'http://$ip';
    ApiConfig.setBaseUrl(url);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ip);

    setState(() => _isSaved = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('服务器地址已保存'),
        backgroundColor: XhsTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _reset() async {
    ApiConfig.resetBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverIpKey);
    _controller.text = '10.0.2.2:8000';
    setState(() => _isSaved = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已恢复默认地址'),
        backgroundColor: XhsTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('服务器设置'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(_isSaved),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: XhsTheme.tagBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: XhsTheme.primaryRed, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '设置后端服务器的 IP 地址和端口，方便在不同网络环境下测试。\n\n'
                      '• 模拟器：10.0.2.2:8000\n'
                      '• 同一WiFi真机：192.168.x.x:8000\n'
                      '• 其他电脑：对应电脑的局域网IP:8000',
                      style: TextStyle(fontSize: 12, color: XhsTheme.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '服务器地址',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: XhsTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '例如: 192.168.31.100:8000',
                prefixIcon: const Icon(Icons.dns_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) {
                if (_isSaved) setState(() => _isSaved = false);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '当前连接: ${ApiConfig.baseUrl}',
              style: const TextStyle(fontSize: 12, color: XhsTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: XhsTheme.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restore, size: 20),
                label: const Text('恢复默认'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: XhsTheme.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}