import SwiftUI
import Combine

// MARK: - AppState（連接後台版本）

@MainActor
class AppState: ObservableObject {

    @Published var uiState = AppUIState()
    @Published var chatHistory: [ChatBubble] = []
    @Published var serverStatus: ServerStatus = .unknown

    let llm = LLMWrapper()
    private let apiClient = AthenaAPIClient.shared
    private let intentEngine = IntentEngine()
    private let toolExecutor = ToolExecutor()

    enum ServerStatus {
        case unknown, online, offline
        var label: String {
            switch self {
            case .unknown: return "連線中"
            case .online:  return "後台連線中"
            case .offline: return "離線模式"
            }
        }
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .online:  return Color(hex: "#30D158")!
            case .offline: return Color(hex: "#FF9F0A")!
            }
        }
    }

    // MARK: - 初始化

    func initialize() async {
        // 載入本地 LLM
        try? llm.load()

        // 檢查後台狀態
        let isOnline = await apiClient.healthCheck()
        serverStatus = isOnline ? .online : .offline
        print(isOnline ? "✅ 後台連線成功" : "⚠️ 後台離線，使用本地模式")

        // 如果後台在線，預先取得 token
        if isOnline {
            try? await apiClient.ensureValidToken()
        }
    }

    // MARK: - 處理使用者輸入

    func handleInput(_ input: String) async {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        chatHistory.append(ChatBubble(role: "user", content: input))
        withAnimation { uiState.isLoading = true }

        if serverStatus == .online {
            // 後台模式：大 LLM 判斷意圖
            await handleWithServer(input)
        } else {
            // 離線模式：本地小 LLM
            await handleLocally(input)
        }

        withAnimation { uiState.isLoading = false }
    }

    // MARK: - 後台模式

    private func handleWithServer(_ input: String) async {
        do {
            let response = try await apiClient.sendIntent(input: input)
            let intent   = response.intent

            print("🎯 後台意圖：\(intent.tool)")

            // 根據 intent 更新 UI
            let widget = await resolveWidget(intent: intent, data: response.data)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                uiState.widget = widget
                uiState.title  = titleFor(tool: intent.tool, params: intent.params)
            }

            if let reply = intent.reply {
                chatHistory.append(ChatBubble(role: "assistant", content: reply))
            }

        } catch {
            print("⚠️ 後台失敗，切換本地模式：\(error)")
            serverStatus = .offline
            await handleLocally(input)
        }
    }

    // MARK: - 離線模式（本地小 LLM）

    private func handleLocally(_ input: String) async {
        if let quick = intentEngine.quickMatch(input: input) {
            let widget = await toolExecutor.execute(quick)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                uiState.widget = widget
                uiState.title  = titleFor(tool: quick.tool.rawValue, params: quick.params)
            }
        } else if llm.isReady {
            let call = await intentEngine.llmMatch(input: input, llm: llm)
            let widget = await toolExecutor.execute(call)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                uiState.widget = widget
                uiState.title  = titleFor(tool: call.tool.rawValue, params: call.params)
            }
        } else {
            withAnimation {
                uiState.widget = .error("後台離線且本地模型未載入")
            }
        }
    }

    // MARK: - 把後台回傳的 intent + data 轉成 AppWidget

    private func resolveWidget(intent: IntentData, data: AnyCodable?) async -> AppWidget {
        switch intent.tool {
        case "news":
            if let codable = data,
               let articles = codable.value as? [NewsItemDTO] {
                let items = articles.map { dto in
                    NewsItem(
                        title:       dto.title,
                        description: dto.description,
                        url:         dto.url,
                        imageUrl:    dto.urlToImage,
                        source:      dto.source?.name ?? "",
                        publishedAt: dto.publishedAt ?? ""
                    )
                }
                return .news(items)
            }
            return .error("無法取得新聞資料")

        case "stock":
            // 股票由後台查，解析回傳的 data
            if let codable = data,
               let dict = codable.value as? [String: Any],
               let price = dict["price"] as? Double,
               let symbol = dict["symbol"] as? String {
                let change = dict["change"] as? Double ?? 0
                let changePercent = dict["changePercent"] as? Double ?? 0
                let previousClose = dict["previousClose"] as? Double ?? price

                // 解析 K 線為 StockPoint
                var points: [StockPoint] = []
                if let rawCandles = dict["candles"] as? [[String: Any]] {
                    points = rawCandles.compactMap { c in
                        guard let close = c["close"] as? Double,
                              let time  = c["time"]  as? Double else { return nil }
                        return StockPoint(
                            time:  Date(timeIntervalSince1970: time),
                            price: close
                        )
                    }
                }

                let stockData = StockData(
                    symbol:        symbol,
                    name:          symbol,
                    price:         price,
                    change:        change,
                    changePercent: changePercent,
                    points:        points
                )
                return .stock(stockData)
            }
            return .error("無法取得股票資料")

        case "weather":
            return .error("天氣功能即將推出")

        case "sports":
            return .error("球賽功能即將推出")

        case "chat":
            let reply = intent.reply ?? intent.params?["reply"] ?? "好的"
            chatHistory.append(ChatBubble(role: "assistant", content: reply))
            return uiState.widget  // 保持原畫面

        case "clear":
            return .empty

        default:
            return .error("未知的指令")
        }
    }

    private func titleFor(tool: String, params: [String: String]?) -> String? {
        switch tool {
        case "news":    return "📰 \(params?["query"] ?? "新聞")"
        case "stock":   return "📈 \(params?["symbol"] ?? "股票")"
        case "weather": return "🌤 天氣"
        case "sports":  return "🏀 球賽"
        default:        return nil
        }
    }

    func reset() {
        withAnimation {
            uiState    = AppUIState()
            chatHistory = []
        }
    }
}
