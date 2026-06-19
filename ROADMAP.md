# Glossa Roadmap

## Milestone 0: Mac Shell

- Native SwiftUI main window
- Menu-bar extra with listen/pause controls
- Floating subtitle overlay using a narrow AppKit bridge
- App state model and provider boundaries
- ScreenCaptureKit capture scaffold

## Milestone 1: Audio Proof

- [x] Request macOS audio/screen capture permissions
- [x] Capture system audio buffers through ScreenCaptureKit
- [x] Show live input level and capture health
- [x] Add microphone fallback

## Milestone 2: Realtime Captions

- [x] Add PCM frames, speech gating, and ASR-sized audio chunks
- [x] Add a transcription provider boundary
- [x] Integrate WhisperKit as the free local default
- [ ] Tune local model chunk size and transcript stabilization
- [ ] Persist recent transcript segments

## Milestone 3: Translation

- Target language picker
- Phrase-level translation buffering
- Bilingual overlay mode
- Apple Translation provider where available
- Optional downloadable local translation packs for unsupported languages

## Milestone 4: Local Mode

- [x] WhisperKit local transcription
- Download/manage model packs
- Battery/performance controls
- Offline privacy mode
