import Foundation

// MARK: - ToolExecutor
// 前端只處理本地操作，所有外部 API（新聞、股票）都由後台負責
// 這裡只處理後台回傳 intent 後，需要本地執行的部分

class ToolExecutor {

    func execute(_ call: ToolCall) async -> AppWidget {
        switch call.tool {

        case .news:
            // 由後台查詢，不應走到這裡
            return .error("新聞由後台處理")

        case .stock:
            // 由後台查詢，不應走到這裡
            return .error("股票由後台處理")

        case .weather:
            return .error("天氣功能即將推出")

        case .sports:
            return .error("球賽功能即將推出")

        case .chat:
            let reply = call.reply ?? call.params["reply"] ?? "好的，我在這裡"
            return .chat([ChatBubble(role: "assistant", content: reply)])

        case .clear:
            return .empty
        }
    }
}
