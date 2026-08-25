# IPAForge

On-device IPA signer, installer, and file manager for **iOS 26+**. Powered by zsign.

## Status

Work in progress.

- [x] Certificate manager (import .p12 + .mobileprovision, password validation)
- [x] Zsign integration (SigningService)
- [x] ZipFoundation (extract / pack IPA via IPAArchiveService)
- [ ] File Manager UI
- [ ] Download (background URLSession)
- [ ] Install flow
- [ ] Full signing UI

## Requirements

- iOS 26.0+
- Xcode with iOS 26 SDK

## Setup

1. Create a new **iOS App** project in Xcode (SwiftUI, iOS 26+).
2. Clone this repo (with submodules):

```bash
git clone --recursive https://github.com/brynts/IPAForge.git
```

If already cloned:

```bash
git submodule update --init --recursive
```

3. Drag the `IPAForge/` source folder into your Xcode project.
4. Add local package **Zsign**:
   - File → Add Package Dependencies… → Add Local… → select `Zsign`
5. Add [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) via SPM.
6. In Info.plist enable Files app access:
   - `UIFileSharingEnabled` = YES
   - `LSSupportsOpeningDocumentsInPlace` = YES

## Storage (visible in Files app)

```
On My iPhone / IPAForge/
└── IPAForge/
    ├── Unsigned/     # imported IPAs
    ├── Signed/       # signed output IPAs
    ├── Work/         # temp extract folders
    └── Certificates/ # managed by CertificateManager (under Documents/Certificates)
```

## Zsign

Uses [khcrysalis/Zsign-Package](https://github.com/khcrysalis/Zsign-Package) (`package` branch).

## License

MIT
