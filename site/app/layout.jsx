import "./globals.css";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const metadata = {
  metadataBase: new URL(siteUrl),
  title: "Glossa - Live translated subtitles for macOS",
  description:
    "Glossa is a native macOS menu-bar app for local, live translated subtitles from your system audio.",
  openGraph: {
    title: "Glossa",
    description:
      "Live captions from your Mac audio, privately translated into the language you choose.",
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
