import Image from "next/image";

const previewLines = [
  {
    source: "El documental empieza ahora.",
    translation: "The documentary starts now.",
    label: "Spanish to English"
  },
  {
    source: "会議は5分後に始まります。",
    translation: "The meeting starts in five minutes.",
    label: "Japanese to English"
  },
  {
    source: "Le son reste sur votre Mac.",
    translation: "Audio stays on your Mac.",
    label: "French to English"
  },
  {
    source: "자막을 화면 위에 고정합니다.",
    translation: "Pin subtitles above the screen.",
    label: "Korean to English"
  },
  {
    source: "الترجمة تظهر أثناء التشغيل.",
    translation: "Translation appears during playback.",
    label: "Arabic to English"
  }
];

const proofItems = [
  {
    title: "macOS 15 Sequoia+",
    text: "Built for modern ScreenCaptureKit audio access."
  },
  {
    title: "Apple Silicon Mac",
    text: "Recommended for local WhisperKit transcription."
  },
  {
    title: "GitHub release",
    text: "Free to download, inspect, and improve."
  }
];

const features = [
  {
    title: "Subtitles that follow the audio",
    text: "Glossa captures what the Mac is playing, detects the spoken language, and keeps translated captions visible above the active app."
  },
  {
    title: "Menu-bar control without a dashboard",
    text: "Start listening, pause capture, switch target language, and show the overlay from a compact macOS applet."
  },
  {
    title: "Local-first by default",
    text: "WhisperKit handles transcription on the Mac. Apple Translation runs first when the language pair is available."
  },
  {
    title: "Fallbacks stay optional",
    text: "LibreTranslate-compatible endpoints can cover extra languages, including Bangla, without adding a required paid API."
  }
];

const languages = [
  { name: "Spanish", glyph: "Ñ", code: "es" },
  { name: "Japanese", glyph: "あ", code: "ja" },
  { name: "French", glyph: "É", code: "fr" },
  { name: "Korean", glyph: "한", code: "ko" },
  { name: "Arabic", glyph: "ع", code: "ar" },
  { name: "Hindi", glyph: "अ", code: "hi" },
  { name: "Mandarin", glyph: "中", code: "zh" },
  { name: "Portuguese", glyph: "ã", code: "pt" },
  { name: "Bangla", glyph: "অ", code: "bn" }
];

const privacyItems = [
  "Audio frames are processed in memory.",
  "Transcription uses WhisperKit on the Mac.",
  "Apple Translation is the default translation path.",
  "Fallback endpoints are user supplied and optional."
];

function MacDownloadButton() {
  return (
    <a
      className="primary-action download-action"
      href="https://github.com/rajin-khan/Glossa/releases"
    >
      <span className="apple-mark" aria-hidden="true"></span>
      <span className="download-label">
        <strong>Download for macOS</strong>
        <small>macOS 15 Sequoia or later</small>
      </span>
    </a>
  );
}

export default function Home() {
  return (
    <>
      <a className="skip-link" href="#features">
        Skip to content
      </a>

      <header className="site-header">
        <a className="brand" href="#top" aria-label="Glossa home">
          <Image src="/glossa-app-icon.png" alt="" width={38} height={38} priority />
          <span>Glossa</span>
        </a>
        <nav aria-label="Primary navigation">
          <a href="#features">Features</a>
          <a href="#privacy">Privacy</a>
          <a href="#download">Download</a>
        </nav>
        <a className="header-cta" href="https://github.com/rajin-khan/Glossa/releases">
          Download
        </a>
      </header>

      <main id="top">
        <section className="hero" aria-labelledby="hero-title">
          <div className="hero-copy">
            <h1 id="hero-title">Anything, translated live.</h1>
            <p className="hero-text">
              Capture Mac audio, detect speech locally, and show translated captions while
              playback continues.
            </p>
            <div className="hero-actions" aria-label="Primary actions">
              <MacDownloadButton />
              <a className="secondary-action" href="https://github.com/rajin-khan/Glossa">
                View GitHub
              </a>
            </div>
          </div>

          <div className="hero-visual" aria-label="Glossa live translation preview">
            <div className="app-window">
              <div className="ambient-card">
                <Image
                  src="/glossa-mark-template.png"
                  alt="Glossa bird and ribbon mark"
                  width={128}
                  height={128}
                  priority
                />
                <div>
                  <span>Target</span>
                  <strong>English</strong>
                </div>
              </div>

              <div className="window-bar">
                <span />
                <span />
                <span />
                <strong>Glossa</strong>
              </div>
              <div className="window-body">
                <div className="control-row">
                  <div>
                    <small>Capture</small>
                    <p>System Audio</p>
                  </div>
                  <div>
                    <small>Source</small>
                    <p>Auto detect</p>
                  </div>
                  <div>
                    <small>Target</small>
                    <p>English</p>
                  </div>
                </div>

                <div className="stage-shell">
                  <div className="subtitle-stage">
                    <Image
                      className="stage-mark"
                      src="/glossa-mark-template.png"
                      alt=""
                      aria-hidden="true"
                      width={360}
                      height={360}
                      loading="eager"
                    />
                    <div className="line-stack" aria-label="Example translated subtitles">
                      {previewLines.map((line, index) => (
                        <div className="subtitle-line" key={line.label} style={{ "--i": index }}>
                          <span>{line.label}</span>
                          <strong>{line.translation}</strong>
                          <small>{line.source}</small>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              <div className="menu-applet">
                <div className="applet-head">
                  <Image src="/glossa-mark-template.png" alt="" width={42} height={42} />
                  <div>
                    <strong>Glossa</strong>
                    <span>Listening in the menu bar</span>
                  </div>
                </div>
                <div className="meter" aria-hidden="true">
                  <span />
                  <span />
                  <span />
                  <span />
                  <span />
                </div>
                <div className="applet-buttons">
                  <button type="button">Pause</button>
                  <button type="button">Overlay</button>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="proof-strip" aria-label="Compatibility and distribution">
          {proofItems.map((item) => (
            <article key={item.title}>
              <strong>{item.title}</strong>
              <span>{item.text}</span>
            </article>
          ))}
        </section>

        <section className="section features-section" id="features">
          <div className="section-heading">
            <h2>Designed for video, calls, courses, and streams.</h2>
            <p>
              Glossa keeps the interaction close to the menu bar and moves the translation layer
              where attention already lives.
            </p>
          </div>

          <div className="feature-grid">
            {features.map((feature, index) => (
              <article className={`feature-card feature-${index + 1}`} key={feature.title}>
                <h3>{feature.title}</h3>
                <p>{feature.text}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="language-panel" aria-label="Language examples">
          <div>
            <h2>One control. Many languages.</h2>
            <p>
              Pick a target language once. Glossa listens for the source language automatically
              and keeps the translated line ready for the overlay.
            </p>
          </div>
          <div className="language-grid">
            {languages.map((language, index) => (
              <article
                className="language-tile"
                key={language.code}
                style={{ "--i": index }}
                aria-label={`${language.name} language example: ${language.glyph}`}
              >
                <span>{language.name}</span>
                <strong lang={language.code}>{language.glyph}</strong>
              </article>
            ))}
          </div>
        </section>

        <section className="privacy" id="privacy">
          <div>
            <h2>No account. No usage bill. No audio archive.</h2>
            <p>
              Audio frames are processed in memory and never saved by Glossa. Apple Translation
              and WhisperKit keep the default path local. If you configure LibreTranslate, choose a
              local endpoint to keep fallback translation on your own machine.
            </p>
          </div>
          <ul>
            {privacyItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section className="download" id="download">
          <Image src="/glossa-app-icon.png" alt="" width={86} height={86} />
          <div>
            <h2>Download Glossa 0.1.5.</h2>
            <p>
              Designed for Apple Silicon Macs running macOS 15 Sequoia or newer. The current build
              is ad-hoc signed for free GitHub distribution.
            </p>
          </div>
          <MacDownloadButton />
        </section>
      </main>

      <footer className="site-footer">
        <span>Glossa for macOS</span>
        <a href="https://github.com/rajin-khan/Glossa/blob/main/CHANGELOG.md">Changelog</a>
        <a href="https://github.com/rajin-khan/Glossa/blob/main/README.md">README</a>
      </footer>
    </>
  );
}
