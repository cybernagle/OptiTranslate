import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ContentViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OptiTranslate")
                .font(.headline)
            HStack {
                Text("原文:")
                Spacer()
            }
            ScrollView {
                Text(vm.original)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
            }
            HStack { Text("译文:") ; Spacer() }
            ScrollView {
                Text(vm.translation)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
            }
            HStack {
                Button(vm.isTranslating ? "Translating..." : "Translate") {
                    Task { await vm.translate() }
                }
                .disabled(vm.isTranslating || vm.original.isEmpty)

                Spacer()
                Button("Save") { vm.save() }
            }
        }
        .padding()
        .frame(width: 400, height: 240)
    }

    // Allow external controller to programmatically start
    func startTranslation(text: String) {
        vm.original = text
        Task { await vm.translate() }
    }
}

class ContentViewModel: ObservableObject {
    @Published var original: String = ""
    @Published var translation: String = ""
    @Published var isTranslating = false
    @Published var lastSavedURL: URL?

    func translate() async {
        guard !original.isEmpty else { return }
        isTranslating = true
        defer { isTranslating = false }
        do {
            let tr = try await Translator.translateToChinese(text: original)
            DispatchQueue.main.async {
                self.translation = tr
            }
        } catch {
            DispatchQueue.main.async {
                self.translation = "翻译失败: \(error.localizedDescription)"
            }
        }
    }

    func save() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let file = docs.appendingPathComponent("Translations.md")
        let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let entry = "\n\n\(dateStr)\n原文:\n\(original)\n\n译文:\n\(translation)\n"
        if let data = entry.data(using: .utf8) {
            if fm.fileExists(atPath: file.path) {
                if let handle = try? FileHandle(forWritingTo: file) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                    lastSavedURL = file
                }
            } else {
                fm.createFile(atPath: file.path, contents: data)
                lastSavedURL = file
            }
        }
    }
}
