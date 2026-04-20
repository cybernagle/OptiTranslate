import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TranslationStore
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header
            HStack {
                Image(systemName: "character.book.closed")
                    .foregroundColor(.accentColor)
                Text("OptiTranslate")
                    .font(.headline)
                Spacer()
                if !store.savedMessage.isEmpty {
                    Text(store.savedMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings — set OpenAI API Key")
            }

            Divider()

            // Input field
            HStack(spacing: 6) {
                TextField("输入单词或短语…", text: $store.wordInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .focused($inputFocused)
                    .onSubmit { Task { await store.translate() } }

                if !store.wordInput.isEmpty {
                    Button { store.clear() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { Task { await store.translate() } }) {
                    if store.isTranslating {
                        ProgressView().scaleEffect(0.7).frame(width: 20, height: 20)
                    } else {
                        Text("查")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.wordInput.trimmingCharacters(in: .whitespaces).isEmpty || store.isTranslating)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)

            // Meaning
            if !store.meaning.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("释义", systemImage: "textformat.abc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(store.meaning)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Example sentence
            if !store.example.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("例句", systemImage: "quote.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(store.example)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(6)
            }

            // Save button (only shown when there's a result)
            if !store.meaning.isEmpty {
                HStack {
                    Spacer()
                    Button("保存到 Translations.md") { store.save() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .frame(width: 380)
        .onAppear { inputFocused = true }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }
}
