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
    /// Try multiple URL variants and authentication header names to maximize compatibility
    /// with OpenAI-compatible endpoints and BigModel PaaS.
    private static func urlCandidates(from rawURL: String) -> [URL] {
        var s = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return [] }
        var candidates: [String] = []
        // 1) as provided
        candidates.append(s)
        // 2) if contains /paas/v4 and not already chat/completions, try appending /chat/completions
        if s.contains("/paas/v4") && !s.contains("/chat/completions") {
            candidates.append(s.trimmingTrailingSlash() + "/chat/completions")
        }
        // 3) BigModel OpenAI-compatible path
        if s.contains("open.bigmodel.cn") && !s.contains("/openai/") {
            candidates.append(s.trimmingTrailingSlash() + "/openai/v1/chat/completions")
        }
        // 4) OpenAI default if user provided just a host
        if !s.hasPrefix("http") {
            candidates.append("https://\(s)/v1/chat/completions")
        }
        return candidates.compactMap { URL(string: $0) }
    }

    private static let authHeaderCandidates = [
        { (key: String) in ("Authorization", "Bearer \(key)") },
        { (key: String) in ("X-API-KEY", key) },
        { (key: String) in ("Api-Key", key) },
        { (key: String) in ("x-api-key", key) }
    ]

    static func translate(word: String) async throws -> TranslationResult {
        let key = UserDefaults.standard.string(forKey: "openai_api_key")
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ""
        guard !key.isEmpty else { throw TranslatorError.missingAPIKey }

        let rawURL = UserDefaults.standard.string(forKey: "openai_api_url")
            ?? "https://api.openai.com/v1/chat/completions"
        let model = UserDefaults.standard.string(forKey: "openai_model")
            ?? "gpt-4o-mini"

        let urls = urlCandidates(from: rawURL)
        if urls.isEmpty { throw TranslatorError.apiError("Invalid API URL: \(rawURL)") }

        let system = """
You are a concise technical dictionary EN→ZH. The user gives a word or phrase.
Reply ONLY in this exact format (two lines, no extra text):
释义: <concise Chinese meaning, include the part-of-speech tag e.g. [n.] [v.] [adj.]>
例句: <one vivid, slightly exaggerated English sentence showing the word in a software/engineering context, followed by its Chinese translation in parentheses>
"""

        // Prepare several plausible request bodies (OpenAI-style + BigModel-friendly variants)
        let baseBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": word]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        let altPromptBody: [String: Any] = [
            "model": model,
            "prompt": word,
            "max_tokens": 300,
            "temperature": 0.7
        ]
        let altInputBody: [String: Any] = [
            "model": model,
            "input": word
        ]
        let altDataBody: [String: Any] = [
            "model": model,
            "data": ["messages": [["role": "user", "content": word]]]
        ]

        let bodyVariants: [[String: Any]] = [baseBody, altPromptBody, altInputBody, altDataBody]

        var lastErrorMessages: [String] = []

        for url in urls {
            for authMaker in authHeaderCandidates {
                let (hName, hValue) = authMaker(key)
                for body in bodyVariants {
                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.setValue(hValue, forHTTPHeaderField: hName)
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.timeoutInterval = 30

                    do {
                        req.httpBody = try JSONSerialization.data(withJSONObject: body)
                    } catch {
                        lastErrorMessages.append("serialize-error for url=\(url) bodyKeys=\(Array(body.keys)): \(error.localizedDescription)")
                        continue
                    }

                    do {
                        let (data, resp) = try await URLSession.shared.data(for: req)
                        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
                            let s = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                            lastErrorMessages.append("\(url) [\(hName)] bodyKeys=\(Array(body.keys)): \(s)")
                            continue
                        }

                        // Try parse OpenAI-style response first
                        struct Msg: Decodable { let content: String }
                        struct Choice: Decodable { let message: Msg }
                        struct Resp: Decodable { let choices: [Choice] }

                        let decoded = try? JSONDecoder().decode(Resp.self, from: data)
                        var raw = decoded?.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                            ?? String(data: data, encoding: .utf8)
                            ?? ""

                        // If provider returns a JSON with text at top-level, try to extract
                        if raw.isEmpty, let text = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let t = text["text"] as? String { raw = t }
                            else if let t = text["response"] as? String { raw = t }
                        }

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
                    } catch {
                        lastErrorMessages.append("\(url) [\(hName)] bodyKeys=\(Array(body.keys)): \(error.localizedDescription)")
                        continue
                    }
                }
            }
        }

        throw TranslatorError.apiError("All attempts failed:\n\(lastErrorMessages.joined(separator: "\n"))")
    }
}
