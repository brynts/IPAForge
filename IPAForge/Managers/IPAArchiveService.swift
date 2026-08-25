import Foundation

#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

enum IPAArchiveError: LocalizedError {
    case zipUnavailable
    case extractFailed(String)
    case packFailed(String)
    case payloadNotFound
    case appNotFound
    
    var errorDescription: String? {
        switch self {
        case .zipUnavailable:
            return "ZipFoundation is not linked. Add ZIPFoundation via SPM."
        case .extractFailed(let msg):
            return "Extract failed: \(msg)"
        case .packFailed(let msg):
            return "Pack failed: \(msg)"
        case .payloadNotFound:
            return "Payload folder not found inside IPA."
        case .appNotFound:
            return "No .app found inside Payload."
        }
    }
}

/// Extract / repack IPA using ZipFoundation.
/// Working directories live under Documents so they show in Files app.
@MainActor
final class IPAArchiveService {
    static let shared = IPAArchiveService()
    
    private let fileManager = FileManager.default
    
    /// Documents/IPAForge/
    var rootDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("IPAForge", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var unsignedDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("Unsigned", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var signedDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("Signed", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var workDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("Work", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {}
    
    // MARK: - Extract
    
    /// Unzip IPA → returns URL of the `.app` bundle inside Work/{uuid}/Payload/
    func extractApp(from ipaURL: URL) throws -> (workDir: URL, appURL: URL) {
        #if canImport(ZIPFoundation)
        let id = UUID().uuidString
        let workDir = workDirectory.appendingPathComponent(id, isDirectory: true)
        try fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)
        
        do {
            try fileManager.unzipItem(at: ipaURL, to: workDir)
        } catch {
            try? fileManager.removeItem(at: workDir)
            throw IPAArchiveError.extractFailed(error.localizedDescription)
        }
        
        let payload = workDir.appendingPathComponent("Payload", isDirectory: true)
        guard fileManager.fileExists(atPath: payload.path) else {
            try? fileManager.removeItem(at: workDir)
            throw IPAArchiveError.payloadNotFound
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: payload,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        guard let appURL = contents.first(where: { $0.pathExtension.lowercased() == "app" }) else {
            try? fileManager.removeItem(at: workDir)
            throw IPAArchiveError.appNotFound
        }
        
        return (workDir, appURL)
        #else
        throw IPAArchiveError.zipUnavailable
        #endif
    }
    
    // MARK: - Pack
    
    /// Pack a work directory (must contain Payload/*.app) into a new IPA under Signed/
    func packIPA(workDir: URL, outputName: String) throws -> URL {
        #if canImport(ZIPFoundation)
        var name = outputName
        if !name.lowercased().hasSuffix(".ipa") {
            name += ".ipa"
        }
        
        let outputURL = signedDirectory.appendingPathComponent(name)
        
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        
        do {
            // Zip contents of workDir (Payload/...) so structure stays correct
            try fileManager.zipItem(at: workDir, to: outputURL, shouldKeepParent: false)
        } catch {
            throw IPAArchiveError.packFailed(error.localizedDescription)
        }
        
        return outputURL
        #else
        throw IPAArchiveError.zipUnavailable
        #endif
    }
    
    // MARK: - Import IPA file into Unsigned/
    
    /// Copy an IPA into Documents/IPAForge/Unsigned/
    func importUnsignedIPA(from sourceURL: URL) throws -> URL {
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if access { sourceURL.stopAccessingSecurityScopedResource() }
        }
        
        let dest = unsignedDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        
        try fileManager.copyItem(at: sourceURL, to: dest)
        return dest
    }
    
    // MARK: - Cleanup
    
    func removeWorkDir(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }
}
