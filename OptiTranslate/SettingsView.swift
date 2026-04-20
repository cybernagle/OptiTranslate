import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var apiURL: String = UserDefaults.standard.string(forKey: "openai_api_url")
        ?? "https://api.openai.com/v1/chat/completions"
    @State private var model: String = UserDefaults.standard.string(forKey: "openai_model")
        ?? "gpt-4o-mini"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title2).bold()

            VStack(alignment: .leading, spacing: 6) {
                Text("API URL").font(.caption).foregroundColor(.secondary)
                TextField("https://api.openai.com/v1/chat/completions", text: $apiURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text("支持 OpenAI 兼容的第三方服务（如 Azure、本地 Ollama 等）").font(.caption).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("API Key").font(.caption).foregroundColor(.secondary)
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Model").font(.caption).foregroundColor(.secondary)
                TextField("gpt-4o-mini", text: $model)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Divider()

            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("保存") {
                    let url = apiURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    let mdl = model.trimmingCharacters(in: .whitespacesAndNewlines)
                    UserDefaults.standard.set(url.isEmpty ? "https://api.openai.com/v1/chat/completions" : url,
                                              forKey: "openai_api_url")
                    UserDefaults.standard.set(key, forKey: "openai_api_key")
                    UserDefaults.standard.set(mdl.isEmpty ? "gpt-4o-mini" : mdl,
                                              forKey: "openai_model")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
