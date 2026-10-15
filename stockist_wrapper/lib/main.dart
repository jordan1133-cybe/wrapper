import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockist_wrapper/firebase_msg.dart';


import 'config/app_config.dart';
import 'firebase_options.dart';
import 'webview/webview_screen.dart';

Future<void> main() async {
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

  await _initFirebase();
 // await FirebaseMsg().initFCM();

  runApp(const DashenStockistApp());
   PushService.instance.init();
}


Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('[firebase] initialized: ${Firebase.apps.length} app(s)');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[firebase] init failed: $error');
    }
  }
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