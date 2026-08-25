import Foundation

struct IPAItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var url: URL
    var isSigned: Bool
    var importedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        isSigned: Bool,
        importedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isSigned = isSigned
        self.importedAt = importedAt
    }
}
