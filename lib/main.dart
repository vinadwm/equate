import 'package:flutter/material.dart';
import 'package:equate/view/splash/splash_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const EquateApp());
}

class EquateApp extends StatelessWidget {
  const EquateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Equate',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,

          // Theme Light
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ),
          ),

          // Theme Dark
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),

          home: child,
        );
      },

      // SplashView tidak di-rebuild ulang ketika tema berubah
      child: const SplashView(),
    );
  }
}
