import Foundation

protocol Translating {
    func translate(text: String, to targetLanguageCode: String) async throws -> String
}

final class TranslationService: Translating {
    func translate(text: String, to targetLanguageCode: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        do {
            return try await requestOnlineTranslation(text: trimmed, targetLanguageCode: targetLanguageCode)
        } catch {
            return fallbackTranslation(for: trimmed, targetLanguageCode: targetLanguageCode)
        }
    }

    private func requestOnlineTranslation(text: String, targetLanguageCode: String) async throws -> String {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "en|\(targetLanguageCode)")
        ]

        guard let url = components?.url else {
            throw AppError.translationFailed
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.translationFailed
        }

        let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        let translated = decoded.responseData.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !translated.isEmpty else {
            throw AppError.translationFailed
        }

        return translated
    }

    // Last-resort local fallback so user still gets something if network translation fails.
    private func fallbackTranslation(for text: String, targetLanguageCode: String) -> String {
        guard targetLanguageCode == "hi" else {
            return text
        }

        let dictionary: [String: String] = [
            "hello": "नमस्ते",
            "hi": "नमस्ते",
            "yes": "हाँ",
            "no": "नहीं",
            "run": "दौड़",
            "running": "दौड़ना",
            "distance": "दूरी",
            "time": "समय",
            "pace": "गति",
            "today": "आज",
            "good": "अच्छा",
            "morning": "सुबह",
            "evening": "शाम"
        ]

        return text
            .split(separator: " ")
            .map { dictionary[$0.lowercased()] ?? String($0) }
            .joined(separator: " ")
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: ResponseData

    struct ResponseData: Decodable {
        let translatedText: String
    }
}
