import Foundation

struct Certificate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var p12FileName: String
    var mobileProvisionFileName: String
    var password: String?          // stored securely later (Keychain)
    var teamName: String?
    var expirationDate: Date?
    var isSelected: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        p12FileName: String,
        mobileProvisionFileName: String,
        password: String? = nil,
        teamName: String? = nil,
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
        self.expirationDate = expirationDate
        self.isSelected = isSelected
        self.createdAt = createdAt
    }
}
