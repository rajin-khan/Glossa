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
    }
}
