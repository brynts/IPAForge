import Foundation

struct Certificate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    
    var p12FileName: String
    var mobileProvisionFileName: String
    
    var password: String?
    var teamName: String?
    var teamIdentifier: String?
    var appIDName: String?
    var provisionName: String?
    var creationDate: Date?
    var expirationDate: Date?
    var ppqCheck: Bool?
    var isSelected: Bool
    var createdAt: Date
    
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
    
    /// Days remaining until expiry (negative if expired).
    var daysRemaining: Int? {
        guard let expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        p12FileName: String,
        mobileProvisionFileName: String,
        password: String? = nil,
        teamName: String? = nil,
        teamIdentifier: String? = nil,
        appIDName: String? = nil,
        provisionName: String? = nil,
        creationDate: Date? = nil,
        expirationDate: Date? = nil,
        ppqCheck: Bool? = nil,
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
        self.appIDName = appIDName
        self.provisionName = provisionName
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.ppqCheck = ppqCheck
        self.isSelected = isSelected
        self.createdAt = createdAt
    }
}
