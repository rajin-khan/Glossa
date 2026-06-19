import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: GlossaStore
    @State private var selection: WorkspaceSection? = .live

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, store: store)
        } detail: {
            switch selection ?? .live {
            case .live:
                MainPanelView(store: store)
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
            await store.refreshPermissions()
            store.handleLaunchArguments(ProcessInfo.processInfo.arguments)
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
