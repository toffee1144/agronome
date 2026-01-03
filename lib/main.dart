import 'package:flutter/material.dart';
import 'app_shell.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agronome',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
      ),
      home: const AppShell(),
    );
  }
}
