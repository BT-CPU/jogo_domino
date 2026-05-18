import 'package:flutter/material.dart';
import 'telaLogin.dart';

void main() {
  runApp(const DominoQuimicaApp());
}

class DominoQuimicaApp extends StatelessWidget {
  const DominoQuimicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Domino Quimica',
      theme: ThemeData(
        primaryColor: const Color(0xFFC0392B), // Nosso vermelho padrão
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC0392B),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}