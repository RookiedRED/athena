import SwiftUI
import Combine

// MARK: - 模型下載畫面

struct ModelDownloadView: View {

    private let downloadURL = URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf")!

    @StateObject private var downloader = ModelDownloader()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#050508")!, Color(hex: "#0D1829")!, Color(hex: "#050508")!],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 100, height: 100)
                    Image(systemName: "brain")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 32)

                // 標題
                VStack(spacing: 10) {
                    Text("Athena")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("需要下載 AI 模型才能啟動")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("下載後完全離線使用")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.bottom, 52)

                // 進度區域
                if downloader.isDownloading || downloader.isProcessing {
                    VStack(spacing: 16) {

                        // 進度條
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)

                                if downloader.isProcessing {
                                    ProcessingBar(width: geo.size.width)
                                } else {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#0A84FF")!, Color(hex: "#30D158")!],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geo.size.width * CGFloat(downloader.progress),
                                            height: 4
                                        )
                                        .animation(.easeInOut(duration: 0.2), value: downloader.progress)
                                }
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 40)

                        // 狀態文字
                        HStack {
                            if downloader.isProcessing {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .tint(.white.opacity(0.5))
                                        .scaleEffect(0.7)
                                    Text(downloader.statusText)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Spacer()
                            } else {
                                Text(downloader.progressText)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.45))
                                Spacer()
                                Text(downloader.isProcessing ? "…" : "\(min(Int(downloader.progress * 100), 95))%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }

                // 錯誤訊息
                if let error = downloader.errorMessage {
                    VStack(spacing: 8) {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#FF453A")!)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 8)
                }

                // 按鈕（只在非下載/處理中顯示）
                if !downloader.isDownloading && !downloader.isProcessing {
                    Button {
                        downloader.start(from: downloadURL, onComplete: onComplete)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: downloader.errorMessage == nil ? "arrow.down.circle" : "arrow.clockwise")
                            Text(downloader.errorMessage == nil ? "開始下載" : "重試")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 52)
                        .background(Color(hex: "#0A84FF")!)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
        }
    }
}

// MARK: - 跑馬燈

struct ProcessingBar: View {
    let width: CGFloat
    @State private var offset: CGFloat = -80

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [.clear, Color(hex: "#0A84FF")!, .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(width: 80, height: 4)
            .offset(x: offset)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    offset = width + 80
                }
            }
    }
}

// MARK: - nonisolated 路徑輔助

private func modelFileURL() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(LLMWrapper.modelFileName)
}

// MARK: - 下載管理器

@MainActor
class ModelDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {

    @Published var progress: Double = 0
    @Published var isDownloading = false
    @Published var isProcessing = false
    @Published var statusText = "寫入中，請稍候…"
    @Published var errorMessage: String? = nil
    
    private var receivedBytes: Int64 = 0
    private var totalBytes: Int64 = 0
    private var didCallComplete = false
    
    var progressText: String {
        let received = Double(receivedBytes) / 1_048_576
        if totalBytes > 0 {
            let total = Double(totalBytes) / 1_048_576
            return String(format: "%.1f MB / %.1f MB", received, total)
        }
        return String(format: "%.1f MB / 計算中…", received)
    }

    private var onComplete: (() -> Void)?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func start(from url: URL, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        didCallComplete = false
        isDownloading = true
        isProcessing = false
        errorMessage = nil
        progress = 0
        receivedBytes = 0
        totalBytes = 0
        session.downloadTask(with: url).resume()
    }

    // MARK: - URLSessionDownloadDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            self.receivedBytes = totalBytesWritten
            if totalBytesExpectedToWrite > 0 {
                self.totalBytes = totalBytesExpectedToWrite
                // 最多到 95%，留空間給寫入階段
                self.progress = min(
                    Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 0.95,
                    0.95
                )
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // 先讓 UI 立刻進入「寫入中」
        Task { @MainActor in
            self.isDownloading = false
            self.isProcessing = true
            self.progress = min(self.progress, 0.95) // 保險
        }

        let destination = modelFileURL()

        Task.detached(priority: .userInitiated) { [location] in
            do {
                // 這段在背景做檔案操作
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)

                let attrs = try FileManager.default.attributesOfItem(atPath: destination.path)
                let fileSize = attrs[.size] as? Int64 ?? 0
                guard fileSize > 1_000_000 else {
                    throw NSError(domain: "Athena", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "檔案不完整"])
                }

                // ✅ 檔案真的 OK 了，才回主執行緒收尾 + 跳轉
                await MainActor.run {
                    self.progress = 1.0
                    self.isProcessing = false
                }
                
                try? await Task.sleep(nanoseconds: 300_000_000)

                await MainActor.run {
                    if !self.didCallComplete {
                        self.didCallComplete = true
                        self.onComplete?()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = "儲存失敗：\(error.localizedDescription)"
                }
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        // 忽略正常完成後的 nil error callback
        Task { @MainActor in
            if self.isProcessing { return }  // 寫入中，不要蓋掉
            self.isDownloading = false
            self.errorMessage = "下載失敗：\(error.localizedDescription)"
        }
    }
}
