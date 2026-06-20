# Glossa Roadmap

## Local-First MVP

- [x] Native SwiftUI window and menu-bar utility
- [x] ScreenCaptureKit system-audio capture
- [x] AVAudioEngine microphone fallback
- [x] Local multilingual WhisperKit transcription
- [x] Automatic source-language detection
- [x] Apple on-device translation and language-pack preparation
- [x] Bangla target visibility and LibreTranslate-compatible fallback path
- [x] Bilingual floating subtitle overlay
- [x] Transcript history, permissions, model setup, and recovery UX
- [x] App icon, release bundle, ZIP packaging, and checksums
- [x] Professional README, changelog, and promotional landing page
- [x] Self-contained Next.js landing site for Vercel

## After First Public Testing

- [ ] Add automated microphone and system-audio smoke tests
- [ ] Harden capture against device changes, permission changes, and sleep/wake
- [ ] Tune model/chunk presets for different Apple Silicon generations
- [ ] Add optional larger Whisper models
- [ ] Add clearer setup for local LibreTranslate fallback
- [ ] Export timestamped transcripts
- [ ] Add launch-at-login preference
- [ ] Add downloadable app screenshots and short demo video to the landing page
- [ ] Add Developer ID signing and notarization when funding permits
- [ ] Evaluate opt-in bring-your-own-key providers

## Public Release Readiness

- [ ] Compatibility notes for macOS 15, current macOS beta builds, and tested Mac models
- [ ] Crash-report issue template with app version, capture mode, permissions, and model status
- [ ] Privacy policy page that matches the local-first and optional fallback behavior
- [ ] Stable release channel separate from preview builds
