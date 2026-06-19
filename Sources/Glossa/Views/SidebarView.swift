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
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.teal)
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
    }
}
