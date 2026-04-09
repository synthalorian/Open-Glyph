import 'package:flutter/material.dart';
import '../models/pixel_font.dart';
import '../services/font_storage.dart';
import '../theme/retro_theme.dart';
import 'font_editor_screen.dart';

class FontLibraryScreen extends StatefulWidget {
  const FontLibraryScreen({super.key});

  @override
  State<FontLibraryScreen> createState() => _FontLibraryScreenState();
}

class _FontLibraryScreenState extends State<FontLibraryScreen> {
  List<FontSummary>? _fonts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    setState(() => _loading = true);
    final fonts = await FontStorage.listFonts();
    if (mounted) setState(() { _fonts = fonts; _loading = false; });
  }

  Future<void> _createNew() async {
    final result = await showDialog<_CreateResult>(
      context: context,
      builder: (_) => const _CreateFontDialog(),
    );
    if (result == null) return;

    final font = PixelFont.fromTemplate(
      DateTime.now().millisecondsSinceEpoch.toString(),
      result.name,
      result.template,
    );
    await FontStorage.save(font);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FontEditorScreen(font: font)),
      );
      _loadFonts();
    }
  }

  Future<void> _openFont(String id) async {
    final font = await FontStorage.load(id);
    if (font != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FontEditorScreen(font: font)),
      );
      _loadFonts();
    }
  }

  Future<void> _deleteFont(FontSummary s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        title: const Text('Delete Font', style: TextStyle(color: RetroTheme.amber)),
        content: Text('Delete "${s.name}"?', style: const TextStyle(color: RetroTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FontStorage.delete(s.id);
      _loadFonts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.text_fields, color: RetroTheme.pixel, size: 28),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OPEN GLYPH',
                        style: TextStyle(color: RetroTheme.pixel, fontSize: 22,
                            fontWeight: FontWeight.bold, letterSpacing: 4)),
                    Text('Pixel Art Font Editor',
                        style: TextStyle(color: RetroTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _createNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Font'),
                  style: FilledButton.styleFrom(
                    backgroundColor: RetroTheme.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: RetroTheme.grid, height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: RetroTheme.pixel))
                : (_fonts == null || _fonts!.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.font_download, size: 72, color: RetroTheme.pixel.withValues(alpha: 0.3)),
                            const SizedBox(height: 20),
                            const Text('No fonts yet', style: TextStyle(color: RetroTheme.textSecondary, fontSize: 20)),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _createNew,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Font'),
                              style: FilledButton.styleFrom(backgroundColor: RetroTheme.amber, foregroundColor: Colors.black),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 130,
                        ),
                        itemCount: _fonts!.length,
                        itemBuilder: (_, i) {
                          final f = _fonts![i];
                          return _FontCard(
                            summary: f,
                            onTap: () => _openFont(f.id),
                            onDelete: () => _deleteFont(f),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  final FontSummary summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FontCard({required this.summary, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RetroTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RetroTheme.grid),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.font_download, color: RetroTheme.pixel, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(summary.name,
                        style: const TextStyle(color: RetroTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, size: 16, color: RetroTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _Chip('${summary.glyphWidth}x${summary.glyphHeight}', RetroTheme.pixel),
                ],
              ),
              const SizedBox(height: 4),
              Text(_relativeDate(summary.modifiedAt),
                  style: const TextStyle(color: RetroTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

class _CreateResult {
  final String name;
  final FontTemplate template;
  const _CreateResult(this.name, this.template);
}

class _CreateFontDialog extends StatefulWidget {
  const _CreateFontDialog();

  @override
  State<_CreateFontDialog> createState() => _CreateFontDialogState();
}

class _CreateFontDialogState extends State<_CreateFontDialog> {
  final _nameCtl = TextEditingController(text: 'My Font');
  FontTemplate _template = FontTemplate.c64;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: RetroTheme.surface,
      title: const Text('New Font', style: TextStyle(color: RetroTheme.pixel)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtl,
            autofocus: true,
            style: const TextStyle(color: RetroTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Font Name',
              labelStyle: TextStyle(color: RetroTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Template', style: TextStyle(color: RetroTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: FontTemplate.values.map((t) {
              final selected = t == _template;
              return ChoiceChip(
                label: Text('${t.label} (${t.defaultWidth}x${t.defaultHeight})'),
                selected: selected,
                onSelected: (_) => setState(() => _template = t),
                selectedColor: RetroTheme.pixel.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? RetroTheme.pixel : RetroTheme.textPrimary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_nameCtl.text.isNotEmpty) {
              Navigator.pop(context, _CreateResult(_nameCtl.text, _template));
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
