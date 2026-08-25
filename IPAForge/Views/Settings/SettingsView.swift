import SwiftUI

struct SettingsView: View {
    // Placeholder
    @State private var certificates: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Certificates
                Section {
                    if certificates.isEmpty {
                        Text("No Certificates")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(certificates, id: \.self) { cert in
                            Text(cert)
                        }
                    }
                    
                    NavigationLink {
                        // TODO: Certificates management view
                        Text("Manage Certificates")
                    } label: {
                        Text("Manage Certificates")
                    }
                } header: {
                    Text("Certificates")
                }
                
                // Future sections can go here
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: Add Certificate
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
