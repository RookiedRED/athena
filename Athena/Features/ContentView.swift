import SwiftUI

// MARK: - 主畫面 — iOS 26 Liquid Glass 設計語言

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false

    var body: some View {
        ZStack {

            // ── 1. Mesh Gradient 背景（iOS 26 特色）──────────────────
            MeshGradientBackground()
                .ignoresSafeArea()

            // ── 2. 主要內容 ───────────────────────────────────────────
            VStack(spacing: 0) {

                // 頂部標題（有內容才顯示）
                if let title = appState.uiState.title {
                    LiquidTitleBar(title: title, onClose: { appState.reset() })
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Widget 區域
                ZStack {
                    if appState.uiState.isLoading {
                        LiquidLoadingView()
                    } else {
                        WidgetRenderer(widget: appState.uiState.widget)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.96).combined(with: .opacity),
                                removal:   .scale(scale: 1.02).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: appState.uiState.isLoading)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: appState.uiState.title)
            }

            // ── 3. 底部 Liquid Glass 輸入列 ───────────────────────────
            VStack {
                Spacer()
                LiquidInputBar(text: $inputText, focused: $inputFocused) { input in
                    Task { await appState.handleInput(input) }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Mesh Gradient 背景

struct MeshGradientBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [Float(0.5 + 0.08 * sin(t * 0.4)), Float(0.5 + 0.08 * cos(t * 0.3))], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(hex: "#050508")!, Color(hex: "#080C1A")!, Color(hex: "#050508")!,
                    Color(hex: "#0A0F1E")!, Color(hex: "#0D1829")!, Color(hex: "#0A0F1E")!,
                    Color(hex: "#050508")!, Color(hex: "#06090F")!, Color(hex: "#050508")!
                ]
            )
        }
    }
}

// MARK: - Liquid Glass 標題列

struct LiquidTitleBar: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        // iOS 26 Liquid Glass
        .background(.ultraThinMaterial)
        .overlay(Divider().opacity(0.4), alignment: .bottom)
    }
}

// MARK: - Widget 渲染器

struct WidgetRenderer: View {
    let widget: AppWidget

    var body: some View {
        switch widget {
        case .empty:
            EmptyHomeView()
        case .news(let items):
            NewsWidget(items: items)
        case .newsDetail(let item):
            NewsDetailPlaceholder(item: item)
        case .stock(let data):
            StockWidget(data: data)
        case .chat(let bubbles):
            ChatWidget(bubbles: bubbles)
        case .error(let msg):
            LiquidErrorView(message: msg)
        default:
            LiquidComingSoon()
        }
    }
}

// MARK: - 空白首頁

struct EmptyHomeView: View {
    @EnvironmentObject var appState: AppState
    let suggestions = [
        ("newspaper.fill",  "今天有什麼新聞",    Color(hex: "#0A84FF")!),
        ("chart.xyaxis.line","台積電股價走勢",   Color(hex: "#30D158")!),
        ("cloud.sun.fill",  "台北天氣",          Color(hex: "#FF9F0A")!),
        ("sportscourt.fill","今晚有球賽嗎",       Color(hex: "#FF453A")!),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                // 後台狀態指示
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.serverStatus.color)
                        .frame(width: 6, height: 6)
                    Text(appState.serverStatus.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(appState.serverStatus.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(appState.serverStatus.color.opacity(0.1))
                .clipShape(Capsule())

                // Hero 文字
                VStack(spacing: 8) {
                    Text("Athena，有什麼")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("我可以幫你的嗎？")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                // 建議卡片
                VStack(spacing: 12) {
                    ForEach(suggestions, id: \.1) { icon, text, color in
                        SuggestionRow(icon: icon, text: text, color: color)
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 100)
            }
        }
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon pill
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Liquid Glass card
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - 對話 Widget

struct ChatWidget: View {
    let bubbles: [ChatBubble]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(bubbles) { bubble in
                    ChatBubbleView(bubble: bubble)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }
}

struct ChatBubbleView: View {
    let bubble: ChatBubble
    var isUser: Bool { bubble.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(bubble.content)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    isUser
                    ? DS.accent
                    : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Loading

struct LiquidLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 2)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        LinearGradient(colors: [.white, .white.opacity(0)],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
            Text("Athena 思考中…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
    }
}

// MARK: - 錯誤

struct LiquidErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.orange.opacity(0.8))
            Text(message)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct LiquidComingSoon: View {
    var body: some View {
        VStack {
            Spacer()
            Text("即將推出")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
        }
    }
}

struct NewsDetailPlaceholder: View {
    let item: NewsItem
    var body: some View {
        VStack { Text(item.title).foregroundStyle(.white).padding() }
    }
}

// MARK: - Liquid Glass 輸入列

struct LiquidInputBar: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("問 Athena 任何事…", text: $text)
                .focused(focused)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .tint(DS.accent)
                .submitLabel(.send)
                .onSubmit { submit() }

            // 送出按鈕
            Button(action: submit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(text.isEmpty ? .white.opacity(0.3) : .white)
                    .frame(width: 32, height: 32)
                    .background(text.isEmpty ? Color.white.opacity(0.08) : DS.accent)
                    .clipShape(Circle())
                    .animation(.spring(response: 0.3), value: text.isEmpty)
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // iOS 26 Liquid Glass floating bar
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 28)
    }

    private func submit() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        onSubmit(t)
        text = ""
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
