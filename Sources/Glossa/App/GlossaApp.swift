import SwiftUI

@main
struct GlossaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = GlossaStore()

    var body: some Scene {
        WindowGroup("Glossa", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 820, minHeight: 560)
                .onAppear {
                    appDelegate.configure(store: store)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 920, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Glossa") {
                Button(store.isListening ? "Pause Listening" : "Start Listening") {
                    store.toggleListening()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])

                Button("Show Subtitle Overlay") {
                    appDelegate.overlayController.show()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView(store: store)
                .frame(width: 520)
        }

        MenuBarExtra {
            MenuBarContent(store: store, overlayController: appDelegate.overlayController)
        } label: {
            Label("Glossa", systemImage: store.isListening ? "captions.bubble.fill" : "captions.bubble")
        }
        .menuBarExtraStyle(.menu)
    }
}
