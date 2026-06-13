# Open Glyph

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.4%2B-blue?logo=flutter" alt="Flutter 3.4+">
  <img src="https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart" alt="Dart 3.4+">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License MIT">
  <img src="https://img.shields.io/badge/Platforms-Linux%20%7C%20Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Web%20%7C%20Windows-lightgrey" alt="Platforms">
</p>

**Open Glyph** is a cross-platform pixel art font editor built with Flutter. It lets you design bitmap fonts glyph-by-glyph using a retro-styled grid editor, complete with undo/redo, live preview, and BMFont text export.

Whether you're crafting a C64-style title screen, an NES HUD font, or a tiny 5×5 micro typeface, Open Glyph gives you the tools to draw, tune, and export your pixel-perfect creations.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Pixel Grid Editor** | Draw and erase pixels on a per-glyph canvas with smooth pan-drag support |
| **Character Map** | Visual browser for the full 95-character ASCII set with at-a-glance completion status |
| **Live Preview** | Real-time text preview with adjustable scale (1×–8×) |
| **Retro Templates** | One-click presets: C64, NES, DOS/VGA, Arcade, Tiny 5×5, Wide 16×16 |
| **Glyph Tools** | Shift, mirror (H/V), invert, fill, clear, copy, and paste |
| **Undo / Redo** | 30-step history stack per editing session |
| **Font Settings** | Spacing, line height, baseline, per-glyph advance and x/y offset |
| **BMFont Export** | Copy BMFont-compatible text descriptor to clipboard |
| **Keyboard Shortcuts** | `Ctrl+S` to save, `[` / `]` to navigate glyphs |
| **Local Persistence** | Fonts auto-saved to `~/.open-glyph/fonts/` as JSON |

---

## 🖼️ Screenshots

> *Screenshots coming soon — the app is fully functional and ready for capture.*

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.4 or newer
- A supported platform toolchain (Linux, Android, iOS, macOS, Windows, or Web)

### Install & Run

```bash
# Clone the repository
git clone https://github.com/synthalorian/open-glyph.git
cd open-glyph

# Fetch dependencies
flutter pub get

# Run on your default platform
flutter run

# Or build a release bundle
flutter build linux      # Linux
flutter build android    # Android APK
flutter build windows    # Windows
flutter build macos      # macOS
flutter build ios        # iOS
flutter build web        # Web
```

---

## 🧪 Testing

```bash
flutter test
```

All model and logic tests live in `test/widget_test.dart` and cover:

- Glyph pixel operations (get, set, toggle)
- Shift, mirror, invert transforms
- JSON serialization round-trips
- Snapshot / restore (undo stack backing)

---

## 🏗️ Architecture

```
lib/
├── main.dart                     # App entry point & theme setup
├── models/
│   └── pixel_font.dart           # GlyphData, PixelFont, FontTemplate
├── services/
│   └── font_storage.dart         # Local JSON persistence (~/.open-glyph/fonts/)
├── theme/
│   └── retro_theme.dart          # Dark retro color palette & Material 3 theme
├── screens/
│   ├── font_library_screen.dart  # Font list, create, delete
│   └── font_editor_screen.dart   # Glyph editor, preview, settings panel
└── widgets/
    └── glyph_editor.dart         # Interactive pixel grid with tool bar
```

### Key Design Decisions

- **CustomPainter** for the pixel grid and preview — gives us exact pixel control and avoids widget overhead at high grid resolutions.
- **Uint8List** pixel backing — compact, fast, and serializes cleanly via Base64.
- **Stateful undo stack** inside `GlyphEditor` — keeps history local to the editing session without bloating the model.
- **BMFont text export** — industry-standard descriptor format, easy to extend to image atlases later.

---

## 🎮 Usage Tips

1. **Create a font** from the library screen — pick a template that matches your target resolution.
2. **Select a character** in the left sidebar or press `[` / `]` to cycle.
3. **Draw** with the pen tool (or tap-drag), **erase** with the cross tool.
4. **Use transforms** (shift, mirror, invert) to speed up symmetrical glyphs.
5. **Adjust per-glyph metrics** (advance, x/y offset) in the right settings panel for tight kerning.
6. **Preview** your font in the bottom panel — type any string to see it rendered.
7. **Export** BMFont data when you're ready to drop it into a game engine or renderer.

---

## 🛣️ Roadmap

- [ ] Image atlas export (PNG sprite sheet + BMFont descriptor)
- [ ] Import from existing BMFont / TTF / PNG sprite sheets
- [ ] Unicode / extended Latin / CJK support
- [ ] Kerning pair editor
- [ ] Web drag-and-drop font loading
- [ ] Git-friendly plain-text pixel format (e.g., `.ogf` text files)

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request on GitHub. When contributing:

1. Follow the existing code style (Dart formatter + `flutter_lints`).
2. Add tests for new model or service logic.
3. Keep UI widgets stateless where possible; lift state to screens.

---

## 📄 License

MIT © [synth](https://github.com/synthalorian) (synthalorian)

---

## 🙏 Credits

Developed by **synth** ([synthalorian](https://github.com/synthalorian)) with assistance from **synthshark** 🎹🦈 — a digital entity from the neon grid of 1984.

*This is the wave. 🎹🦈🌆*
