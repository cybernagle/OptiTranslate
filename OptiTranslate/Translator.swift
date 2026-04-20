import Foundation

enum TranslatorError: Error {
    case missingAPIKey
    case apiError(String)
}

struct TranslationResult {
    let meaning: String
    let example: String
}

extension String {
    func trimmingTrailingSlash() -> String {
        if self.hasSuffix("/") { return String(self.dropLast()) }
        return self
    }
}

struct Translator {
    /// Build a compatible OpenAI-style chat completions URL for some providers.
    /// If the user supplies the generic BigModel PaaS root (e.g. https://open.bigmodel.cn/api/paas/v4)
    /// this returns the OpenAI-compatible path used by BigModel: /openai/v1/chat/completions
    private static func normalizeAPIURL(_ rawURL: String) -> URL? {
        var s = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        // If it looks like BigModel PaaS base, append OpenAI-compatible suffix when missing
        if s.contains("open.bigmodel.cn") && !s.contains("/openai/") {
            s = s.trimmingTrailingSlash() + "/openai/v1/chat/completions"
        }
        return URL(string: s)
    }

    static func translate(word: String) async throws -> TranslationResult {
        let key = UserDefaults.standard.string(forKey: "openai_api_key")
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ""
        guard !key.isEmpty else { throw TranslatorError.missingAPIKey }

        let rawURL = UserDefaults.standard.string(forKey: "openai_api_url")
            ?? "https://api.openai.com/v1/chat/completions"
        let model = UserDefaults.standard.string(forKey: "openai_model")
            ?? "gpt-4o-mini"

        guard let url = normalizeAPIURL(rawURL) else {
            throw TranslatorError.apiError("Invalid API URL: \(rawURL)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        let system = """
You are a concise technical dictionary EN→ZH. The user gives a word or phrase.
Reply ONLY in this exact format (two lines, no extra text):
释义: <concise Chinese meaning, include the part-of-speech tag e.g. [n.] [v.] [adj.]>
例句: <one vivid, slightly exaggerated English sentence showing the word in a software/engineering context, followed by its Chinese translation in parentheses>
"""
        // Build OpenAI-compatible body
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": word]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw TranslatorError.apiError(String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)")
        }

        struct Msg: Decodable { let content: String }
        struct Choice: Decodable { let message: Msg }
        struct Resp: Decodable { let choices: [Choice] }

        let raw = (try? JSONDecoder().decode(Resp.self, from: data))?
            .choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var meaning = ""
        var example = ""
        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("释义:") {
                meaning = String(line.dropFirst("释义:".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("例句:") {
                example = String(line.dropFirst("例句:".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        if meaning.isEmpty { meaning = raw }
        return TranslationResult(meaning: meaning, example: example)
    }
}
