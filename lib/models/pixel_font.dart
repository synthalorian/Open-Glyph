import 'dart:convert';
import 'dart:typed_data';

class GlyphData {
  final String character;
  final int width;
  final int height;
  final Uint8List pixels;
  int advance;
  int xOffset;
  int yOffset;

  GlyphData({
    required this.character,
    required this.width,
    required this.height,
    Uint8List? pixels,
    this.advance = 0,
    this.xOffset = 0,
    this.yOffset = 0,
  }) : pixels = pixels ?? Uint8List(width * height) {
    if (advance == 0) advance = width + 1;
  }

  bool getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return pixels[y * width + x] == 1;
  }

  void setPixel(int x, int y, bool value) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    pixels[y * width + x] = value ? 1 : 0;
  }

  void togglePixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    pixels[y * width + x] = pixels[y * width + x] == 1 ? 0 : 1;
  }

  void clear() => pixels.fillRange(0, pixels.length, 0);

  void fill() => pixels.fillRange(0, pixels.length, 1);

  void invert() {
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = pixels[i] == 1 ? 0 : 1;
    }
  }

  void shiftLeft() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width - 1; x++) {
        pixels[y * width + x] = pixels[y * width + x + 1];
      }
      pixels[y * width + width - 1] = 0;
    }
  }

  void shiftRight() {
    for (int y = 0; y < height; y++) {
      for (int x = width - 1; x > 0; x--) {
        pixels[y * width + x] = pixels[y * width + x - 1];
      }
      pixels[y * width] = 0;
    }
  }

  void shiftUp() {
    for (int y = 0; y < height - 1; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = pixels[(y + 1) * width + x];
      }
    }
    for (int x = 0; x < width; x++) {
      pixels[(height - 1) * width + x] = 0;
    }
  }

  void shiftDown() {
    for (int y = height - 1; y > 0; y--) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = pixels[(y - 1) * width + x];
      }
    }
    for (int x = 0; x < width; x++) {
      pixels[x] = 0;
    }
  }

  void mirrorHorizontal() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final temp = pixels[y * width + x];
        pixels[y * width + x] = pixels[y * width + (width - 1 - x)];
        pixels[y * width + (width - 1 - x)] = temp;
      }
    }
  }

  void mirrorVertical() {
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width; x++) {
        final temp = pixels[y * width + x];
        pixels[y * width + x] = pixels[(height - 1 - y) * width + x];
        pixels[(height - 1 - y) * width + x] = temp;
      }
    }
  }

  bool get isEmpty => pixels.every((p) => p == 0);

  GlyphData copy() => GlyphData(
        character: character,
        width: width,
        height: height,
        pixels: Uint8List.fromList(pixels),
        advance: advance,
        xOffset: xOffset,
        yOffset: yOffset,
      );

  /// Snapshot pixels for undo
  Uint8List snapshot() => Uint8List.fromList(pixels);

  void restoreSnapshot(Uint8List snap) {
    for (int i = 0; i < pixels.length && i < snap.length; i++) {
      pixels[i] = snap[i];
    }
  }

  Map<String, dynamic> toJson() => {
        'char': character,
        'w': width,
        'h': height,
        'adv': advance,
        'xOff': xOffset,
        'yOff': yOffset,
        'px': base64Encode(pixels),
      };

  factory GlyphData.fromJson(Map<String, dynamic> json) {
    final px = base64Decode(json['px'] as String);
    return GlyphData(
      character: json['char'] as String,
      width: json['w'] as int,
      height: json['h'] as int,
      pixels: Uint8List.fromList(px),
      advance: json['adv'] as int? ?? 0,
      xOffset: json['xOff'] as int? ?? 0,
      yOffset: json['yOff'] as int? ?? 0,
    );
  }
}

enum FontTemplate {
  blank('Blank', 8, 8),
  c64('C64 Style', 8, 8),
  nes('NES Style', 8, 8),
  dos('DOS/VGA Style', 8, 16),
  arcade('Arcade Style', 8, 8),
  tiny('Tiny 5x5', 5, 5),
  wide('Wide 16x16', 16, 16);

  final String label;
  final int defaultWidth;
  final int defaultHeight;
  const FontTemplate(this.label, this.defaultWidth, this.defaultHeight);
}

class PixelFont {
  final String id;
  String name;
  String? description;
  final int glyphWidth;
  final int glyphHeight;
  int lineHeight;
  int baseline;
  int spacing;
  final Map<String, GlyphData> glyphs;
  final DateTime createdAt;
  DateTime modifiedAt;

  PixelFont({
    required this.id,
    required this.name,
    this.description,
    required this.glyphWidth,
    required this.glyphHeight,
    int? lineHeight,
    int? baseline,
    this.spacing = 1,
    Map<String, GlyphData>? glyphs,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : lineHeight = lineHeight ?? glyphHeight + 2,
        baseline = baseline ?? glyphHeight,
        glyphs = glyphs ?? {},
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  static const String defaultCharset =
      ' !"#\$%&\'()*+,-./0123456789:;<=>?@'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`'
      'abcdefghijklmnopqrstuvwxyz{|}~';

  void initializeBlank() {
    for (final char in defaultCharset.split('')) {
      glyphs[char] = GlyphData(
        character: char,
        width: glyphWidth,
        height: glyphHeight,
      );
    }
  }

  GlyphData getOrCreate(String char) {
    return glyphs.putIfAbsent(
      char,
      () => GlyphData(character: char, width: glyphWidth, height: glyphHeight),
    );
  }

  int get definedGlyphCount => glyphs.values.where((g) => !g.isEmpty).length;

  static PixelFont fromTemplate(String id, String name, FontTemplate template) {
    final font = PixelFont(
      id: id,
      name: name,
      glyphWidth: template.defaultWidth,
      glyphHeight: template.defaultHeight,
    );
    font.initializeBlank();
    return font;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'glyphWidth': glyphWidth,
        'glyphHeight': glyphHeight,
        'lineHeight': lineHeight,
        'baseline': baseline,
        'spacing': spacing,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'glyphs': glyphs.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory PixelFont.fromJson(Map<String, dynamic> json) {
    final font = PixelFont(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      glyphWidth: json['glyphWidth'] as int,
      glyphHeight: json['glyphHeight'] as int,
      lineHeight: json['lineHeight'] as int?,
      baseline: json['baseline'] as int?,
      spacing: json['spacing'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
    final glyphsMap = json['glyphs'] as Map<String, dynamic>? ?? {};
    for (final entry in glyphsMap.entries) {
      font.glyphs[entry.key] =
          GlyphData.fromJson(entry.value as Map<String, dynamic>);
    }
    return font;
  }

  /// Export as BMFont-compatible text format
  String exportBMFontText() {
    final buf = StringBuffer();
    buf.writeln('info face="$name" size=$glyphHeight bold=0 italic=0');
    buf.writeln('common lineHeight=$lineHeight base=$baseline scaleW=${glyphWidth * 16} scaleH=${glyphHeight * 8}');
    buf.writeln('page id=0 file="${name}_0.png"');
    buf.writeln('chars count=${glyphs.length}');
    for (final entry in glyphs.entries) {
      final g = entry.value;
      final code = entry.key.codeUnitAt(0);
      buf.writeln('char id=$code x=0 y=0 width=${g.width} height=${g.height} xoffset=${g.xOffset} yoffset=${g.yOffset} xadvance=${g.advance} page=0 chnl=15');
    }
    return buf.toString();
  }
}
