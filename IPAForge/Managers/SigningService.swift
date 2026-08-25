import Foundation

#if canImport(Zsign)
import Zsign
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

@MainActor
final class SigningService {
    static let shared = SigningService()
    
    private let certificateManager = CertificateManager.shared
    
    private init() {}
    
    func sign(
        appURL: URL,
        options: SigningOptions = .default,
        certificate: Certificate? = nil
    ) async throws {
        guard FileManager.default.fileExists(atPath: appURL.path) else {
            throw SigningError.appNotFound
        }
        
        #if canImport(Zsign)
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
            
            let ok = Zsign.sign(
                appPath: appURL.path,
                provisionPath: provisionPath,
                p12Path: p12Path,
                p12Password: password,
                entitlementsPath: "",
                customIdentifier: options.customBundleId ?? "",
                customName: options.customName ?? "",
                customVersion: options.customVersion ?? "",
                adhoc: false,
                removeProvision: options.removeProvisioning,
                completion: { success in
                    guard !finished else { return }
                    finished = true
                    if success {
                        cont.resume()
                    } else {
                        cont.resume(throwing: SigningError.signFailed("Zsign returned failure"))
                    }
                }
            )
            
            // If completion is never called and immediate false
            if !ok && !finished {
                finished = true
                cont.resume(throwing: SigningError.signFailed("Zsign returned false"))
            }
        }
        #else
        throw SigningError.zsignUnavailable
        #endif
    }
    
    #if canImport(Zsign)
    private func signAdhoc(appURL: URL, options: SigningOptions) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var finished = false
            
            let ok = Zsign.sign(
                appPath: appURL.path,
                entitlementsPath: "",
                customIdentifier: options.customBundleId ?? "",
                customName: options.customName ?? "",
                customVersion: options.customVersion ?? "",
                adhoc: true,
                removeProvision: options.removeProvisioning,
                completion: { success in
                    guard !finished else { return }
                    finished = true
                    if success {
                        cont.resume()
                    } else {
                        cont.resume(throwing: SigningError.signFailed("Adhoc sign failed"))
                    }
                }
            )
            
            if !ok && !finished {
                finished = true
                cont.resume(throwing: SigningError.signFailed("Adhoc sign returned false"))
            }
        }
    }
    #endif
}
