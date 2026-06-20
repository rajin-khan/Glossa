import SwiftUI

@main
struct GlossaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = GlossaStore()

    var body: some Scene {
        WindowGroup("Glossa", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 860, minHeight: 580)
                .onAppear {
                    appDelegate.configure(store: store)
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
        }

        Settings {
            SettingsView(store: store)
        }

        MenuBarExtra {
            MenuBarContent(store: store)
        } label: {
            Label("Glossa", systemImage: store.isListening ? "captions.bubble.fill" : "captions.bubble")
        }
        .menuBarExtraStyle(.menu)
    }
}
