import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/pixel_font.dart';
import '../theme/retro_theme.dart';

class GlyphEditor extends StatefulWidget {
  final GlyphData glyph;
  final VoidCallback onChanged;

  const GlyphEditor({super.key, required this.glyph, required this.onChanged});

  @override
  State<GlyphEditor> createState() => _GlyphEditorState();
}

class _GlyphEditorState extends State<GlyphEditor> {
  bool _drawing = true;
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];
  Uint8List? _clipboardPixels;

  void _snapshot() {
    _undoStack.add(widget.glyph.snapshot());
    _redoStack.clear();
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(widget.glyph.snapshot());
    widget.glyph.restoreSnapshot(_undoStack.removeLast());
    widget.onChanged();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(widget.glyph.snapshot());
    widget.glyph.restoreSnapshot(_redoStack.removeLast());
    widget.onChanged();
  }

  void _doAction(void Function() action) {
    _snapshot();
    action();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tool rows
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            _ToolBtn(Icons.edit, 'Draw', _drawing, () => setState(() => _drawing = true)),
            _ToolBtn(Icons.auto_fix_off, 'Erase', !_drawing, () => setState(() => _drawing = false)),
            const _Sep(),
            _ToolBtn(Icons.undo, 'Undo', false, _undo, enabled: _undoStack.isNotEmpty),
            _ToolBtn(Icons.redo, 'Redo', false, _redo, enabled: _redoStack.isNotEmpty),
            const _Sep(),
            _ToolBtn(Icons.clear, 'Clear', false, () => _doAction(() => widget.glyph.clear())),
            _ToolBtn(Icons.square, 'Fill', false, () => _doAction(() => widget.glyph.fill())),
            _ToolBtn(Icons.invert_colors, 'Invert', false, () => _doAction(() => widget.glyph.invert())),
            const _Sep(),
            _ToolBtn(Icons.arrow_left, 'Left', false, () => _doAction(() => widget.glyph.shiftLeft())),
            _ToolBtn(Icons.arrow_right, 'Right', false, () => _doAction(() => widget.glyph.shiftRight())),
            _ToolBtn(Icons.arrow_upward, 'Up', false, () => _doAction(() => widget.glyph.shiftUp())),
            _ToolBtn(Icons.arrow_downward, 'Down', false, () => _doAction(() => widget.glyph.shiftDown())),
            const _Sep(),
            _ToolBtn(Icons.flip, 'FlipH', false, () => _doAction(() => widget.glyph.mirrorHorizontal())),
            _ToolBtn(Icons.flip_camera_android, 'FlipV', false, () => _doAction(() => widget.glyph.mirrorVertical())),
            const _Sep(),
            _ToolBtn(Icons.copy, 'Copy', false, () {
              _clipboardPixels = widget.glyph.snapshot();
            }),
            _ToolBtn(Icons.paste, 'Paste', false, () {
              if (_clipboardPixels != null) {
                _doAction(() => widget.glyph.restoreSnapshot(_clipboardPixels!));
              }
            }, enabled: _clipboardPixels != null),
          ],
        ),
        const SizedBox(height: 12),
        // Grid
        Expanded(
          child: AspectRatio(
            aspectRatio: widget.glyph.width / widget.glyph.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellW = constraints.maxWidth / widget.glyph.width;
                final cellH = constraints.maxHeight / widget.glyph.height;
                return GestureDetector(
                  onPanStart: (d) {
                    _snapshot();
                    _handleDraw(d.localPosition, cellW, cellH);
                  },
                  onPanUpdate: (d) => _handleDraw(d.localPosition, cellW, cellH),
                  onTapDown: (d) {
                    _snapshot();
                    _handleDraw(d.localPosition, cellW, cellH);
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _GlyphGridPainter(
                      glyph: widget.glyph,
                      cellWidth: cellW,
                      cellHeight: cellH,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _handleDraw(Offset pos, double cellW, double cellH) {
    final x = (pos.dx / cellW).floor();
    final y = (pos.dy / cellH).floor();
    if (x >= 0 && x < widget.glyph.width && y >= 0 && y < widget.glyph.height) {
      final current = widget.glyph.getPixel(x, y);
      if (_drawing && !current) {
        widget.glyph.setPixel(x, y, true);
        widget.onChanged();
      } else if (!_drawing && current) {
        widget.glyph.setPixel(x, y, false);
        widget.onChanged();
      }
    }
  }
}

class _GlyphGridPainter extends CustomPainter {
  final GlyphData glyph;
  final double cellWidth;
  final double cellHeight;

  _GlyphGridPainter({required this.glyph, required this.cellWidth, required this.cellHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = RetroTheme.background;
    final pixelPaint = Paint()..color = RetroTheme.pixel;
    final gridPaint = Paint()..color = RetroTheme.grid..strokeWidth = 0.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (int y = 0; y < glyph.height; y++) {
      for (int x = 0; x < glyph.width; x++) {
        if (glyph.getPixel(x, y)) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellWidth + 0.5, y * cellHeight + 0.5, cellWidth - 1, cellHeight - 1),
            pixelPaint,
          );
        }
      }
    }

    for (int x = 0; x <= glyph.width; x++) {
      canvas.drawLine(Offset(x * cellWidth, 0), Offset(x * cellWidth, size.height), gridPaint);
    }
    for (int y = 0; y <= glyph.height; y++) {
      canvas.drawLine(Offset(0, y * cellHeight), Offset(size.width, y * cellHeight), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool enabled;

  const _ToolBtn(this.icon, this.label, this.active, this.onTap, {this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? RetroTheme.textSecondary.withOpacity(0.3)
        : active
            ? RetroTheme.pixel
            : RetroTheme.textSecondary;
    return Tooltip(
      message: label,
      child: Material(
        color: active ? RetroTheme.pixel.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 2), color: RetroTheme.grid);
  }
}
