import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PastelShopApp());
}

class PastelShopApp extends StatelessWidget {
  const PastelShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastel Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F8FE), // Latar pastel biru
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F86C6), // Warna aksen biru tegas
          surface: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}