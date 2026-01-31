import Foundation

enum AnthropicError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case parseError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class AnthropicService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"
    private let session: URLSession

    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Parse a credit card statement into structured JSON.
    func parseStatement(_ text: String) async throws -> [String: Any] {
        let prompt = """
        Parse this credit card statement and extract the following information in JSON format:
        {
          "cardIdentifier": "string - card name/type if identifiable",
          "issuer": "string - bank/issuer name",
          "statementDate": "YYYY-MM-DD",
          "balance": number,
          "minimumPayment": number,
          "dueDate": "YYYY-MM-DD",
          "apr": number (as percentage, e.g., 21.99),
          "transactions": [
            {
              "date": "YYYY-MM-DD",
              "description": "string",
              "amount": number (positive for charges, negative for credits),
              "category": "string - best guess: groceries, gas, dining, travel, streaming, amazon, other"
            }
          ],
          "categoryTotals": {
            "groceries": number,
            "gas": number,
            "dining": number,
            "travel": number,
            "streaming": number,
            "amazon": number,
            "other": number
          },
          "rewardsEarned": number or null,
          "rewardsType": "string - points/miles/cashback type" or null
        }

        Statement text:
        \(text)

        Return ONLY valid JSON, no other text.
        """

        return try await sendRequest(prompt: prompt, maxTokens: 8000)
    }

    /// Parse credit report hard inquiries.
    func parseCreditReport(_ text: String) async throws -> [String: Any] {
        let prompt = """
        Parse this credit report text and extract all HARD INQUIRIES (not soft inquiries). Return JSON:

        {
          "bureau": "Experian" | "Equifax" | "TransUnion",
          "inquiries": [
            {
              "creditor": "string - company name",
              "date": "YYYY-MM-DD",
              "type": "string - credit card, auto loan, mortgage, personal loan, other"
            }
          ]
        }

        Credit report text:
        \(text)

        Return ONLY valid JSON, no other text. Only include hard inquiries, not soft/promotional inquiries.
        """

        return try await sendRequest(prompt: prompt, maxTokens: 8000)
    }

    /// Analyze a card for recommendation given user context.
    func analyzeCard(_ cardInfo: String, context: String) async throws -> [String: Any] {
        let prompt = """
        You are a credit card rewards expert. Analyze whether this person should apply for this card.

        CARD BEING CONSIDERED:
        \(cardInfo)

        CURRENT SITUATION:
        \(context)

        Provide a structured analysis in JSON format:
        {
          "recommendation": "APPLY" | "WAIT" | "SKIP",
          "signupBonusValue": number (dollar value of signup bonus),
          "firstYearValue": number (total first year value including bonus minus fee),
          "ongoingAnnualValue": number (value in subsequent years minus fee),
          "pros": ["string", "string", ...],
          "cons": ["string", "string", ...],
          "timing": "string - best time to apply or why to wait",
          "alternativeCards": ["string", "string"] or null,
          "spendStrategy": "string - how to meet minimum spend",
          "keepOrChurn": "KEEP" | "CHURN" - whether to keep long-term or cancel after bonus,
          "summary": "2-3 sentence summary of recommendation"
        }

        Consider:
        1. Does this card overlap with existing cards?
        2. Is the signup bonus competitive vs alternatives?
        3. Can they realistically meet the spend requirement?
        4. Impact on 5/24 status
        5. Whether this is a card to keep or churn
        6. Transfer partner overlap with existing points

        Return ONLY valid JSON.
        """

        return try await sendRequest(prompt: prompt, maxTokens: 2000)
    }

    // MARK: - Private Helpers

    private func sendRequest(prompt: String, maxTokens: Int) async throws -> [String: Any] {
        guard let url = URL(string: baseURL) else {
            throw AnthropicError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AnthropicError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.invalidResponse
        }

        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Check for API-level errors
        if httpResponse.statusCode != 200 {
            if let error = responseDict["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AnthropicError.apiError(message)
            }
            throw AnthropicError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Extract text content from the response
        guard let contentArray = responseDict["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              let text = firstBlock["text"] as? String else {
            throw AnthropicError.invalidResponse
        }

        return try parseJSONFromResponse(text)
    }

    /// Parse JSON from Claude's response text, handling markdown fences and extraction fallbacks.
    private func parseJSONFromResponse(_ text: String) throws -> [String: Any] {
        // Step 1: Strip markdown code fences if present
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(
            of: #"^```(?:json)?\s*\n?"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"\n?```\s*$"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 2: Try direct JSON parse
        if let data = cleaned.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }

        // Step 3: Fallback - balanced brace matching to extract JSON object
        var braceCount = 0
        var startIdx: String.Index?
        var endIdx: String.Index?

        for i in cleaned.indices {
            let char = cleaned[i]
            if char == "{" {
                if startIdx == nil { startIdx = i }
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 && startIdx != nil {
                    endIdx = cleaned.index(after: i)
                    break
                }
            }
        }

        if let start = startIdx, let end = endIdx {
            let jsonSubstring = String(cleaned[start..<end])
            if let data = jsonSubstring.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }

        throw AnthropicError.parseError("Could not extract valid JSON from response")
    }
}
