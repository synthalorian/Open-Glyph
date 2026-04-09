import 'package:flutter_test/flutter_test.dart';
import 'package:open_glyph/models/pixel_font.dart';

void main() {
  test('GlyphData pixel operations', () {
    final glyph = GlyphData(character: 'A', width: 4, height: 4);
    expect(glyph.getPixel(0, 0), false);
    glyph.setPixel(0, 0, true);
    expect(glyph.getPixel(0, 0), true);
    glyph.togglePixel(0, 0);
    expect(glyph.getPixel(0, 0), false);
  });

  test('GlyphData shift operations', () {
    final glyph = GlyphData(character: 'X', width: 4, height: 4);
    glyph.setPixel(0, 0, true);
    glyph.shiftRight();
    expect(glyph.getPixel(0, 0), false);
    expect(glyph.getPixel(1, 0), true);
  });

  test('GlyphData invert', () {
    final glyph = GlyphData(character: 'X', width: 2, height: 2);
    glyph.invert();
    expect(glyph.getPixel(0, 0), true);
    expect(glyph.getPixel(1, 1), true);
  });

  test('GlyphData JSON roundtrip', () {
    final glyph = GlyphData(character: 'B', width: 8, height: 8);
    glyph.setPixel(3, 4, true);
    final json = glyph.toJson();
    final restored = GlyphData.fromJson(json);
    expect(restored.character, 'B');
    expect(restored.getPixel(3, 4), true);
    expect(restored.getPixel(0, 0), false);
  });

  test('PixelFont JSON roundtrip', () {
    final font = PixelFont.fromTemplate('1', 'Test', FontTemplate.c64);
    font.glyphs['A']!.setPixel(2, 3, true);
    final json = font.toJson();
    final restored = PixelFont.fromJson(json);
    expect(restored.name, 'Test');
    expect(restored.glyphWidth, 8);
    expect(restored.glyphs['A']!.getPixel(2, 3), true);
  });

  test('PixelFont snapshot/restore', () {
    final glyph = GlyphData(character: 'C', width: 4, height: 4);
    glyph.setPixel(1, 1, true);
    final snap = glyph.snapshot();
    glyph.clear();
    expect(glyph.getPixel(1, 1), false);
    glyph.restoreSnapshot(snap);
    expect(glyph.getPixel(1, 1), true);
  });
}
