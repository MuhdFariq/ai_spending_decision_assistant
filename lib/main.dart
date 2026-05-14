import 'package:ai_spending_decision_assistant/screens/affordability_checker_screen.dart';
import 'package:ai_spending_decision_assistant/screens/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/add_expense_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home, this.enableAnalytics = true});

  final Widget? home;
  final bool enableAnalytics;

  @override
  Widget build(BuildContext context) {
    // Define our Midnight Gold Palette
    const Color goldPrimary = Color(0xFFFFD700);
    const Color midnightBlack = Color(0xFF121212);
    const Color charcoalGrey = Color(0xFF1E1E1E);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stratatouille',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // This tells Flutter to use light text
        
        // Background Colors
        scaffoldBackgroundColor: midnightBlack,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldPrimary,
          brightness: Brightness.dark,
          primary: goldPrimary,
          surface: charcoalGrey,
          onSurface: Colors.white,
        ),

        // Styling the AppBar globally
        appBarTheme: const AppBarTheme(
          backgroundColor: midnightBlack,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
          iconTheme: IconThemeData(color: goldPrimary),
        ),

        // Styling Cards globally (used in your History list)
        cardTheme: CardThemeData(
          color: charcoalGrey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: goldPrimary.withOpacity(0.1)),
          ),
        ),

        // Making buttons look premium by default
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldPrimary,
            foregroundColor: midnightBlack,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: home ?? const HomeShell(),
    );
  }
}