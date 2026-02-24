import SwiftUI
import Charts

// MARK: - 股票 Widget — iOS 26 Liquid Glass

struct StockWidget: View {
    let data: StockData
    var isUp: Bool { data.change >= 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 價格卡
                PriceCard(data: data, isUp: isUp)

                // 圖表卡
                if data.points.count > 2 {
                    LiquidChartCard(data: data, isUp: isUp)
                }

                // 數字統計
                StatsRow(data: data, isUp: isUp)

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

// MARK: - 價格卡

struct PriceCard: View {
    let data: StockData
    let isUp: Bool
    var color: Color { isUp ? DS.accentGreen : DS.accentRed }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 股票代碼 + 名稱
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(data.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(0.5)
                    Text(data.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                // 漲跌標籤
                HStack(spacing: 4) {
                    Image(systemName: isUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                    Text(String(format: "%.2f%%", abs(data.changePercent)))
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
            }

            // 大價格
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.2f", data.price))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%+.2f 今日", data.change))
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), Color.white.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - 圖表卡

struct LiquidChartCard: View {
    let data: StockData
    let isUp: Bool
    var color: Color { isUp ? DS.accentGreen : DS.accentRed }
    var minPrice: Double { data.points.map(\.price).min() ?? 0 }
    var maxPrice: Double { data.points.map(\.price).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今日走勢")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .kerning(0.6)

            Chart(data.points) { point in
                // 面積
                AreaMark(
                    x: .value("時間", point.time),
                    yStart: .value("Min", minPrice * 0.9995),
                    yEnd:   .value("價格", point.price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // 線
                LineMark(
                    x: .value("時間", point.time),
                    y: .value("價格", point.price)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: minPrice * 0.999 ... maxPrice * 1.001)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) {
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.3))
                        .font(.system(size: 11))
                }
            }
            .frame(height: 180)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - 統計行

struct StatsRow: View {
    let data: StockData
    let isUp: Bool

    var body: some View {
        HStack(spacing: 10) {
            StatPill(label: "最高",
                     value: String(format: "%.2f", data.points.map(\.price).max() ?? 0),
                     color: DS.accentGreen)
            StatPill(label: "最低",
                     value: String(format: "%.2f", data.points.map(\.price).min() ?? 0),
                     color: DS.accentRed)
            StatPill(label: "筆數",
                     value: "\(data.points.count)",
                     color: .white.opacity(0.5))
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(0.4)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
        )
    }
}
