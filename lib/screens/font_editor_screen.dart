import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pixel_font.dart';
import '../services/font_storage.dart';
import '../theme/retro_theme.dart';
import '../widgets/glyph_editor.dart';

class FontEditorScreen extends StatefulWidget {
  final PixelFont font;

  const FontEditorScreen({super.key, required this.font});

  @override
  State<FontEditorScreen> createState() => _FontEditorScreenState();
}

class _FontEditorScreenState extends State<FontEditorScreen> {
  late PixelFont _font;
  String _selectedChar = 'A';
  late TextEditingController _previewCtl;
  int _previewScale = 3;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _font = widget.font;
    _previewCtl = TextEditingController(text: 'HELLO WORLD');
  }

  @override
  void dispose() {
    _previewCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await FontStorage.save(_font);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${_font.name}"'),
          duration: const Duration(seconds: 1),
          backgroundColor: RetroTheme.pixel.withValues(alpha: 0.8),
        ),
      );
    }
  }

  void _export() async {
    final bmf = _font.exportBMFontText();
    await Clipboard.setData(ClipboardData(text: bmf));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMFont data copied to clipboard')),
      );
    }
  }

  void _navigateChar(int delta) {
    const charset = PixelFont.defaultCharset;
    final idx = charset.indexOf(_selectedChar);
    if (idx < 0) return;
    final newIdx = (idx + delta).clamp(0, charset.length - 1);
    setState(() => _selectedChar = charset[newIdx]);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) _save();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.bracketLeft) _navigateChar(-1);
    if (event.logicalKey == LogicalKeyboardKey.bracketRight) _navigateChar(1);
  }

  @override
  Widget build(BuildContext context) {
    final glyph = _font.getOrCreate(_selectedChar);
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.text_fields, size: 20),
              const SizedBox(width: 8),
              Text(_font.name, style: const TextStyle(letterSpacing: 1)),
              const SizedBox(width: 8),
              Text('${_font.glyphWidth}x${_font.glyphHeight}',
                  style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_showSettings ? Icons.settings : Icons.settings_outlined),
              onPressed: () => setState(() => _showSettings = !_showSettings),
              tooltip: 'Font Settings',
            ),
            IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save (Ctrl+S)'),
            IconButton(icon: const Icon(Icons.file_download), onPressed: _export, tooltip: 'Export BMFont'),
          ],
        ),
        body: Row(
          children: [
            // Character map sidebar
            Container(
              width: 220,
              color: RetroTheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: RetroTheme.grid)),
                    ),
                    child: Row(
                      children: [
                        const Text('CHARACTER MAP',
                            style: TextStyle(color: RetroTheme.pixel, fontSize: 11,
                                fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const Spacer(),
                        Text('${_font.definedGlyphCount}/${PixelFont.defaultCharset.length}',
                            style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10,
                        mainAxisSpacing: 1,
                        crossAxisSpacing: 1,
                      ),
                      itemCount: PixelFont.defaultCharset.length,
                      itemBuilder: (context, index) {
                        final char = PixelFont.defaultCharset[index];
                        final isSelected = char == _selectedChar;
                        final glyphData = _font.glyphs[char];
                        final hasContent = glyphData != null && !glyphData.isEmpty;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedChar = char),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? RetroTheme.pixel.withValues(alpha: 0.2)
                                  : hasContent
                                      ? RetroTheme.surfaceLight
                                      : RetroTheme.background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                              border: isSelected
                                  ? Border.all(color: RetroTheme.pixel, width: 1)
                                  : null,
                            ),
                            child: glyphData != null && hasContent
                                ? CustomPaint(
                                    painter: _MiniGlyphPainter(glyph: glyphData),
                                  )
                                : Center(
                                    child: Text(
                                      char == ' ' ? '·' : char,
                                      style: TextStyle(
                                        color: isSelected ? RetroTheme.pixel : RetroTheme.textSecondary.withValues(alpha: 0.4),
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Nav hint
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: RetroTheme.grid)),
                    ),
                    child: const Text(
                      '[ ] to navigate glyphs',
                      style: TextStyle(color: RetroTheme.textSecondary, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: RetroTheme.grid),
            // Main editor
            Expanded(
              child: Column(
                children: [
                  // Glyph editor
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Editing: "${_selectedChar == ' ' ? 'SPACE' : _selectedChar}"',
                                style: const TextStyle(color: RetroTheme.amber, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'U+${_selectedChar.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0')}',
                                style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: GlyphEditor(
                              glyph: glyph,
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: RetroTheme.grid, height: 1),
                  // Preview
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: RetroTheme.background,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text('PREVIEW',
                                  style: TextStyle(color: RetroTheme.pixel, fontSize: 11,
                                      fontWeight: FontWeight.bold, letterSpacing: 2)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _previewCtl,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(color: RetroTheme.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: RetroTheme.surfaceLight,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Scale buttons
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: _previewScale > 1
                                    ? () => setState(() => _previewScale--)
                                    : null,
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                              Text('${_previewScale}x',
                                  style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: _previewScale < 8
                                    ? () => setState(() => _previewScale++)
                                    : null,
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: CustomPaint(
                              painter: _FontPreviewPainter(
                                font: _font,
                                text: _previewCtl.text,
                                scale: _previewScale.toDouble(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Settings panel
            if (_showSettings) ...[
              const VerticalDivider(width: 1, color: RetroTheme.grid),
              _SettingsPanel(
                font: _font,
                glyph: glyph,
                onChanged: () => setState(() {}),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniGlyphPainter extends CustomPainter {
  final GlyphData glyph;
  _MiniGlyphPainter({required this.glyph});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / glyph.width;
    final cellH = size.height / glyph.height;
    final paint = Paint()..color = RetroTheme.pixel.withValues(alpha: 0.8);

    for (int y = 0; y < glyph.height; y++) {
      for (int x = 0; x < glyph.width; x++) {
        if (glyph.getPixel(x, y)) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FontPreviewPainter extends CustomPainter {
  final PixelFont font;
  final String text;
  final double scale;

  _FontPreviewPainter({required this.font, required this.text, this.scale = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = RetroTheme.pixel;
    double cursorX = 0;
    double cursorY = 0;

    for (final char in text.split('')) {
      if (char == '\n') {
        cursorX = 0;
        cursorY += font.lineHeight * scale;
        continue;
      }
      final glyph = font.glyphs[char];
      if (glyph == null) {
        cursorX += font.glyphWidth * scale + font.spacing * scale;
        continue;
      }

      if (cursorX + glyph.width * scale > size.width) {
        cursorX = 0;
        cursorY += font.lineHeight * scale;
      }

      for (int y = 0; y < glyph.height; y++) {
        for (int x = 0; x < glyph.width; x++) {
          if (glyph.getPixel(x, y)) {
            canvas.drawRect(
              Rect.fromLTWH(
                cursorX + x * scale,
                cursorY + y * scale,
                scale - (scale > 2 ? 0.5 : 0),
                scale - (scale > 2 ? 0.5 : 0),
              ),
              paint,
            );
          }
        }
      }
      cursorX += glyph.advance * scale + font.spacing * scale;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SettingsPanel extends StatelessWidget {
  final PixelFont font;
  final GlyphData glyph;
  final VoidCallback onChanged;

  const _SettingsPanel({required this.font, required this.glyph, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: RetroTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _Label('FONT SETTINGS'),
          const SizedBox(height: 8),
          _IntField('Spacing', font.spacing, (v) { font.spacing = v; onChanged(); }),
          _IntField('Line Height', font.lineHeight, (v) { font.lineHeight = v; onChanged(); }),
          _IntField('Baseline', font.baseline, (v) { font.baseline = v; onChanged(); }),
          const SizedBox(height: 16),
          const _Label('GLYPH SETTINGS'),
          const SizedBox(height: 8),
          _IntField('Advance', glyph.advance, (v) { glyph.advance = v; onChanged(); }),
          _IntField('X Offset', glyph.xOffset, (v) { glyph.xOffset = v; onChanged(); }),
          _IntField('Y Offset', glyph.yOffset, (v) { glyph.yOffset = v; onChanged(); }),
          const SizedBox(height: 16),
          const _Label('INFO'),
          const SizedBox(height: 8),
          _InfoRow('Glyph Size', '${font.glyphWidth} x ${font.glyphHeight}'),
          const _InfoRow('Charset', '95 chars'),
          _InfoRow('Defined', '${font.definedGlyphCount} glyphs'),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: RetroTheme.pixel, fontSize: 10,
          fontWeight: FontWeight.bold, letterSpacing: 2));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label,
                style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 10))),
            Text(value, style: const TextStyle(color: RetroTheme.textPrimary, fontSize: 10)),
          ],
        ),
      );
}

class _IntField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _IntField(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label,
              style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 11))),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 12),
              onPressed: () => onChanged(value - 1),
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(color: RetroTheme.textPrimary, fontSize: 12, fontFamily: 'monospace')),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: const Icon(Icons.add, size: 12),
              onPressed: () => onChanged(value + 1),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
