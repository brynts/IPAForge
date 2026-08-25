import Foundation
import Combine

@MainActor
class CertificateManager: ObservableObject {
    static let shared = CertificateManager()
    
    @Published var certificates: [Certificate] = []
    
    private let saveKey = "ipaforge.certificates"
    
    private init() {
        load()
    }
    
    var selectedCertificate: Certificate? {
        certificates.first(where: { $0.isSelected })
    }
    
    func add(_ certificate: Certificate) {
        // Only one selected at a time
        var newCert = certificate
        if certificates.isEmpty {
            newCert.isSelected = true
        }
        certificates.append(newCert)
        save()
    }
    
    func remove(_ certificate: Certificate) {
        certificates.removeAll { $0.id == certificate.id }
        
        // Auto-select another one if needed
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
