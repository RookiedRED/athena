//
//  KeychainManager.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import Foundation
import Security

// MARK: - Keychain 管理器

struct KeychainManager {

    // MARK: - 存入

    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // 先刪掉舊的
        delete(key: key)

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key,
            kSecAttrService:     "com.athena.app",
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - 讀取

    static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key,
            kSecAttrService:     "com.athena.app",
            kSecReturnData:      true,
            kSecMatchLimit:      kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    // MARK: - 刪除

    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.athena.app"
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - API Key 語義包裝

extension KeychainManager {

    enum APIKey: String {
        case news    = "api_key_news"
        case stock   = "api_key_stock"
    }

    static func saveAPIKey(_ key: APIKey, value: String) {
        save(key: key.rawValue, value: value)
    }

    static func loadAPIKey(_ key: APIKey) -> String? {
        load(key: key.rawValue)
    }
}
