import Foundation

// MARK: - 意圖識別引擎
// LLM 只負責把使用者的話翻譯成「要呼叫什麼 Tool + 參數」
// 不再直接控制 UI

struct ToolCall: Codable {
    let tool: ToolType
    let params: [String: String]
    let reply: String?          // AI 的口頭回應（可選）
}

enum ToolType: String, Codable {
    case news       // 新聞查詢
    case stock      // 股票走勢
    case weather    // 天氣
    case sports     // 球賽
    case chat       // 一般對話（不需要外部資料）
    case clear      // 清空畫面
}

// MARK: - IntentEngine

class IntentEngine {

    // 用簡單的關鍵字比對快速判斷（不過 LLM，快又穩）
    func quickMatch(input: String) -> ToolCall? {
        let t = input.lowercased()

        // 新聞
        if t.contains("新聞") || t.contains("今天發生") || t.contains("最新消息") {
            let query = extractQuery(from: input, keywords: ["新聞", "最新消息", "今天發生"])
            return ToolCall(tool: .news, params: ["query": query ?? "台灣"], reply: nil)
        }

        // 股票
        if t.contains("股票") || t.contains("走勢") || t.contains("股價") {
            let symbol = extractStockSymbol(from: input)
            return ToolCall(tool: .stock, params: ["symbol": symbol], reply: nil)
        }

        // 天氣
        if t.contains("天氣") || t.contains("氣溫") || t.contains("下雨") {
            let city = extractCity(from: input) ?? "台北"
            return ToolCall(tool: .weather, params: ["city": city], reply: nil)
        }

        // 球賽
        if t.contains("球賽") || t.contains("比賽") || t.contains("轉播") || t.contains("nba") || t.contains("足球") {
            return ToolCall(tool: .sports, params: ["query": input], reply: nil)
        }

        // 清空
        if t.contains("清空") || t.contains("回到主畫面") || t.contains("清除") {
            return ToolCall(tool: .clear, params: [:], reply: nil)
        }

        return nil  // 無法快速判斷，交給 LLM
    }

    // LLM 判斷（處理模糊、複雜的指令）
    func llmMatch(input: String, llm: LLMWrapper) async -> ToolCall {
        let prompt = """
        將使用者的請求分類成以下其中一個 Tool，只回傳 JSON：

        Tool 列表：
        - news: 查詢新聞、時事、最新消息
        - stock: 查看股票、股價、走勢、投資
        - weather: 查看天氣、氣溫、降雨
        - sports: 球賽、比賽、體育、轉播
        - chat: 一般對話、問問題、聊天
        - clear: 清空、回到空白畫面

        回傳格式：
        { "tool": "tool名稱", "params": { "query": "相關關鍵字" }, "reply": "簡短口頭回應" }

        使用者說：「\(input)」

        只回傳 JSON：
        """

        let response = await llm.respond(to: prompt)

        if let data = extractJSON(from: response).data(using: .utf8),
           let call = try? JSONDecoder().decode(ToolCall.self, from: data) {
            return call
        }

        // fallback
        return ToolCall(tool: .chat, params: ["message": input], reply: nil)
    }

    // MARK: - 輔助工具

    private func extractQuery(from input: String, keywords: [String]) -> String? {
        for kw in keywords {
            if let range = input.range(of: kw) {
                let after = String(input[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !after.isEmpty { return after }
            }
        }
        return nil
    }

    private func extractStockSymbol(from input: String) -> String {
        let symbolMap: [String: String] = [
            "台積電": "2330.TW", "tsmc": "TSM",
            "鴻海": "2317.TW", "聯發科": "2454.TW",
            "蘋果": "AAPL", "apple": "AAPL",
            "特斯拉": "TSLA", "tesla": "TSLA",
            "nvidia": "NVDA", "輝達": "NVDA"
        ]
        let lower = input.lowercased()
        for (key, symbol) in symbolMap {
            if lower.contains(key.lowercased()) { return symbol }
        }
        return "2330.TW"  // 預設台積電
    }

    private func extractCity(from input: String) -> String? {
        let cities = ["台北", "台中", "台南", "高雄", "新竹", "東京", "紐約", "倫敦", "上海"]
        for city in cities {
            if input.contains(city) { return city }
        }
        return nil
    }

    private func extractJSON(from text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.replacingOccurrences(of: "```json", with: "")
                     .replacingOccurrences(of: "```", with: "")
                     .trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = clean.firstIndex(of: "{"), let e = clean.lastIndex(of: "}") {
            return String(clean[s...e])
        }
        return clean
    }
}
