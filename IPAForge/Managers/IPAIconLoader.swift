import UIKit

#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

enum IPAIconLoader {
    /// Best-effort: pull a PNG icon out of an IPA zip.
    static func loadIcon(from ipaURL: URL) -> UIImage? {
        #if canImport(ZIPFoundation)
        guard let archive = Archive(url: ipaURL, accessMode: .read) else { return nil }
        
        var bestPath: String?
        var bestScore = 0
        
        for entry in archive {
            let path = entry.path
            guard path.hasPrefix("Payload/"),
                  path.contains(".app/"),
                  path.lowercased().hasSuffix(".png") else { continue }
            
            // Skip nested frameworks/plugins icons when possible
            let lower = path.lowercased()
            if lower.contains(".appex/") || lower.contains(".framework/") { continue }
            
            let name = (path as NSString).lastPathComponent.lowercased()
            var score = entry.uncompressedSize
            if name.contains("appicon") {
                score += 10_000_000
            } else if name.hasPrefix("icon") {
                score += 1_000_000
            }
            if name.contains("60x60") || name.contains("76x76") || name.contains("83.5") {
                score += 100_000
            }
            
            if score > bestScore {
                bestScore = score
                bestPath = path
            }
        }
        
        guard let bestPath,
              let entry = archive[bestPath] else { return nil }
        
        var data = Data()
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return nil
        }
        
        return UIImage(data: data)
        #else
        return nil
        #endif
    }
}
