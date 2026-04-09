import 'package:flutter/material.dart';
import 'theme/retro_theme.dart';
import 'screens/font_library_screen.dart';

void main() {
  runApp(const OpenGlyphApp());
}

class OpenGlyphApp extends StatelessWidget {
  const OpenGlyphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Glyph',
      debugShowCheckedModeBanner: false,
      theme: RetroTheme.darkTheme,
      home: const FontLibraryScreen(),
    );
  }
}
