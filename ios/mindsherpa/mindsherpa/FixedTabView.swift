import SwiftUI
import UIKit

/// A TabView wrapper that ensures the tab bar has a solid background on iOS 15+
struct FixedTabView<Selection, Content>: View where Selection: Hashable, Content: View {
    @Binding var selection: Selection
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                TabView(selection: $selection) {
                    content()
                }
                .toolbarBackground(Color(.systemBackground), for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
            } else {
                TabView(selection: $selection) {
                    content()
                }
            }
        }
        .onAppear(perform: configureAppearance)
    }

    private func configureAppearance() {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UITabBar.appearance().barTintColor = UIColor.systemBackground
            UITabBar.appearance().isTranslucent = false
        }
    }
}
