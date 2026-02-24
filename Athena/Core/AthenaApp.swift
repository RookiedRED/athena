import SwiftUI

@main
struct AthenaApp: App {

    @StateObject private var appState = AppState()

    @State private var isLoggedIn = false
    @State private var modelExists: Bool = {
        FileManager.default.fileExists(atPath: LLMWrapper.modelURL.path)
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !isLoggedIn {
                    LoginView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLoggedIn = true
                        }
                    }
                } else if !modelExists {
                    ModelDownloadView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            modelExists = true
                        }
                        Task { await appState.initialize() }
                    }
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .onAppear {
                            Task { await appState.initialize() }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
            .animation(.easeInOut(duration: 0.5), value: modelExists)
            .task {
                #if DEBUG
                TokenManager.clear()
                #endif
                isLoggedIn = TokenManager.isValid
            }
        }
    }
}
