import 'package:flutter/material.dart';
import 'theme/retro_theme.dart';
import 'screens/font_library_screen.dart';

void main() {
  runApp(const RetroTypeApp());
}

class RetroTypeApp extends StatelessWidget {
  const RetroTypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroType',
      debugShowCheckedModeBanner: false,
      theme: RetroTheme.darkTheme,
      home: const FontLibraryScreen(),
    );
  }
}
