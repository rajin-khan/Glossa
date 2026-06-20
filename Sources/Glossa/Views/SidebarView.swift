import SwiftUI

struct SidebarView: View {
    @Binding var selection: WorkspaceSection?
    @ObservedObject var store: GlossaStore

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(WorkspaceSection.allCases) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Glossa")
        .safeAreaInset(edge: .top) {
            HStack(spacing: 10) {
                GlossaAppIconView(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Glossa")
                        .font(.callout.weight(.semibold))
                    Text("Speech carried as captions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                GlossaMarkView(size: 24)
                    .opacity(0.76)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Local & Private")
                        .font(.caption.weight(.semibold))
                    Text("Audio is never stored")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
        }
        .preferredColorScheme(.dark)
    }
}
