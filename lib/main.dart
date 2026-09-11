import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

// ============================================================
// VIEW
// ============================================================
import 'package:equate/view/splash/splash_view.dart';

// ============================================================
// VIEWMODEL
// ============================================================
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // INITIALIZE DATE LOCALE
  // ==========================================================
  await initializeDateFormatting('id_ID', null);

  // ==========================================================
  // INITIALIZE FIREBASE
  // ==========================================================
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ==========================================================
  // RUN APP
  // ==========================================================
  runApp(
    MultiProvider(
      providers: [
        // ======================================================
        // AUTH VIEWMODEL
        // ======================================================
        ChangeNotifierProvider(create: (_) => AuthViewModel()),

        // ======================================================
        // HISTORICAL DATA VIEWMODEL
        // ======================================================
        ChangeNotifierProvider(create: (_) => HistoricalDataViewModel()),
      ],
      child: const EquateApp(),
    ),
  );
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

          // ==================================================
          // LIGHT THEME
          // ==================================================
          theme: ThemeData(
            brightness: Brightness.light,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF9800),
              brightness: Brightness.light,
            ),

            scaffoldBackgroundColor: Colors.white,

            useMaterial3: true,

            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ),
          ),

          // ==================================================
          // DARK THEME
          // ==================================================
          darkTheme: ThemeData(
            brightness: Brightness.dark,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF9800),
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

      child: const SplashView(),
    );
  }
}
