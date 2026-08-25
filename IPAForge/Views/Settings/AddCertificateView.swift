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
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        p12URL != nil &&
        provisionURL != nil &&
        !isSaving
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Certificate Name", text: $name)
                    SecureField("Password", text: $password)
                } header: {
                    Text("Info")
                } footer: {
                    Text("Password is required if your .p12 is encrypted.")
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
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            save()
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .fileImporter(
                isPresented: $showP12Picker,
                allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleP12Pick(result)
            }
            .fileImporter(
                isPresented: $showProvisionPicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "mobileprovision") ?? .data
                ],
                allowsMultipleSelection: false
            ) { result in
                handleProvisionPick(result)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleP12Pick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            p12URL = url
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = url.deletingPathExtension().lastPathComponent
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleProvisionPick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            provisionURL = urls.first
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func save() {
        guard let p12 = p12URL, let provision = provisionURL else { return }
        
        isSaving = true
        
        Task {
            do {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let pwd = password.isEmpty ? nil : password
                
                _ = try manager.add(
                    name: trimmedName,
                    p12SourceURL: p12,
                    provisionSourceURL: provision,
                    password: pwd
                )
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }
}

#Preview {
    AddCertificateView()
}
