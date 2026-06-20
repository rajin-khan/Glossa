import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: GlossaStore
    @State private var selection = SettingsTab.launchSelection

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView(store: store)
                .tag(SettingsTab.general)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsView(store: store)
                .tag(SettingsTab.appearance)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            PrivacySettingsView(store: store)
                .tag(SettingsTab.privacy)
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 620, height: 540)
        .padding(.top, 8)
    }
}

private enum SettingsTab: String {
    case general
    case appearance
    case privacy

    static var launchSelection: SettingsTab {
        let prefix = "--settings-tab="
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) }),
              let tab = SettingsTab.resolve(String(argument.dropFirst(prefix.count)))
        else {
            return .general
        }
        return tab
    }

    private static func resolve(_ rawValue: String) -> SettingsTab? {
        if rawValue == "overlay" {
            return .appearance
        }
        return SettingsTab(rawValue: rawValue)
    }
}
