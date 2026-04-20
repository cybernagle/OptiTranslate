import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TranslationStore
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title bar
            HStack {
                Text("OptiTranslate")
                    .font(.headline)
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }

            Divider()

            // Original text
            Group {
                Text("原文").font(.caption).foregroundColor(.secondary)
                ScrollView {
                    Text(store.original.isEmpty ? "选中文字后按 ⌥Space…" : store.original)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(store.original.isEmpty ? .secondary : .primary)
                        .padding(5)
                }
                .frame(height: 60)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
            }

            // Chinese translation
            Group {
                Text("译文").font(.caption).foregroundColor(.secondary)
                ScrollView {
                    Text(store.isTranslating ? "翻译中…" : (store.translation.isEmpty ? " " : store.translation))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(store.isTranslating ? .secondary : .primary)
                        .padding(5)
                }
                .frame(height: 60)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
            }

            // Tech example
            if !store.translationExample.isEmpty {
                Group {
                    Text("例子").font(.caption).foregroundColor(.secondary)
                    Text(store.translationExample)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
            }

            Divider()

            // Action buttons
            HStack {
                if !store.savedMessage.isEmpty {
                    Text(store.savedMessage).font(.caption).foregroundColor(.green)
                }
                Spacer()
                Button(store.isTranslating ? "翻译中…" : "翻译") {
                    Task { await store.translate() }
                }
                .disabled(store.isTranslating || store.original.isEmpty)

                Button("保存") { store.save() }
                    .disabled(store.translation.isEmpty)
            }
        }
        .padding(12)
        .frame(width: 420)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
