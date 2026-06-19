# Glossa

Glossa is a native macOS menu-bar app for live translated subtitles from system audio.

The first milestone is the Mac shell: a polished SwiftUI window, menu-bar controls, a floating subtitle overlay, and service boundaries for system audio capture, transcription, and translation.

## Run

```bash
./script/build_and_run.sh
```

The project is intentionally SwiftPM-first for now so early iteration stays light. The run script builds a local `.app` bundle in `dist/` before launching.
