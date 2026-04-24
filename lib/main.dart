import 'package:ai_spending_decision_assistant/screens/affordability_checker_screen.dart';
import 'package:ai_spending_decision_assistant/screens/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'screens/home_shell.dart';
import 'screens/add_expense_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home, this.enableAnalytics = true});

  static final AnalyticsService analyticsService = AnalyticsService();
  final Widget? home;
  final bool enableAnalytics;

  @override
  Widget build(BuildContext context) {
    final List<NavigatorObserver> navigatorObservers = enableAnalytics
        ? <NavigatorObserver>[analyticsService.getAnalyticsObserver()]
        : <NavigatorObserver>[];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Spending Decision Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF6F3FB),
        useMaterial3: true,
      ),
      navigatorObservers: navigatorObservers,
      home: home ?? const AiChatScreen(),
    );
  }
}
