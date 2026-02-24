//
//  AthenaAPIClient.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import Foundation

// MARK: - Athena API Client
// 負責所有跟後台的溝通

class AthenaAPIClient {

    static let baseURL = AppEnvironment.baseURL

    static let shared = AthenaAPIClient()
    private init() {}

    // MARK: - 取得 / 刷新 Token

    func ensureValidToken() async throws {
        if TokenManager.isValid && !TokenManager.isExpiringSoon { return }

        if TokenManager.token != nil {
            // 有舊 token，嘗試 refresh
            try await refreshToken()
        } else {
            // 第一次，取得新 token
            try await fetchToken()
        }
    }

    private func fetchToken() async throws {
        guard let url = URL(string: "\(Self.baseURL)/api/auth/token") else {
            throw APIError.networkError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(TokenManager.deviceId, forHTTPHeaderField: "x-device-id")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.authFailed
        }

        let result = try JSONDecoder().decode(TokenResponse.self, from: data)
        TokenManager.save(token: result.token, expiresAt: result.expiresAt)
        print("✅ Token 取得成功，裝置 ID：\(TokenManager.deviceId)")
    }

    private func refreshToken() async throws {
        guard let url = URL(string: "\(Self.baseURL)/api/auth/refresh") else {
            throw APIError.networkError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(TokenManager.deviceId, forHTTPHeaderField: "x-device-id")

        if let oldToken = TokenManager.token {
            request.setValue("Bearer \(oldToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            // Refresh 失敗就重新取得
            try await fetchToken()
            return
        }

        let result = try JSONDecoder().decode(TokenResponse.self, from: data)
        TokenManager.save(token: result.token, expiresAt: result.expiresAt)
        print("🔄 Token 刷新成功")
    }

    // MARK: - 送出意圖（主要呼叫）

    func sendIntent(input: String, currentState: [String: Any] = [:]) async throws -> IntentResponse {
        try await ensureValidToken()

        guard let token = TokenManager.token else { throw APIError.authFailed }

        guard let url = URL(string: "\(Self.baseURL)/api/intent") else {
            throw APIError.networkError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120  // LLM 推論可能需要較長時間

        let body: [String: Any] = [
            "input": input,
            "currentState": currentState
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.networkError }

        if http.statusCode == 401 || http.statusCode == 403 {
            // Token 失效，清掉重試一次
            TokenManager.clear()
            throw APIError.authFailed
        }

        guard http.statusCode == 200 else {
            throw APIError.serverError(http.statusCode)
        }

        return try JSONDecoder().decode(IntentResponse.self, from: data)
    }

    // MARK: - 健康檢查

    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(Self.baseURL)/health") else { return false }
        guard let (_, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
}

// MARK: - Response Models

struct TokenResponse: Codable {
    let token: String
    let expiresAt: Double
}

struct IntentResponse: Codable {
    let intent: IntentData
    let data: AnyCodable?
    let processedAt: Double?
}

struct IntentData: Codable {
    let tool: String
    let params: [String: String]?
    let reply: String?
}

// AnyCodable：讓 data 欄位可以是任何 JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([NewsItemDTO].self) {
            value = arr
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

struct NewsItemDTO: Codable {
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let source: NewsSourceDTO?
    let publishedAt: String?

    struct NewsSourceDTO: Codable {
        let name: String?
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case authFailed
    case networkError
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .authFailed:        return "連線驗證失敗，請確認網路"
        case .networkError:      return "無法連線到伺服器"
        case .serverError(let c): return "伺服器錯誤：\(c)"
        case .parseError:        return "資料解析失敗"
        }
    }
}
