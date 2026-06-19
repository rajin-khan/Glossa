# Glossa

Glossa is a native macOS menu-bar app for live translated subtitles from system audio.

The development stack is local-first and free to run:

- ScreenCaptureKit and AVAudioEngine for system/microphone audio
- WhisperKit with a local multilingual Whisper model for speech-to-text
- Apple Translation on supported macOS versions for on-device translation
- Optional bring-your-own-key cloud providers may be added later

WhisperKit downloads the selected model on first use. The default development model is `tiny` so setup remains manageable while the realtime pipeline is being tuned.

## Run

```bash
./script/build_and_run.sh
```

The project is intentionally SwiftPM-first for now so early iteration stays light. The run script builds a local `.app` bundle in `dist/` before launching.
