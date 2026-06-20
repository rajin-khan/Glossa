import Image from "next/image";

const features = [
  {
    number: "01",
    title: "Floating bilingual subtitles",
    text: "Translations sit above full-screen apps and Spaces, with source text available underneath when you want it.",
    className: "large"
  },
  {
    number: "02",
    title: "System audio capture",
    text: "Capture audio playing on your Mac through ScreenCaptureKit, with microphone fallback when needed.",
    className: ""
  },
  {
    number: "03",
    title: "Automatic source detection",
    text: "WhisperKit identifies the spoken language locally before Glossa translates into your selected target.",
    className: ""
  },
  {
    number: "04",
    title: "A real macOS applet",
    text: "The menu-bar bird opens a compact control surface for listening, overlays, capture mode, and recent captions.",
    className: "dark"
  }
];

const privacyItems = [
  "Speech recognition: WhisperKit on this Mac",
  "Translation: Apple first, fallback optional",
  "Capture: system audio or microphone fallback",
  "Storage: transcripts stay local"
];

export default function Home() {
  return (
    <>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="Glossa home">
          <Image src="/glossa-app-icon.png" alt="" width={36} height={36} priority />
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
        <section className="hero">
          <div className="hero-copy">
            <p className="eyebrow">Native macOS subtitle utility</p>
            <h1>Translate audio.</h1>
            <p className="hero-text">
              Live captions from your Mac audio, privately translated into the language you choose.
            </p>
            <div className="hero-actions">
              <a className="primary-action" href="https://github.com/rajin-khan/Glossa/releases">
                Download 0.1.0
              </a>
              <a className="secondary-action" href="https://github.com/rajin-khan/Glossa">
                View GitHub
              </a>
            </div>
          </div>

          <div className="hero-visual" aria-label="Glossa app preview">
            <div className="icon-plinth">
              <Image
                src="/glossa-app-icon.png"
                alt="Glossa app icon with an engraved bird and ribbon"
                width={172}
                height={172}
                priority
              />
            </div>
            <div className="app-window">
              <div className="window-bar">
                <span />
                <span />
                <span />
                <strong>Glossa</strong>
              </div>
              <div className="window-body">
                <div className="control-row">
                  <div>
                    <small>Listen To</small>
                    <p>System Audio</p>
                  </div>
                  <div>
                    <small>Translate Into</small>
                    <p>Bangla · বাংলা</p>
                  </div>
                  <button type="button">Start</button>
                </div>
                <div className="subtitle-stage">
                  <Image
                    className="stage-mark"
                    src="/glossa-mark-template.png"
                    alt=""
                    aria-hidden="true"
                    width={340}
                    height={340}
                  />
                  <p className="translated">The translation appears while audio keeps playing.</p>
                  <p className="source">La traduction apparait pendant que l'audio continue.</p>
                </div>
              </div>
            </div>
            <div className="menu-applet">
              <div className="applet-head">
                <Image src="/glossa-app-icon.png" alt="" width={44} height={44} />
                <div>
                  <strong>Glossa</strong>
                  <span>Ready in the menu bar</span>
                </div>
              </div>
              <div className="applet-buttons">
                <button type="button">Start</button>
                <button type="button">Overlay</button>
              </div>
              <div className="applet-caption">
                <small>Ribbon</small>
                <p>Ready to carry the next line.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="feature-strip" aria-label="Core product qualities">
          <div>
            <strong>Local-first</strong>
            <span>WhisperKit transcription on this Mac.</span>
          </div>
          <div>
            <strong>Menu-bar fast</strong>
            <span>Start, pause, switch language, and show the overlay.</span>
          </div>
          <div>
            <strong>Bangla ready</strong>
            <span>Apple first, LibreTranslate fallback optional.</span>
          </div>
        </section>

        <section className="section" id="features">
          <div className="section-heading">
            <h2>Built for watching, listening, and staying immersed.</h2>
            <p>Glossa stays out of the way until speech needs to become readable.</p>
          </div>
          <div className="feature-grid">
            {features.map((feature) => (
              <article key={feature.number} className={`feature-card ${feature.className}`.trim()}>
                <span>{feature.number}</span>
                <h3>{feature.title}</h3>
                <p>{feature.text}</p>
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
          <Image src="/glossa-app-icon.png" alt="" width={92} height={92} />
          <div>
            <h2>Start with Glossa 0.1.0.</h2>
            <p>
              The current build is ad-hoc signed for free GitHub distribution. Open it once with
              Control-click &gt; Open.
            </p>
          </div>
          <a className="primary-action" href="https://github.com/rajin-khan/Glossa/releases">
            Download ZIP
          </a>
        </section>
      </main>

      <footer className="site-footer">
        <span>Glossa 0.1.0</span>
        <a href="https://github.com/rajin-khan/Glossa/blob/main/CHANGELOG.md">Changelog</a>
        <a href="https://github.com/rajin-khan/Glossa/blob/main/README.md">README</a>
      </footer>
    </>
  );
}
