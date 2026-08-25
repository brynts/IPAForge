import SwiftUI
import UniformTypeIdentifiers

struct AddCertificateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = CertificateManager.shared
    
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var p12URL: URL?
    @State private var provisionURL: URL?
    
    @State private var showP12Picker = false
    @State private var showProvisionPicker = false
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        p12URL != nil &&
        provisionURL != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Certificate Name", text: $name)
                    SecureField("Password (optional)", text: $password)
                } header: {
                    Text("Info")
                }
                
                Section {
                    Button {
                        showP12Picker = true
                    } label: {
                        HStack {
                            Text("Certificate (.p12)")
                            Spacer()
                            Text(p12URL?.lastPathComponent ?? "Select")
                                .foregroundStyle(p12URL == nil ? .secondary : .primary)
                                .lineLimit(1)
                        }
                    }
                    
                    Button {
                        showProvisionPicker = true
                    } label: {
                        HStack {
                            Text("Provisioning Profile")
                            Spacer()
                            Text(provisionURL?.lastPathComponent ?? "Select")
                                .foregroundStyle(provisionURL == nil ? .secondary : .primary)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("Files")
                } footer: {
                    Text("Select both .p12 and .mobileprovision files.")
                }
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .fileImporter(
                isPresented: $showP12Picker,
                allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result {
                    p12URL = urls.first
                    if name.isEmpty, let fileName = urls.first?.deletingPathExtension().lastPathComponent {
                        name = fileName
                    }
                }
            }
            .fileImporter(
                isPresented: $showProvisionPicker,
                allowedContentTypes: [UTType(filenameExtension: "mobileprovision") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result {
                    provisionURL = urls.first
                }
            }
        }
    }
    
    private func save() {
        guard let p12 = p12URL, let provision = provisionURL else { return }
        
        let cert = Certificate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            p12FileName: p12.lastPathComponent,
            mobileProvisionFileName: provision.lastPathComponent,
            password: password.isEmpty ? nil : password
        )
        
        // TODO: Actually copy files to app container & parse provision for team/expiration
        manager.add(cert)
        dismiss()
    }
}

#Preview {
    AddCertificateView()
}
