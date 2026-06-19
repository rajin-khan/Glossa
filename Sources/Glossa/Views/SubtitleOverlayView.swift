import SwiftUI

struct SubtitleOverlayView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        SubtitleCard(segment: store.currentSubtitle)
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
    }
}
