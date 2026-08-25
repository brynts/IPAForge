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
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
                        Label("Add Certificate", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Certificates")
                } footer: {
                    Text("Select a certificate to use for signing.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddCertificate) {
                AddCertificateView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ViewBuilder
    private func certificateRow(_ cert: Certificate) -> some View {
        let check = certificateManager.check(cert)
        
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(cert.name)
                    .font(.body.weight(.medium))
                
                if let team = cert.teamName {
                    Text(team)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 6) {
                    statusPill(check: check)
                    agePill(cert: cert)
                    ppqPill(cert: cert)
                }
            }
            
            Spacer(minLength: 0)
            
            if cert.isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .padding(.top, 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            certificateManager.select(cert)
        }
    }
    
    // MARK: - Pills
    
    private func statusPill(check: CertificateCheckResult) -> some View {
        let text: String
        let color: Color
        switch check {
        case .ok:
            text = "Valid"
            color = .green
        case .expired:
            text = "Expired"
            color = .red
        case .missingFiles:
            text = "Files missing"
            color = .red
        case .wrongPassword:
            text = "Wrong password"
            color = .red
        case .invalidP12:
            text = "Invalid .p12"
            color = .red
        }
        return Pill(text: text, color: color)
    }
    
    private func agePill(cert: Certificate) -> some View {
        if let days = cert.daysRemaining {
            if days < 0 {
                return Pill(text: "Expired \(abs(days))d ago", color: .red)
            } else if days == 0 {
                return Pill(text: "Expires today", color: .yellow)
            } else {
                return Pill(text: "\(days)d left", color: .yellow)
            }
        } else if let exp = cert.expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return Pill(text: formatter.string(from: exp), color: .yellow)
        } else {
            return Pill(text: "Age unknown", color: .secondary)
        }
    }
    
    private func ppqPill(cert: Certificate) -> some View {
        if let ppq = cert.ppqCheck, ppq {
            return Pill(text: "PPQ", color: .red)
        } else {
            return Pill(text: "Not PPQ", color: .green)
        }
    }
}

// MARK: - Pill UI

private struct Pill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    SettingsView()
}
