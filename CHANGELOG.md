# Changelog

All notable changes to Glossa are tracked here.

## 0.1.0 - 2026-06-20

### Added

- Native macOS SwiftUI app with regular window, menu-bar utility, and floating subtitle overlay.
- ScreenCaptureKit system-audio capture and AVAudioEngine microphone fallback.
- Local multilingual WhisperKit transcription with automatic source-language detection.
- Apple on-device translation workflow with target language discovery.
- Bangla target visibility even when Apple Translation does not expose Bangla dynamically.
- Optional LibreTranslate-compatible fallback endpoint for unsupported Apple Translation pairs.
- Dark bird-and-ribbon visual identity, app icon, menu-bar template mark, and branded UI surfaces.
- AppKit-backed menu-bar applet with start/pause, overlay, target language, capture source, and latest caption controls.
- Local transcript history, permission recovery, model setup, and diagnostics.
- Release packaging script for an ad-hoc signed `.app`, ZIP archive, and SHA-256 checksum.
- Self-contained Next.js landing site in `site/` for Vercel deployment.

### Verified

- SwiftPM test suite covers store behavior, subtitle pipeline, audio resampling, model directory checks, language catalog merging, and LibreTranslate endpoint resolution.
- Release bundle verifies with `codesign --verify --deep --strict`.

### Notes

- Glossa is free to develop and local-first. It contains no OpenAI API integration or paid cloud dependency.
- The current release uses ad-hoc signing for zero-budget GitHub distribution. Users should open the app once with **Control-click > Open**.
