import Foundation
import Combine
import Security

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
    
    func add(
        name: String,
        p12SourceURL: URL,
        provisionSourceURL: URL,
        password: String?
    ) throws -> Certificate {
        let p12Access = p12SourceURL.startAccessingSecurityScopedResource()
        let provisionAccess = provisionSourceURL.startAccessingSecurityScopedResource()
        defer {
            if p12Access { p12SourceURL.stopAccessingSecurityScopedResource() }
            if provisionAccess { provisionSourceURL.stopAccessingSecurityScopedResource() }
        }
        
        try validateP12(at: p12SourceURL, password: password)
        
        let id = UUID()
        let folder = certificatesDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let p12Name = p12SourceURL.lastPathComponent
        let provisionName = provisionSourceURL.lastPathComponent
        
        let destP12 = folder.appendingPathComponent(p12Name)
        let destProvision = folder.appendingPathComponent(provisionName)
        
        try fileManager.copyItem(at: p12SourceURL, to: destP12)
        try fileManager.copyItem(at: provisionSourceURL, to: destProvision)
        
        let info = try parseMobileProvision(at: destProvision)
        
        let cert = Certificate(
            id: id,
            name: name,
            p12FileName: p12Name,
            mobileProvisionFileName: provisionName,
            password: password,
            teamName: info.teamName,
            teamIdentifier: info.teamIdentifier,
            appIDName: info.appIDName,
            provisionName: info.provisionName,
            creationDate: info.creationDate,
            expirationDate: info.expirationDate,
            ppqCheck: info.ppqCheck,
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
    
    func check(_ certificate: Certificate) -> CertificateCheckResult {
        let p12Path = p12URL(for: certificate)
        let provisionPath = provisionURL(for: certificate)
        
        guard fileManager.fileExists(atPath: p12Path.path),
              fileManager.fileExists(atPath: provisionPath.path) else {
            return .missingFiles
        }
        
        if certificate.isExpired {
            return .expired
        }
        
        do {
            try validateP12(at: p12Path, password: certificate.password)
        } catch CertificateError.wrongPassword {
            return .wrongPassword
        } catch {
            return .invalidP12
        }
        
        return .ok
    }
    
    // MARK: - P12 Validation
    
    func validateP12(at url: URL, password: String?) throws {
        let data = try Data(contentsOf: url)
        let pwd = password ?? ""
        
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: pwd
        ]
        
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        
        switch status {
        case errSecSuccess:
            return
        case errSecAuthFailed, errSecPkcs12VerifyFailure:
            throw CertificateError.wrongPassword
        default:
            throw CertificateError.invalidP12(status)
        }
    }
    
    // MARK: - Parse mobileprovision
    
    private struct ProvisionInfo {
        var teamName: String?
        var teamIdentifier: String?
        var appIDName: String?
        var provisionName: String?
        var creationDate: Date?
        var expirationDate: Date?
        var ppqCheck: Bool?
    }
    
    private func parseMobileProvision(at url: URL) throws -> ProvisionInfo {
        let data = try Data(contentsOf: url)
        
        guard let content = String(data: data, encoding: .isoLatin1) else {
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
        
        info.teamName = plist["TeamName"] as? String
        info.appIDName = plist["AppIDName"] as? String
        info.provisionName = plist["Name"] as? String
        info.creationDate = dateValue(plist["CreationDate"])
        info.expirationDate = dateValue(plist["ExpirationDate"])
        info.ppqCheck = boolValue(plist["PPQCheck"])
        
        if let teamIds = plist["TeamIdentifier"] as? [String] {
            info.teamIdentifier = teamIds.first
        }
        
        return info
    }
    
    private func dateValue(_ any: Any?) -> Date? {
        if let date = any as? Date { return date }
        if let interval = any as? TimeInterval { return Date(timeIntervalSinceReferenceDate: interval) }
        if let number = any as? NSNumber {
            return Date(timeIntervalSinceReferenceDate: number.doubleValue)
        }
        if let string = any as? String {
            let formatter = ISO8601DateFormatter()
            if let d = formatter.date(from: string) { return d }
        }
        return nil
    }
    
    private func boolValue(_ any: Any?) -> Bool? {
        if let b = any as? Bool { return b }
        if let n = any as? NSNumber { return n.boolValue }
        if let i = any as? Int { return i != 0 }
        if let s = any as? String {
            let lower = s.lowercased()
            if ["true", "yes", "1"].contains(lower) { return true }
            if ["false", "no", "0"].contains(lower) { return false }
        }
        return nil
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

enum CertificateError: LocalizedError {
    case wrongPassword
    case invalidP12(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .wrongPassword:
            return "Wrong password for the .p12 certificate."
        case .invalidP12(let status):
            return "Invalid .p12 file (error \(status))."
        }
    }
}

enum CertificateCheckResult {
    case ok
    case missingFiles
    case expired
    case wrongPassword
    case invalidP12
    
    var message: String {
        switch self {
        case .ok: return "Valid"
        case .missingFiles: return "Files missing"
        case .expired: return "Expired"
        case .wrongPassword: return "Wrong password"
        case .invalidP12: return "Invalid .p12"
        }
    }
}
