import Foundation
import AppKit

/// Shared state between StatusBarController and ContentView.
@MainActor
final class TranslationStore: ObservableObject {
    @Published var original: String = ""
    @Published var translation: String = ""
    @Published var translationExample: String = ""
    @Published var isTranslating = false
    @Published var savedMessage: String = ""

    func translate() async {
        guard !original.isEmpty else { return }
        isTranslating = true
        translation = ""
        translationExample = ""
        defer { isTranslating = false }
        do {
            let result = try await Translator.translate(text: original)
            translation = result.meaning
            translationExample = result.example
        } catch TranslatorError.missingAPIKey {
            translation = "⚠️ 请先在设置中填入 OpenAI API Key"
        } catch {
            translation = "翻译失败: \(error.localizedDescription)"
        }
    }

    func save() {
        guard !original.isEmpty, !translation.isEmpty else { return }
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let file = docs.appendingPathComponent("Translations.md")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        var entry = "\n## \(dateStr)\n\n"
        entry += "**原文:** \(original)\n\n"
        entry += "**中文:** \(translation)\n\n"
        if !translationExample.isEmpty {
            entry += "**例子:** \(translationExample)\n\n"
        }
        entry += "---\n"

        guard let data = entry.data(using: .utf8) else { return }
        if fm.fileExists(atPath: file.path) {
            if let handle = try? FileHandle(forWritingTo: file) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            let header = "# Translations\n\n"
            fm.createFile(atPath: file.path, contents: (header + entry).data(using: .utf8))
        }
        savedMessage = "✅ 已保存到 Translations.md"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.savedMessage = ""
        }
    }
}
