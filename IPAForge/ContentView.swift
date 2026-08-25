import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SignView()
                .tabItem {
                    Label("Sign", systemImage: "signature")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
