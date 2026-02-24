//
//  AppEnvironment.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import Foundation

// MARK: - AppEnvironment

enum AppEnvironment {

    static let baseURL: String = {
        guard let url = Bundle.main.infoDictionary?["ATHENA_BASE_URL"] as? String,
              !url.isEmpty,
              url != "$(ATHENA_BASE_URL)" else {
            // xcconfig 未設定時使用預設值（不 crash）
            print("⚠️ ATHENA_BASE_URL 未設定，使用預設 localhost")
            return "http://localhost:3000"
        }
        return url
    }()
}
