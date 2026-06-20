# Glossa

Glossa is a native macOS menu-bar app that turns audio playing on your Mac into live translated subtitles. Speech recognition and translation run locally, with no account, API key, or usage bill.

## What Works

- System-audio capture through ScreenCaptureKit
- Microphone fallback through AVAudioEngine
- Automatic source-language detection with local WhisperKit
- Target languages discovered from Apple Translation plus Glossa's promised targets, including Bangla
- Optional LibreTranslate-compatible fallback endpoint for Bangla or other unsupported Apple pairs
- Floating bilingual subtitle overlay across Spaces and full-screen apps
- Menu-bar listen, language, capture, and overlay controls
- Local transcript history and model/permission recovery UI
- No audio recording or transcript upload

## Requirements

- macOS 15 or newer
- Apple Silicon recommended
- Screen & System Audio Recording permission
- Internet once to download the free Whisper model and any Apple language packs

## Run From Source

```bash
./script/prepare_local_model.sh
./script/build_and_run.sh
```

The app bundle is staged at `dist/Glossa.app`. The default `tiny` multilingual model keeps first-run setup and realtime latency manageable.

## Package A Release

```bash
./script/package_release.sh
```

This creates `dist/Glossa-0.1.0-macOS.zip` and `dist/SHA256SUMS.txt` using an optimized release build.

The zero-budget build uses a stable ad-hoc signature. After downloading it from GitHub, open Glossa once with **Control-click > Open**. A paid Developer ID can be supplied later through `CODESIGN_IDENTITY` for hardened-runtime signing and notarization.

## Privacy

Audio frames are processed in memory and never saved by Glossa. WhisperKit transcribes on this Mac; Apple Translation uses local language packs. Glossa contains no OpenAI API integration or paid cloud dependency.

If you configure a LibreTranslate fallback URL, translated text for unsupported pairs is sent to that endpoint. Use a local endpoint such as `http://127.0.0.1:5000` to keep that fallback on your own machine.
