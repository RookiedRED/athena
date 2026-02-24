import SwiftUI

// MARK: - 新聞 Widget — iOS 26 Liquid Glass

struct NewsWidget: View {
    let items: [NewsItem]
    @Environment(\.openURL) var openURL

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                // 頭條大卡
                if let first = items.first {
                    HeroNewsCard(item: first)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .onTapGesture { openIfValid(first.url) }
                }

                // 分隔標題
                HStack {
                    Text("更多報導")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .kerning(0.8)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                // 其餘列表
                VStack(spacing: 0) {
                    ForEach(Array(items.dropFirst().enumerated()), id: \.1.id) { idx, item in
                        ListNewsRow(item: item, isLast: idx == items.count - 2)
                            .onTapGesture { openIfValid(item.url) }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                .padding(.horizontal, 16)

                Spacer().frame(height: 110)
            }
        }
    }

    private func openIfValid(_ urlStr: String) {
        if let url = URL(string: urlStr) { openURL(url) }
    }
}

// MARK: - 頭條大卡

struct HeroNewsCard: View {
    let item: NewsItem
    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 來源標籤
            HStack(spacing: 6) {
                Circle()
                    .fill(DS.accent)
                    .frame(width: 6, height: 6)
                Text(item.source.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.accent)
                    .kerning(0.6)
                Spacer()
                Text(relativeDate(item.publishedAt))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
            }

            // 標題
            Text(item.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(3)

            // 描述
            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(3)
                    .lineSpacing(2)
            }

            // 閱讀按鈕
            HStack {
                Spacer()
                Label("閱讀全文", systemImage: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.accent)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .scaleEffect(pressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25), value: pressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
            pressing: { pressing in pressed = pressing }, perform: {})
    }
}

// MARK: - 列表行

struct ListNewsRow: View {
    let item: NewsItem
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // 文字
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.source)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.accent)
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .lineSpacing(2)
                    Text(relativeDate(item.publishedAt))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.top, 3)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.07))
                    .padding(.leading, 18)
            }
        }
    }
}

// MARK: - 時間格式化

private func relativeDate(_ str: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: str) {
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "zh_TW")
        rel.unitsStyle = .short
        return rel.localizedString(for: date, relativeTo: Date())
    }
    return str
}
