# Glossa Roadmap

## Milestone 0: Mac Shell

- Native SwiftUI main window
- Menu-bar extra with listen/pause controls
- Floating subtitle overlay using a narrow AppKit bridge
- App state model and provider boundaries
- ScreenCaptureKit capture scaffold

## Milestone 1: Audio Proof

- Request macOS audio/screen capture permissions
- Capture system audio buffers through ScreenCaptureKit
- Show live input level and capture health
- Add microphone fallback

## Milestone 2: Realtime Captions

- Connect cloud ASR for first working realtime transcripts
- Add partial/final transcript stabilization
- Persist recent transcript segments

## Milestone 3: Translation

- Target language picker
- Phrase-level translation buffering
- Bilingual overlay mode
- Provider switcher for OpenAI, DeepL, and Apple Translation where available

## Milestone 4: Local Mode

- WhisperKit local transcription
- Download/manage model packs
- Battery/performance controls
- Offline privacy mode
