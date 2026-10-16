import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'config/dashen_colors.dart';
import 'webview/webview_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: DashenColors.surface,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DashenColors.surface,
      systemNavigationBarDividerColor: DashenColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DashenSalesRepApp());
}

class DashenSalesRepApp extends StatelessWidget {
  const DashenSalesRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: DashenColors.lime,
          secondary: DashenColors.highlight,
          surface: DashenColors.surface,
        ),
        scaffoldBackgroundColor: DashenColors.surface,
        canvasColor: DashenColors.surface,
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}
