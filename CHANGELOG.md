# Changelog

All notable changes to Glossa are tracked here.

## 0.1.1 - 2026-06-21

### Added

- Appearance section in the main app and Settings for subtitle overlay tuning.
- Single overlay scale control that adjusts subtitle text, source text, padding, height, width, corners, and transparency together.
- Reset Position action for returning the floating subtitle overlay to the lower center of the screen.
- Tiny shimmering bird standby state whenever the overlay is visible and no active subtitle is present.

### Changed

- The subtitle overlay now resizes per sentence, expanding horizontally first and then vertically only when needed.
- Pausing or stopping listening keeps the overlay available and clears the active subtitle, returning it to the bird standby state.
- Menu-bar applet and main app chrome were tightened for a calmer, more minimal workflow.
- Overlay shadows were removed to avoid rectangular artifacts around the rounded subtitle surface.

### Verified

- SwiftPM test suite passes with overlay preference persistence and standby behavior coverage.

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
- Responsive landing-page redesign with multilingual subtitle previews and a refined macOS product mockup.

### Verified

- SwiftPM test suite covers store behavior, subtitle pipeline, audio resampling, model directory checks, language catalog merging, and LibreTranslate endpoint resolution.
- Release bundle verifies with `codesign --verify --deep --strict`.

### Notes

- Glossa is free to develop and local-first. It contains no OpenAI API integration or paid cloud dependency.
- The current release uses ad-hoc signing for zero-budget GitHub distribution. Users should open the app once with **Control-click > Open**.
