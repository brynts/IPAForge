import Foundation
import Combine

@MainActor
class CertificateManager: ObservableObject {
    static let shared = CertificateManager()
    
    @Published var certificates: [Certificate] = []
    
    private let saveKey = "ipaforge.certificates"
    private let fileManager = FileManager.default
    
    private var certificatesDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Certificates", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {
        load()
    }
    
    var selectedCertificate: Certificate? {
        certificates.first(where: { $0.isSelected })
    }
    
    // MARK: - Paths
    
    func folderURL(for certificate: Certificate) -> URL {
        certificatesDirectory.appendingPathComponent(certificate.id.uuidString, isDirectory: true)
    }
    
    func p12URL(for certificate: Certificate) -> URL {
        folderURL(for: certificate).appendingPathComponent(certificate.p12FileName)
    }
    
    func provisionURL(for certificate: Certificate) -> URL {
        folderURL(for: certificate).appendingPathComponent(certificate.mobileProvisionFileName)
    }
    
    // MARK: - Add / Remove / Select
    
    /// Copy files into app container, parse provision, then save.
    func add(
        name: String,
        p12SourceURL: URL,
        provisionSourceURL: URL,
        password: String?
    ) throws -> Certificate {
        let id = UUID()
        let folder = certificatesDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        
        // Need security-scoped access for files picked from Files app
        let p12Access = p12SourceURL.startAccessingSecurityScopedResource()
        let provisionAccess = provisionSourceURL.startAccessingSecurityScopedResource()
        defer {
            if p12Access { p12SourceURL.stopAccessingSecurityScopedResource() }
            if provisionAccess { provisionSourceURL.stopAccessingSecurityScopedResource() }
        }
        
        let p12Name = p12SourceURL.lastPathComponent
        let provisionName = provisionSourceURL.lastPathComponent
        
        let destP12 = folder.appendingPathComponent(p12Name)
        let destProvision = folder.appendingPathComponent(provisionName)
        
        try fileManager.copyItem(at: p12SourceURL, to: destP12)
        try fileManager.copyItem(at: provisionSourceURL, to: destProvision)
        
        // Parse mobileprovision
        let info = try parseMobileProvision(at: destProvision)
        
        var cert = Certificate(
            id: id,
            name: name,
            p12FileName: p12Name,
            mobileProvisionFileName: provisionName,
            password: password,
            teamName: info.teamName,
            teamIdentifier: info.teamIdentifier,
            expirationDate: info.expirationDate,
            isSelected: certificates.isEmpty
        )
        
        certificates.append(cert)
        save()
        return cert
    }
    
    func remove(_ certificate: Certificate) {
        let folder = folderURL(for: certificate)
        try? fileManager.removeItem(at: folder)
        
        certificates.removeAll { $0.id == certificate.id }
        
        if selectedCertificate == nil, let first = certificates.first {
            select(first)
        }
        save()
    }
    
    func select(_ certificate: Certificate) {
        for i in certificates.indices {
            certificates[i].isSelected = (certificates[i].id == certificate.id)
        }
        save()
    }
    
    /// Basic check: files still exist + not expired
    func check(_ certificate: Certificate) -> CertificateCheckResult {
        let p12Exists = fileManager.fileExists(atPath: p12URL(for: certificate).path)
        let provisionExists = fileManager.fileExists(atPath: provisionURL(for: certificate).path)
        
        if !p12Exists || !provisionExists {
            return .missingFiles
        }
        if certificate.isExpired {
            return .expired
        }
        return .ok
    }
    
    // MARK: - Parse mobileprovision
    
    private struct ProvisionInfo {
        var teamName: String?
        var teamIdentifier: String?
        var expirationDate: Date?
    }
    
    private func parseMobileProvision(at url: URL) throws -> ProvisionInfo {
        let data = try Data(contentsOf: url)
        
        // mobileprovision is a CMS blob; plist sits between XML headers
        guard let content = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            return ProvisionInfo()
        }
        
        guard let start = content.range(of: "<?xml"),
              let end = content.range(of: "</plist>") else {
            return ProvisionInfo()
        }
        
        let plistString = String(content[start.lowerBound..<end.upperBound])
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            return ProvisionInfo()
        }
        
        var info = ProvisionInfo()
        
        if let teamName = plist["TeamName"] as? String {
            info.teamName = teamName
        }
        
        if let teamIds = plist["TeamIdentifier"] as? [String] {
            info.teamIdentifier = teamIds.first
        }
        
        if let exp = plist["ExpirationDate"] as? Date {
            info.expirationDate = exp
        }
        
        return info
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Certificate].self, from: data) else {
            return
        }
        certificates = decoded
    }
}

enum CertificateCheckResult {
    case ok
    case missingFiles
    case expired
    
    var message: String {
        switch self {
        case .ok: return "Valid"
        case .missingFiles: return "Certificate files missing"
        case .expired: return "Certificate expired"
        }
    }
}
