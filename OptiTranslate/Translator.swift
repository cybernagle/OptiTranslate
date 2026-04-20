import Foundation

enum TranslatorError: Error {
    case missingAPIKey
    case apiError(String)
}

struct Translator {
    static func translateToChinese(text: String) async throws -> String {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            throw TranslatorError.missingAPIKey
        }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let system = "You are a concise technical translator. Translate the user's text into fluent Chinese and include a short technical example if appropriate. Return only the translation text."
        let messages: [[String: String]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": "Translate to Chinese:\n\(text)"]
        ]
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 800
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let s = String(data: data, encoding: .utf8) ?? ""
            throw TranslatorError.apiError(s)
        }
        struct Choice: Decodable { struct Msg: Decodable { let content: String }; let message: Msg }
        struct Resp: Decodable { let choices: [Choice] }
        let dec = try JSONDecoder().decode(Resp.self, from: data)
        return dec.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
