


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'config/app_config.dart';
import 'webview/webview_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF034F2A),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF034F2A),
      systemNavigationBarDividerColor: Color(0xFF034F2A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DashenStockistApp());
}

class DashenStockistApp extends StatelessWidget {
  const DashenStockistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9EC24F),
          surface: Color(0xFF034F2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF034F2A),
        canvasColor: const Color(0xFF034F2A),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}
