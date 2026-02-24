//
//  TokenManager.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import Foundation

// MARK: - Token 管理（存在 Keychain，自動判斷是否過期）

class TokenManager {

    private enum Keys {
        static let token     = "athena_jwt_token"
        static let expiresAt = "athena_jwt_expires_at"
        static let deviceId  = "athena_device_id"
    }

    // MARK: - Device ID（第一次啟動自動產生，永久保存）

    static var deviceId: String {
        if let existing = KeychainManager.load(key: Keys.deviceId) {
            return existing
        }
        let newId = UUID().uuidString
        KeychainManager.save(key: Keys.deviceId, value: newId)
        return newId
    }

    // MARK: - Token 存取

    static var token: String? {
        get { KeychainManager.load(key: Keys.token) }
        set {
            if let value = newValue {
                KeychainManager.save(key: Keys.token, value: value)
            } else {
                KeychainManager.delete(key: Keys.token)
            }
        }
    }

    static var expiresAt: Date? {
        get {
            guard let str = KeychainManager.load(key: Keys.expiresAt),
                  let ms = Double(str) else { return nil }
            return Date(timeIntervalSince1970: ms / 1000)
        }
        set {
            if let date = newValue {
                KeychainManager.save(key: Keys.expiresAt, value: String(date.timeIntervalSince1970 * 1000))
            } else {
                KeychainManager.delete(key: Keys.expiresAt)
            }
        }
    }

    // MARK: - 判斷 Token 狀態

    // Token 是否有效（存在且未過期，預留 60 秒緩衝）
    static var isValid: Bool {
        guard token != nil, let exp = expiresAt else { return false }
        return exp.timeIntervalSinceNow > 60
    }

    // Token 是否快過期（少於 1 天）
    static var isExpiringSoon: Bool {
        guard let exp = expiresAt else { return true }
        return exp.timeIntervalSinceNow < 86400
    }

    // MARK: - 儲存 Token

    static func save(token: String, expiresAt: TimeInterval) {
        self.token = token
        self.expiresAt = Date(timeIntervalSince1970: expiresAt / 1000)
    }

    static func clear() {
        token = nil
        expiresAt = nil
    }
}
