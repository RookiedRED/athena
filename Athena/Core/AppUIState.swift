import SwiftUI

// MARK: - Widget 系統

enum AppWidget {
    case empty
    case chat([ChatBubble])
    case news([NewsItem])
    case newsDetail(NewsItem)
    case stock(StockData)
    case weather(WeatherSnapshot)
    case sports([SportsEvent])
    case webView(URL)
    case imageGrid([URL])
    case error(String)
}

struct AppUIState {
    var widget: AppWidget = .empty
    var title: String? = nil
    var isLoading: Bool = false
}

// MARK: - 資料模型

struct ChatBubble: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

struct NewsItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String?
    let url: String
    let imageUrl: String?
    let source: String
    let publishedAt: String

    enum CodingKeys: String, CodingKey {
        case title, description, url, source, publishedAt
        case imageUrl = "urlToImage"
    }
}

struct StockData: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let points: [StockPoint]
}

struct StockPoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

struct WeatherSnapshot {
    let city: String
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
    let icon: String
    let hourly: [HourlyWeather]
}

struct HourlyWeather: Identifiable {
    let id = UUID()
    let hour: String
    let temp: Double
    let icon: String
}

struct SportsEvent: Identifiable {
    let id = UUID()
    let league: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: String?
    let awayScore: String?
    let status: String
    let startTime: String
    let streamUrl: String?
}

// MARK: - iOS 26 Design Tokens

struct DS {
    // Liquid Glass 用系統 material，這裡定義語義色
    static let accent      = Color(hex: "#0A84FF")!   // iOS Blue
    static let accentGreen = Color(hex: "#30D158")!
    static let accentRed   = Color(hex: "#FF453A")!
    static let label       = Color.white
    static let secondLabel = Color.white.opacity(0.55)
    static let fill        = Color.white.opacity(0.08)
    static let separator   = Color.white.opacity(0.12)
    static let cardRadius: CGFloat   = 22
    static let cornerRadius: CGFloat = 16
}

// MARK: - Color Helper

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        h = h.hasPrefix("#") ? String(h.dropFirst()) : h
        guard h.count == 6, let v = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8)  & 0xFF) / 255,
            blue:  Double(v         & 0xFF) / 255
        )
    }
}
