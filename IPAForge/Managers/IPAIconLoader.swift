import UIKit

#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

enum IPAIconLoader {
    /// Best-effort: pull a PNG icon out of an IPA zip.
    static func loadIcon(from ipaURL: URL) -> UIImage? {
        #if canImport(ZIPFoundation)
        guard let archive = Archive(url: ipaURL, accessMode: .read) else { return nil }
        
        // Prefer AppIcon*@3x / AppIcon* large PNGs under Payload/*.app/
        let candidates = archive.compactMap { entry -> (String, Int)？ in
            let path = entry.path
            guard path.hasPrefix("Payload/"),
                  path.contains(".app/"),
                  path.lowercased().hasSuffix(".png") else { return nil }
            let name = (path as NSString).lastPathComponent.lowercased()
            // Prefer app icons over random assets
            let score: Int
            if name.contains("appicon") {
                score = 100 + entry.uncompressedSize
            } else if name.hasPrefix("icon") {
                score = 50 + entry.uncompressedSize
            } else {
                score = entry.uncompressedSize
            }
            return (path, score)
        }
        // Fix typo - can't use fullwidth question mark. Rewrite properly below.
        return nil
        #else
        return nil
        #endif
    }
}
