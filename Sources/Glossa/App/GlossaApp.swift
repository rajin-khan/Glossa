import SwiftUI

@main
struct GlossaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = GlossaStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingOnboarding = false

    var body: some Scene {
        WindowGroup("Glossa", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 860, minHeight: 580)
                .preferredColorScheme(.dark)
                .onAppear {
                    appDelegate.configure(store: store)
                    showOnboardingIfNeeded()
                }
                .sheet(isPresented: $isShowingOnboarding, onDismiss: {
                    hasCompletedOnboarding = true
                }) {
                    OnboardingView(store: store) {
                        hasCompletedOnboarding = true
                        isShowingOnboarding = false
                    }
                    .preferredColorScheme(.dark)
                }
        }
        .defaultSize(width: 960, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Glossa") {
                Button(store.isListening ? "Pause Listening" : "Start Listening") {
                    store.toggleListening()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])

                Button(store.overlayVisible ? "Hide Subtitle Overlay" : "Show Subtitle Overlay") {
                    store.toggleOverlay()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(after: .help) {
                Button("Show Glossa Onboarding") {
                    isShowingOnboarding = true
                }
            }
        }

        Settings {
            SettingsView(store: store)
                .preferredColorScheme(.dark)
        }
    }

    private func showOnboardingIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isShowingOnboarding = true
        }
    }
}
