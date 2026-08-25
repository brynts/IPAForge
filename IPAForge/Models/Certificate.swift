import Foundation

struct Certificate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    
    /// Folder name inside Documents/Certificates/{id}/
    var p12FileName: String
    var mobileProvisionFileName: String
    
    var password: String?
    var teamName: String?
    var teamIdentifier: String?
    var expirationDate: Date?
    var isSelected: Bool
    var createdAt: Date
    
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        p12FileName: String,
        mobileProvisionFileName: String,
        password: String? = nil,
        teamName: String? = nil,
        teamIdentifier: String? = nil,
        expirationDate: Date? = nil,
        isSelected: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.p12FileName = p12FileName
        self.mobileProvisionFileName = mobileProvisionFileName
        self.password = password
        self.teamName = teamName
        self.teamIdentifier = teamIdentifier
        self.expirationDate = expirationDate
        self.isSelected = isSelected
        self.createdAt = createdAt
    }
}
