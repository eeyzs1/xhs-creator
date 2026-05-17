import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/post_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/xhs_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const XhsCreatorApp());
}

class XhsCreatorApp extends StatelessWidget {
  const XhsCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: MaterialApp(
        title: '小红书创作助手',
        debugShowCheckedModeBanner: false,
        theme: XhsTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
