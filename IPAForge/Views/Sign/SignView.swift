import SwiftUI
import UniformTypeIdentifiers

struct SignView: View {
    @StateObject private var library = IPALibrary.shared
    @StateObject private var certs = CertificateManager.shared
    
    @State private var showIPAPicker = false
    @State private var isBusy = false
    @State private var busyMessage = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var iconCache: [URL: UIImage] = [:]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if library.unsigned.isEmpty {
                        Text("No unsigned IPAs")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                    } else {
                        ForEach(library.unsigned) { item in
                            ipaRow(item)
                        }
                        .onDelete { indexSet in
                            delete(items: library.unsigned, at: indexSet)
                        }
                    }
                } header: {
                    Text("Unsigned IPA")
                }
                
                Section {
                    if library.signed.isEmpty {
                        Text("No signed IPAs")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                    } else {
                        ForEach(library.signed) { item in
                            ipaRow(item)
                        }
                        .onDelete { indexSet in
                            delete(items: library.signed, at: indexSet)
                        }
                    }
                } header: {
                    Text("Signed IPA")
                }
            }
            .navigationTitle("Sign")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showIPAPicker = true
                        } label: {
                            Label("Add from Files", systemImage: "folder")
                        }
                        
                        Button {
                            // TODO: Add from URL
                        } label: {
                            Label("Add from URL", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isBusy)
                }
            }
            .sheet(isPresented: $showIPAPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.ipa]
                ) { urls in
                    guard let url = urls.first else { return }
                    importIPA(url)
                }
                .ignoresSafeArea()
            }
            .overlay {
                if isBusy {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(busyMessage)
                                .font(.subheadline)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .onAppear {
                library.refresh()
                loadMissingIcons()
            }
            .onChange(of: library.unsigned.count) { _, _ in
                loadMissingIcons()
            }
            .onChange(of: library.signed.count) { _, _ in
                loadMissingIcons()
            }
        }
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func ipaRow(_ item: IPAItem) -> some View {
        HStack(spacing: 12) {
            appIcon(for: item.url)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text(item.url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !item.isSigned {
                Button("Sign") {
                    sign(item)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isBusy || certs.selectedCertificate == nil)
            }
        }
    }
    
    @ViewBuilder
    private func appIcon(for url: URL) -> some View {
        if let image = iconCache[url] {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
                .overlay {
                    Image(systemName: "app.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }
    
    // MARK: - Actions
    
    private func loadMissingIcons() {
        let all = library.unsigned + library.signed
        for item in all where iconCache[item.url] == nil {
            Task.detached(priority: .utility) {
                let image = IPAIconLoader.loadIcon(from: item.url)
                await MainActor.run {
                    if let image {
                        iconCache[item.url] = image
                    }
                }
            }
        }
    }
    
    private func importIPA(_ url: URL) {
        isBusy = true
        busyMessage = "Importing…"
        Task {
            do {
                try library.importFromFiles(url: url)
                loadMissingIcons()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isBusy = false
        }
    }
    
    private func sign(_ item: IPAItem) {
        guard certs.selectedCertificate != nil else {
            errorMessage = "Select a certificate in Settings first."
            showError = true
            return
        }
        
        isBusy = true
        busyMessage = "Extracting…"
        
        Task {
            var workDir: URL?
            do {
                let archive = IPAArchiveService.shared
                let extracted = try archive.extractApp(from: item.url)
                workDir = extracted.workDir
                
                busyMessage = "Signing…"
                try await SigningService.shared.sign(appURL: extracted.appURL)
                
                busyMessage = "Packing…"
                let outputName = item.name + "-signed"
                _ = try archive.packIPA(workDir: extracted.workDir, outputName: outputName)
                
                archive.removeWorkDir(extracted.workDir)
                workDir = nil
                library.refresh()
                loadMissingIcons()
            } catch {
                if let workDir {
                    IPAArchiveService.shared.removeWorkDir(workDir)
                }
                errorMessage = error.localizedDescription
                showError = true
            }
            isBusy = false
        }
    }
    
    private func delete(items: [IPAItem], at offsets: IndexSet) {
        for index in offsets {
            try? library.delete(items[index])
        }
    }
}

#Preview {
    SignView()
}
