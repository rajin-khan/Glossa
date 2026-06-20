import "./globals.css";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const metadata = {
  metadataBase: new URL(siteUrl),
  title: "Glossa - Live translated subtitles for Mac audio",
  description:
    "Glossa is a native macOS menu-bar app for local live subtitles from system audio on Apple Silicon Macs running macOS 15 Sequoia or newer.",
  openGraph: {
    title: "Glossa",
    description:
      "Live translated subtitles from Mac audio, with local transcription and menu-bar controls.",
    images: ["/glossa-app-icon.png"]
  },
  icons: {
    icon: "/glossa-app-icon.png",
    apple: "/glossa-app-icon.png"
  }
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
