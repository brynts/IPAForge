import SwiftUI

struct SignView: View {
    // Placeholder data
    @State private var unsignedIPAs: [String] = []
    @State private var signedIPAs: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Unsigned IPAs
                Section {
                    if unsignedIPAs.isEmpty {
                        Text("No unsigned IPAs")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(unsignedIPAs, id: \.self) { ipa in
                            Text(ipa)
                        }
                    }
                } header: {
                    Text("Unsigned IPA")
                }
                
                // MARK: - Signed IPAs
                Section {
                    if signedIPAs.isEmpty {
                        Text("No signed IPAs")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(signedIPAs, id: \.self) { ipa in
                            Text(ipa)
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
                            // TODO: Add from Files
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
                }
            }
        }
    }
}

#Preview {
    SignView()
}
