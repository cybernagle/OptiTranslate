import Foundation
import AppKit

@MainActor
final class TranslationStore: ObservableObject {
    @Published var wordInput: String = ""
    @Published var meaning: String = ""
    @Published var example: String = ""
    @Published var isTranslating = false
    @Published var savedMessage: String = ""

    func translate() async {
        let word = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }
        isTranslating = true
        meaning = ""
        example = ""
        defer { isTranslating = false }
        do {
            let result = try await Translator.translate(word: word)
            meaning = result.meaning
            example = result.example
        } catch TranslatorError.missingAPIKey {
            meaning = "⚠️ 请先在设置中填入 OpenAI API Key（点右上角 ⚙️）"
        } catch {
            meaning = "翻译失败: \(error.localizedDescription)"
        }
    }

    func save() {
        let word = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty, !meaning.isEmpty else { return }

        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let file = docs.appendingPathComponent("Translations.md")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        var entry = "\n## \(word)  `\(dateStr)`\n\n"
        entry += "**释义:** \(meaning)\n\n"
        if !example.isEmpty {
            entry += "**例句:** \(example)\n\n"
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
            let header = "# 单词本\n\n"
            fm.createFile(atPath: file.path, contents: (header + entry).data(using: .utf8))
        }

        savedMessage = "✅ 已保存"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.savedMessage = ""
        }
    }

    func clear() {
        wordInput = ""
        meaning = ""
        example = ""
        savedMessage = ""
    }
}
