import Foundation

#if canImport(ZsignSwift)
import ZsignSwift
#endif

enum SigningError: LocalizedError {
    case noCertificate
    case certificateInvalid(String)
    case appNotFound
    case signFailed(String)
    case zsignUnavailable
    
    var errorDescription: String? {
        switch self {
        case .noCertificate:
            return "No certificate selected. Add one in Settings."
        case .certificateInvalid(let msg):
            return "Certificate invalid: \(msg)"
        case .appNotFound:
            return "App bundle not found."
        case .signFailed(let msg):
            return "Signing failed: \(msg)"
        case .zsignUnavailable:
            return "Zsign is not linked. Add the Zsign package in Xcode."
        }
    }
}

/// Thin wrapper around Zsign for signing an extracted .app bundle.
@MainActor
final class SigningService {
    static let shared = SigningService()
    
    private let certificateManager = CertificateManager.shared
    
    private init() {}
    
    /// Sign an already-extracted .app directory.
    /// - Parameters:
    ///   - appURL: Path to `Something.app`
    ///   - options: Optional overrides (bundle id, name, version, adhoc)
    ///   - certificate: Certificate to use. Defaults to selected one.
    func sign(
        appURL: URL,
        options: SigningOptions = .default,
        certificate: Certificate? = nil
    ) async throws {
        guard FileManager.default.fileExists(atPath: appURL.path) else {
            throw SigningError.appNotFound
        }
        
        #if canImport(ZsignSwift)
        if options.adhoc {
            try await signAdhoc(appURL: appURL, options: options)
            return
        }
        
        let cert = certificate ?? certificateManager.selectedCertificate
        guard let cert else {
            throw SigningError.noCertificate
        }
        
        let check = certificateManager.check(cert)
        guard check == .ok else {
            throw SigningError.certificateInvalid(check.message)
        }
        
        let p12Path = certificateManager.p12URL(for: cert).path
        let provisionPath = certificateManager.provisionURL(for: cert).path
        let password = cert.password ?? ""
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var finished = false
            
            _ = Zsign.sign(
                appPath: appURL.path,
                provisionPath: provisionPath,
                p12Path: p12Path,
                p12Password: password,
                entitlementsPath: "",
                customIdentifier: options.customBundleId ?? "",
                customName: options.customName ?? "",
                customVersion: options.customVersion ?? "",
                removeProvision: !options.removeProvisioning,
                completion: { success, error in
                    guard !finished else { return }
                    finished = true
                    
                    if let error {
                        cont.resume(throwing: SigningError.signFailed(error.localizedDescription))
                    } else if success == false {
                        cont.resume(throwing: SigningError.signFailed("Unknown signing error"))
                    } else {
                        cont.resume()
                    }
                }
            )
        }
        #else
        throw SigningError.zsignUnavailable
        #endif
    }
    
    #if canImport(ZsignSwift)
    private func signAdhoc(appURL: URL, options: SigningOptions) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var finished = false
            
            _ = Zsign.sign(
                appPath: appURL.path,
                entitlementsPath: "",
                customIdentifier: options.customBundleId ?? "",
                customName: options.customName ?? "",
                customVersion: options.customVersion ?? "",
                adhoc: true,
                removeProvision: !options.removeProvisioning,
                completion: { success, error in
                    guard !finished else { return }
                    finished = true
                    
                    if let error {
                        cont.resume(throwing: SigningError.signFailed(error.localizedDescription))
                    } else if success == false {
                        cont.resume(throwing: SigningError.signFailed("Unknown adhoc signing error"))
                    } else {
                        cont.resume()
                    }
                }
            )
        }
    }
    #endif
}
