# IPAForge

On-device IPA signer, installer, and file manager for **iOS 26+**. Powered by zsign.

## Status

Work in progress.

- [x] Certificate manager (import .p12 + .mobileprovision, password validation)
- [x] Zsign integration (SigningService)
- [ ] ZipFoundation (extract / repack IPA)
- [ ] File Manager
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
   - File → Add Package Dependencies…
   - Add Local… → select the `Zsign` folder (submodule)
5. (Optional) Add [ZipFoundation](https://github.com/weichsel/ZIPFoundation) via SPM for IPA extract/repack.

## Zsign

Uses [khcrysalis/Zsign-Package](https://github.com/khcrysalis/Zsign-Package) (`package` branch), same as Feather.

Signing is done via `SigningService.shared.sign(appURL:options:certificate:)` on an extracted `.app` bundle.

## License

MIT
