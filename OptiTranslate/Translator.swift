import Foundation

enum TranslatorError: Error {
    case missingAPIKey
    case apiError(String)
    case parseError
}

struct TranslationResult {
    let meaning: String
    let example: String
}

struct Translator {
    static func translate(text: String) async throws -> TranslationResult {
        let key = UserDefaults.standard.string(forKey: "openai_api_key")
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ""
        guard !key.isEmpty else { throw TranslatorError.missingAPIKey }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        let system = """
You are a concise technical translator EN→ZH. Reply ONLY in this exact format (no extra lines):
译文: <Chinese translation of the input>
例子: <one short technical usage example in Chinese, preferably software/engineering context>
"""
        let messages: [[String: String]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": text]
        ]
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 600,
            "temperature": 0.3
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let s = String(data: data, encoding: .utf8) ?? ""
            throw TranslatorError.apiError(s)
        }

        struct Msg: Decodable { let content: String }
        struct Choice: Decodable { let message: Msg }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let raw = decoded.choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Parse "译文: ..." and "例子: ..."
        var meaning = ""
        var example = ""
        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("译文:") {
                meaning = String(line.dropFirst("译文:".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("例子:") {
                example = String(line.dropFirst("例子:".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        // Fallback: if no 译文: prefix, use full raw as meaning
        if meaning.isEmpty { meaning = raw }
        return TranslationResult(meaning: meaning, example: example)
    }
}
