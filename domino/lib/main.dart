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
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}
