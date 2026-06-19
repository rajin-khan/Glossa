import SwiftUI

struct TranscriptHistoryView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Group {
            if store.recentSegments.isEmpty {
                ContentUnavailableView(
                    "No Transcript Yet",
                    systemImage: "text.alignleft",
                    description: Text("Start listening and translated lines will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.recentSegments.reversed().enumerated()), id: \.element.id) { index, segment in
                            TranscriptRow(segment: segment, showsTimestamp: true)
                                .padding(.vertical, 4)
                            if index < store.recentSegments.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Transcript")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    copyTranscript()
                } label: {
                    Label("Copy Transcript", systemImage: "doc.on.doc")
                }
                .disabled(store.recentSegments.isEmpty)

                Button(role: .destructive) {
                    store.clearTranscript()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(store.recentSegments.isEmpty)
            }
        }
    }

    private func copyTranscript() {
        let text = store.recentSegments
            .map { "\($0.translatedText)\n\($0.sourceText)" }
            .joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
