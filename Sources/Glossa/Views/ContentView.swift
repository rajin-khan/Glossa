import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
        } detail: {
            MainPanelView(store: store)
        }
        .background(.regularMaterial)
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
