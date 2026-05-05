import 'package:flutter/material.dart';

// IMPORTS DAS SUAS TELAS
import 'telaLogin.dart';
import 'telaInicial.dart';
import 'comoJogar.dart';
import 'telaDificuldade.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dominó Química',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const TelaInicial(),
        '/howToPlay': (context) => const HowToPlayScreen(),
        '/difficulty': (context) => const TelaDificuldade(),
      },
    );
  }
}
