import Foundation

struct SigningOptions: Codable, Equatable {
    var customBundleId: String?
    var customName: String?
    var customVersion: String?
    var removeProvisioning: Bool
    var adhoc: Bool
    
    static let `default` = SigningOptions(
        customBundleId: nil,
        customName: nil,
        customVersion: nil,
        removeProvisioning: false,
        adhoc: false
    )
}
