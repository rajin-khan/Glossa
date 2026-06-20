# Changelog

All notable changes to Glossa are tracked here.

## Unreleased

### Changed

- Split persistence, capture lifecycle, preview playback, AppKit system routing, main-window sections, and menu-bar sections into focused helper types.
- Simplified the menu-bar applet with one brand mark, compact language and capture menus, lighter live-caption presentation, and smoother state transitions.
- Reduced overlay customization to the intended single scale control plus source-text visibility.

### Fixed

- Serialized rapid capture stop/start operations so an older stop cannot tear down a newly started session.
- Made the onboarding permission action reliably foreground the macOS Screen & System Audio Recording pane without competing permission prompts.

### Removed

- Deleted unused overlay typography, width, opacity, and corner-radius preferences.
- Deleted the superseded static `landing/` site; `site/` remains the single Vercel-ready web app.

### Verified

- `swift test`
- `pnpm run build` in `site/`
- `./script/build_and_run.sh --verify --preview-subtitles`

## 0.1.5 - 2026-06-21

### Fixed

- Onboarding and Settings permission buttons now open the relevant macOS Privacy & Security panes instead of only making silent permission requests.

### Verified

- `swift test`

## 0.1.4 - 2026-06-21

### Added

- First-run onboarding for permissions, local speech model setup, and preview listening.
- Help menu command for reopening the onboarding flow.
- DMG packaging with a drag-to-Applications installer layout alongside the zip archive.

### Fixed

- Microphone buffer capture now handles interleaved and planar channel layouts safely.
- Microphone tap work now keeps analysis and UI relay work off the Core Audio callback path.

### Verified

- `swift test`
- Microphone smoke launch with audible speech input stayed alive after the previous crash window.
- Release package build, code-signature verification, DMG verification, and checksum generation.

## 0.1.3 - 2026-06-21

### Changed

- Polished the empty transcript copy in the main app.
- Updated download references for the latest preview package.

### Verified

- `swift test`
- `pnpm run build`
- Release package build, code-signature verification, and checksum verification.

## 0.1.2 - 2026-06-21

### Fixed

- Microphone capture no longer crashes when the AVAudioEngine tap delivers buffers on Core Audio's realtime queue.
- Microphone startup now validates the current input format before installing the tap.

### Changed

- Capture failures now keep the subtitle overlay available and return it to the tiny standby mark instead of hiding the overlay.
- The standby overlay mark now uses a diagonal sheen animation instead of a simple fade pulse.
- The menu-bar applet is slightly smaller and tighter while keeping start, overlay, language, capture, and settings controls available.

### Verified

- `swift test`
- Microphone smoke launch stays alive after the previous crash window.

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

## Pre-1.0 Milestones

### Preview Stabilization

- [ ] Keep system-audio and microphone capture stable across macOS 15 and current macOS beta builds.
- [ ] Add a repeatable smoke-test script for microphone, system audio, overlay standby, and preview mode.
- [ ] Improve first-run recovery when permissions or local model files are missing.

### Translation Quality

- [ ] Tune speech chunking for shorter captions and lower latency.
- [ ] Offer local model size choices after the tiny model path is stable.
- [ ] Make LibreTranslate fallback setup clearer for self-hosted users.

### Distribution

- [ ] Add a signed and notarized build when funding allows a paid Apple Developer account.
- [ ] Add downloadable screenshots and a short demo video.
- [ ] Publish a clearer compatibility table by Mac model and macOS version after more testing.

### Public Launch

- [ ] Confirm privacy copy with real fallback behavior.
- [ ] Add issue templates for crash reports, language coverage, and capture bugs.
- [ ] Move from preview release notes to a stable support policy.
