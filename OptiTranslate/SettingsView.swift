import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title2).bold()

            VStack(alignment: .leading, spacing: 6) {
                Text("OpenAI API Key")
                    .font(.headline)
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                Text("Key 保存在本地 UserDefaults，不会上传。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("保存") {
                    UserDefaults.standard.set(apiKey.trimmingCharacters(in: .whitespaces),
                                              forKey: "openai_api_key")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
