import Foundation
import LLM
import Combine

// MARK: - LLM 封裝
// 把 LLM.swift 的細節包起來，方便其他地方使用

@MainActor
class LLMWrapper: ObservableObject {

    private var llm: LLM?

    static let modelFileName = "qwen2.5-1.5b-instruct-q4_k_m.gguf"
    static var modelURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(modelFileName)
    }

    var isReady: Bool {
        FileManager.default.fileExists(atPath: Self.modelURL.path)
    }

    func load() throws {
        guard isReady else { throw LLMError.modelNotFound }
        guard let model = LLM(from: Self.modelURL, template: .chatML()) else {
            throw LLMError.loadFailed
        }
        llm = model
    }

    func respond(to prompt: String) async -> String {
        // 釋放舊 instance 重置 KV cache，再建新的
        llm = nil
        guard let model = LLM(from: Self.modelURL, template: .chatML()) else { return "" }
        llm = model
        await model.respond(to: prompt)
        return model.output
    }
}

enum LLMError: Error, LocalizedError {
    case modelNotFound
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound: return "找不到模型，請先下載"
        case .loadFailed: return "模型載入失敗"
        }
    }
}
