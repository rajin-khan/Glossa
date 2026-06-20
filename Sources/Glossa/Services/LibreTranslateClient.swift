import Foundation

enum LibreTranslateClient {
    static func resolvedEndpoint(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        if components.path.isEmpty || components.path == "/" {
            components.path = "/translate"
        }

        return components.url ?? url
    }

    static func translate(
        text: String,
        sourceLanguage: String,
        targetLanguage: String,
        endpoint: URL
    ) async throws -> String {
        var request = URLRequest(url: resolvedEndpoint(from: endpoint))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            LibreTranslateBody(
                q: text,
                source: normalizedSourceLanguage(sourceLanguage),
                target: targetLanguage,
                format: "text"
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw LibreTranslateError.badResponse
        }

        let decoded = try JSONDecoder().decode(LibreTranslateResponse.self, from: data)
        let translated = decoded.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translated.isEmpty else {
            throw LibreTranslateError.emptyTranslation
        }
        return translated
    }

    private static func normalizedSourceLanguage(_ sourceLanguage: String) -> String {
        let normalized = sourceLanguage.lowercased()
        guard (2...3).contains(normalized.count) else { return "auto" }
        return normalized
    }
}

private struct LibreTranslateBody: Encodable {
    let q: String
    let source: String
    let target: String
    let format: String
}

private struct LibreTranslateResponse: Decodable {
    let translatedText: String
}

enum LibreTranslateError: LocalizedError {
    case badResponse
    case emptyTranslation

    var errorDescription: String? {
        switch self {
        case .badResponse:
            "LibreTranslate did not return a successful response."
        case .emptyTranslation:
            "LibreTranslate returned an empty translation."
        }
    }
}
