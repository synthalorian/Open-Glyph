import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/pixel_font.dart';

class FontStorage {
  static String get _basePath {
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(home, '.open-glyph', 'fonts');
  }

  static Future<void> _ensureDir() async {
    final dir = Directory(_basePath);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  static String _filePath(String id) => p.join(_basePath, '$id.json');

  static Future<void> save(PixelFont font) async {
    await _ensureDir();
    font.modifiedAt = DateTime.now();
    final json = const JsonEncoder.withIndent('  ').convert(font.toJson());
    await File(_filePath(font.id)).writeAsString(json);
  }

  static Future<PixelFont?> load(String id) async {
    try {
      final file = File(_filePath(id));
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return PixelFont.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<List<FontSummary>> listFonts() async {
    await _ensureDir();
    final dir = Directory(_basePath);
    final summaries = <FontSummary>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          summaries.add(FontSummary(
            id: json['id'] as String,
            name: json['name'] as String,
            description: json['description'] as String?,
            glyphWidth: json['glyphWidth'] as int,
            glyphHeight: json['glyphHeight'] as int,
            modifiedAt: DateTime.parse(json['modifiedAt'] as String),
          ));
        } catch (_) {}
      }
    }
    summaries.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return summaries;
  }

  static Future<void> delete(String id) async {
    final file = File(_filePath(id));
    if (await file.exists()) await file.delete();
  }
}

class FontSummary {
  final String id;
  final String name;
  final String? description;
  final int glyphWidth;
  final int glyphHeight;
  final DateTime modifiedAt;

  const FontSummary({
    required this.id,
    required this.name,
    this.description,
    required this.glyphWidth,
    required this.glyphHeight,
    required this.modifiedAt,
  });
}
