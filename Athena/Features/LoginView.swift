//
//  LoginView.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import SwiftUI

struct LoginView: View {
    let onLoginSuccess: () -> Void

    @State private var phase: LoginPhase = .idle
    @State private var errorMessage: String? = nil
    @State private var animateIn = false
    @State private var pressed = false
    
    private let slides: [FeatureSlide] = [
        .init(icon: "newspaper.fill",
              title: "即時新聞與資訊",
              subtitle: "快速整理重點、掌握最新動態",
              tint: Color(hex: "#0A84FF")!,
              isActionable: false),
        .init(icon: "chart.xyaxis.line",
              title: "股票走勢分析",
              subtitle: "摘要趨勢、指標解讀、個股快問快答",
              tint: Color(hex: "#30D158")!,
              isActionable: false),
        .init(icon: "cloud.sun.fill",
              title: "天氣與生活助理",
              subtitle: "天氣提醒、行程建議、生活小幫手",
              tint: Color(hex: "#FF9F0A")!,
              isActionable: false)
    ]

    enum LoginPhase { case idle, connecting, success }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)
                    header.padding(.bottom, 22)
                    card
                        .frame(maxWidth: 520)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 22)
                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
            }
        .background(background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82).delay(0.15)) {
                animateIn = true
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#050508")!,
                    Color(hex: "#0A0F1E")!,
                    Color(hex: "#050508")!
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 柔和、較「玻璃系」的光暈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#0A84FF")!.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 320
                    )
                )
                .frame(width: 650, height: 650)
                .offset(x: -140, y: -260)
                .blur(radius: 55)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#30D158")!.opacity(0.10), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 240
                    )
                )
                .frame(width: 520, height: 520)
                .offset(x: 170, y: 330)
                .blur(radius: 60)

            // 顆粒感（很淡，增加質感）
            NoiseOverlay(opacity: 0.05)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#0A84FF")!, Color(hex: "#0055CC")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 0.6)
                    )
                    .shadow(color: Color(hex: "#0A84FF")!.opacity(0.35), radius: 26, y: 10)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .scaleEffect(animateIn ? 1 : 0.7)
            .opacity(animateIn ? 1 : 0)

            VStack(spacing: 6) {
                Text("Athena")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("你的 AI 智能助理")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 14)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 18) {

            HStack {
                Text("功能介紹")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                if phase == .success {
                    Label("已連線", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#30D158")!)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#30D158")!.opacity(0.14), in: Capsule())
                }
            }

            // Feature 列表
            FeatureCarousel(slides: slides)

            // Divider 更淡更細
            Divider()
                .overlay(Color.white.opacity(0.08))

            primaryButton

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#FF453A")!)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "#FF453A")!.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text("連線時系統會自動取得安全 Token\n之後開啟 App 不需要重新登入")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.28))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 2)
        }
        .padding(22)
        .background(
            ZStack {
                // 外層柔光（讓它不像「框框」）
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 14)
                    .opacity(0.9)

                // 玻璃本體
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)

                // 超細玻璃描邊
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            }
        )
        .shadow(color: .black.opacity(0.30), radius: 26, y: 18)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button(action: connect) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(buttonFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 0.7)
                    )
                    .shadow(color: buttonShadow, radius: 18, y: 10)

                contentForButton
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: pressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: phase)
        }
        .disabled(phase == .connecting || phase == .success)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var contentForButton: some View {
        Group {
            if phase == .connecting {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("正在連線…")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
            } else if phase == .success {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("連線成功")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
            } else {
                Text("開始使用")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var buttonFill: some ShapeStyle {
        if phase == .success {
            return AnyShapeStyle(Color(hex: "#30D158")!)
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "#0A84FF")!, Color(hex: "#0055CC")!],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var buttonShadow: Color {
        phase == .success
        ? Color(hex: "#30D158")!.opacity(0.25)
        : Color(hex: "#0A84FF")!.opacity(0.25)
    }

    // MARK: - Connect

    private func connect() {
        phase = .connecting
        errorMessage = nil

        Task {
            do {
                try await AthenaAPIClient.shared.ensureValidToken()
                withAnimation { phase = .success }
                try? await Task.sleep(nanoseconds: 800_000_000)
                onLoginSuccess()
            } catch {
                withAnimation {
                    phase = .idle
                    errorMessage = "無法連線到伺服器，請確認網路"
                }
            }
        }
    }
}

struct FeatureSlide: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    /// true = 顯示箭頭、可點（你之後若要做跳轉/展開用）
    /// false = 不顯示箭頭、不可點
    let isActionable: Bool
}


struct FeatureSlideCard: View {
    let slide: FeatureSlide

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(slide.tint.opacity(0.18))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 0.7)

                Image(systemName: slide.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(slide.tint)
            }
            .frame(width: 52, height: 52)
            .layoutPriority(1)

            VStack(alignment: .leading, spacing: 6) {
                Text(slide.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(slide.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2)

            if slide.isActionable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.18))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 0.7)
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        // 不可點就完全不要手勢（避免暗示）
        .onTapGesture {
            guard slide.isActionable else { return }
            // TODO: 之後你要點擊開啟對應介紹/跳頁，在這裡做
        }
    }
}


// MARK: - Noise Overlay（顆粒質感）

struct NoiseOverlay: View {
    var opacity: Double = 0.05

    var body: some View {
        Rectangle()
            .fill(.white.opacity(opacity))
            .blendMode(.overlay)
    }
}

// MARK: - 滑動Card
struct FeatureCarousel: View {
    let slides: [FeatureSlide]

    @State private var index: Int = 0
    @State private var isUserInteracting: Bool = false

    // 自動輪播間隔
    private let interval: TimeInterval = 3.2
    // 使用者手動滑動後，暫停多久再繼續自動輪播
    private let resumeDelay: UInt64 = 2_500_000_000

    var body: some View {
        ZStack {
            // TabView
            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                    FeatureSlideCard(slide: slide)
                        .tag(i)
                        .padding(.horizontal, 2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 118)
            .clipped()

            // 左右側指示/按鈕（明顯、可點）
            HStack {
                sideButton(direction: .prev)
                Spacer()
                sideButton(direction: .next)
            }
            .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            pageDots
                .padding(.bottom, 4)
        }
        .task {
            await autoScrollLoop()
        }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in
                    isUserInteracting = true
                }
                .onEnded { _ in
                    // 手動滑完先暫停，之後再恢復自動輪播
                    Task {
                        try? await Task.sleep(nanoseconds: resumeDelay)
                        isUserInteracting = false
                    }
                }
        )
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<slides.count, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i == index ? 0.55 : 0.18))
                    .frame(width: i == index ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Side Buttons

    private enum Direction { case prev, next }

    private func sideButton(direction: Direction) -> some View {
        let isPrev = (direction == .prev)
        let systemName = isPrev ? "chevron.left" : "chevron.right"

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                step(isPrev ? -1 : 1)
            }
            // 點了就當作使用者互動，暫停自動輪播一段
            isUserInteracting = true
            Task {
                try? await Task.sleep(nanoseconds: resumeDelay)
                isUserInteracting = false
            }
        } label: {
            ZStack {
                // 玻璃底
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.6))
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 6)

                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.80))
            }
            .frame(width: 34, height: 34)
            .opacity(slides.count <= 1 ? 0.0 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(slides.count <= 1)
        .accessibilityLabel(isPrev ? "上一個功能" : "下一個功能")
    }

    // MARK: - Auto Scroll

    private func autoScrollLoop() async {
        guard slides.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            if isUserInteracting { continue }
            await MainActor.run {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    step(1)
                }
            }
        }
    }

    private func step(_ delta: Int) {
        let n = slides.count
        guard n > 0 else { return }
        index = (index + delta + n) % n
    }
}
