import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: GlossaStore
    @State private var selection: WorkspaceSection? = .live
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, store: store)
        } detail: {
            switch selection ?? .live {
            case .live:
                MainPanelView(store: store)
            case .appearance:
                AppearanceSettingsView(store: store)
            case .transcript:
                TranscriptHistoryView(store: store)
            }
        }
        .overlay(alignment: .topLeading) {
            if #available(macOS 15.0, *) {
                AppleTranslationHostView(broker: store.translationBroker)
            }
        }
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            await store.refreshPermissions()
            await store.refreshAvailableTargetLanguages()
            store.prepareCachedLocalModel()
            store.handleLaunchArguments(arguments)
            if arguments.contains("--open-settings") {
                openSettings()
            }
            if #unavailable(macOS 15.0) {
                store.translationBroker.markUnavailable("Translation requires macOS 15")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await store.refreshPermissions()
            }
        }
    }
}
