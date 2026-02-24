//
//  SettingsView.swift
//  Athena
//
//  Created by Lin, Hung Yu on 2/23/26.
//

import SwiftUI

// MARK: - 設定頁面
// 前端只需要管理後台連線狀態，所有 API Key 都在 VPS 的 .env

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var isCheckingServer = false
    @State private var serverChecked    = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#050508")!, Color(hex: "#0D1829")!, Color(hex: "#050508")!],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // 頂部列
                HStack {
                    Text("設定")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .overlay(Divider().opacity(0.4), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 24) {

                        // 後台連線狀態
                        SettingsSection(title: "後台伺服器") {
                            VStack(spacing: 0) {

                                // 狀態列
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(appState.serverStatus.color.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "server.rack")
                                            .font(.system(size: 18))
                                            .foregroundStyle(appState.serverStatus.color)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Athena Server")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text(appState.serverStatus.label)
                                            .font(.system(size: 13))
                                            .foregroundStyle(appState.serverStatus.color)
                                    }

                                    Spacer()

                                    // 狀態指示燈
                                    Circle()
                                        .fill(appState.serverStatus.color)
                                        .frame(width: 8, height: 8)
                                }
                                .padding(16)

                                Divider().background(Color.white.opacity(0.07)).padding(.leading, 16)

                                // 重新連線按鈕
                                Button {
                                    Task { await checkServer() }
                                } label: {
                                    HStack {
                                        if isCheckingServer {
                                            ProgressView()
                                                .tint(.white)
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                        }
                                        Text(isCheckingServer ? "連線中…" : "重新檢查連線")
                                            .font(.system(size: 15))
                                    }
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(14)
                                }
                                .disabled(isCheckingServer)
                            }
                        }

                        // 裝置資訊
                        SettingsSection(title: "裝置") {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("裝置 ID")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                    Text(TokenManager.deviceId)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.3))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                // 複製按鈕
                                Button {
                                    UIPasteboard.general.string = TokenManager.deviceId
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }
                            .padding(16)
                        }

                        // Token 狀態
                        SettingsSection(title: "認證") {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("JWT Token")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                    if let exp = TokenManager.expiresAt {
                                        Text("到期：\(exp.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.35))
                                    } else {
                                        Text("尚未取得")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "#FF9F0A")!)
                                    }
                                }
                                Spacer()
                                Circle()
                                    .fill(TokenManager.isValid ? Color(hex: "#30D158")! : Color(hex: "#FF453A")!)
                                    .frame(width: 8, height: 8)
                            }
                            .padding(16)
                        }

                        // 說明
                        VStack(alignment: .leading, spacing: 8) {
                            Label("安全說明", systemImage: "lock.shield")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("所有 API Key 存放在後台伺服器，不會出現在裝置上。裝置透過 JWT Token 與後台安全通訊。")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.3))
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func checkServer() async {
        isCheckingServer = true
        await appState.initialize()
        isCheckingServer = false
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}

// MARK: - Section 容器

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(0.8)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
    }
}
