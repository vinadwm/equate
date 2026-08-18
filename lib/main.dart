import 'package:flutter/material.dart';
import 'package:equate/view/splash/splash_view.dart'; // atau 'view/splash/splash_view.dart'

void main() {
  runApp(const EquateApp());
}

class EquateApp extends StatelessWidget {
  const EquateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const SplashView(), // Poin masuk pertama aplikasi
    );
  }
}