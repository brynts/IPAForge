import SwiftUI

struct SettingsView: View {
    @StateObject private var certificateManager = CertificateManager.shared
    @State private var showAddCertificate = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Certificates
                Section {
                    if certificateManager.certificates.isEmpty {
                        Text("No Certificates")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(certificateManager.certificates) { cert in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cert.name)
                                    if let team = cert.teamName {
                                        Text(team)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if cert.isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                certificateManager.select(cert)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                certificateManager.remove(certificateManager.certificates[index])
                            }
                        }
                    }
                    
                    Button {
                        showAddCertificate = true
                    } label: {
                        Label("Add Certificate", systemImage: "plus")
                    }
                } header: {
                    Text("Certificates")
                } footer: {
                    Text("Select a certificate to use for signing.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddCertificate) {
                AddCertificateView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
