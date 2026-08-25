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
                            certificateRow(cert)
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
    
    @ViewBuilder
    private func certificateRow(_ cert: Certificate) -> some View {
        let check = certificateManager.check(cert)
        
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cert.name)
                
                HStack(spacing: 6) {
                    if let team = cert.teamName {
                        Text(team)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if check != .ok {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(check.message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let exp = cert.expirationDate {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(exp, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
}

#Preview {
    SettingsView()
}
