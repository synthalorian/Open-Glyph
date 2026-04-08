# RetroType

Pixel art font editor — create bitmap fonts with retro templates.

## What is RetroType?

A dedicated editor for creating bitmap/pixel fonts with live preview, kerning tools, and export to common formats. Built-in templates for retro styles (C64, NES, DOS, arcade) with preview in mock game UIs.

## Features (Planned)

- **Pixel grid editor** — draw glyphs pixel-by-pixel with draw/erase tools
- **Character map** — full ASCII charset with visual glyph browser
- **Live preview** — see your font rendered in real-time as you edit
- **Retro templates** — C64, NES, DOS/VGA, arcade, tiny 5x5, wide 16x16
- **Export** — TTF/OTF, BMFont, spritesheet PNG
- **Kerning editor** — adjust spacing between character pairs
- **Game UI preview** — see your font in mock RPG dialogs, HUDs, menus

## Tech Stack

- **Flutter** (cross-platform: desktop, mobile, web)
- **Custom pixel grid canvas** for the editor
- **Dart** for font data models and export logic

## Getting Started

```bash
flutter pub get
flutter run
```

## License

MIT
