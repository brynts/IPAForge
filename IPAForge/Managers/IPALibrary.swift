import Foundation
import Combine

@MainActor
final class IPALibrary: ObservableObject {
    static let shared = IPALibrary()
    
    @Published var unsigned: [IPAItem] = []
    @Published var signed: [IPAItem] = []
    
    private let archive = IPAArchiveService.shared
    private let fileManager = FileManager.default
    
    private init() {
        refresh()
    }
    
    func refresh() {
        unsigned = loadIPAs(in: archive.unsignedDirectory, signed: false)
        signed = loadIPAs(in: archive.signedDirectory, signed: true)
    }
    
    private func loadIPAs(in directory: URL, signed: Bool) -> [IPAItem] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        return urls
            .filter { $0.pathExtension.lowercased() == "ipa" }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                return IPAItem(
                    name: url.deletingPathExtension().lastPathComponent,
                    url: url,
                    isSigned: signed,
                    importedAt: date
                )
            }
            .sorted { $0.importedAt > $1.importedAt }
    }
    
    func importFromFiles(url: URL) throws {
        _ = try archive.importUnsignedIPA(from: url)
        refresh()
    }
    
    func delete(_ item: IPAItem) throws {
        try fileManager.removeItem(at: item.url)
        refresh()
    }
}
