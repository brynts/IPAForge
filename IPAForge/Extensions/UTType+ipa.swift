import UniformTypeIdentifiers

extension UTType {
    static var ipa: UTType {
        UTType(filenameExtension: "ipa", conformingTo: .data)!
    }
}
