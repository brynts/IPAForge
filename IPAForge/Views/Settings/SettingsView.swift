import SwiftUI

struct SettingsView: View {
    @StateObject private var certificateManager = CertificateManager.shared
    @State private var showAddCertificate = false
    
    var body: some View {
        NavigationStack {
            List {
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
        
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cert.name)
                    .font(.body.weight(.medium))
                
                if let team = cert.teamName {
                    Text(team)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Status line: Valid/Expired • Expires in Xd • PPQ
                HStack(spacing: 6) {
                    statusBadge(check: check, cert: cert)
                    
                    if let days = cert.daysRemaining, check == .ok {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(days == 0 ? "Expires today" : "\(days)d left")
                            .font(.caption2)
                            .foregroundStyle(days <= 7 ? .orange : .secondary)
                    }
                    
                    if let ppq = cert.ppqCheck {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(ppq ? "PPQ" : "No PPQ")
                            .font(.caption2)
                            .foregroundStyle(ppq ? .orange : .secondary)
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
    
    @ViewBuilder
    private func statusBadge(check: CertificateCheckResult, cert: Certificate) -> some View {
        switch check {
        case .ok:
            Text("Valid")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
        case .expired:
            Text("Expired")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
        case .missingFiles:
            Text("Files missing")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
        case .wrongPassword:
            Text("Wrong password")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
        case .invalidP12:
            Text("Invalid .p12")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    SettingsView()
}
