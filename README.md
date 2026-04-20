OptiTranslate — macOS menu-bar translator

Features:
- Menu bar app that stays in the top-right corner
- Global hotkey Option(⌥)+Space: translates current selection
- Uses OpenAI API (OPENAI_API_KEY env var) for translation
- Saves translations to ~/Documents/Translations.md

Build & run:
1. Install xcodegen (if needed): brew install xcodegen
2. Generate Xcode project: cd macos/OptiTranslate && xcodegen generate
3. Open OptiTranslate.xcodeproj in Xcode and run on macOS target

Packaging to DMG:
- Use Xcode Archive then export, or use provided scripts/build-dmg.sh which calls xcodebuild archive + hdiutil (adjust scheme & signing as needed).

Notes:
- The app simulates Cmd+C to fetch selected text. If accessibility/clipboard permissions are required, approve them in System Settings.
- Provide OPENAI_API_KEY via environment or in Xcode scheme run env variables.
