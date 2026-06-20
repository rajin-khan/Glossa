# Glossa Site

This is the self-contained Next.js landing site for Glossa.

## Local Preview

```bash
pnpm install
pnpm dev
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000).

## Vercel

Set Vercel's **Root Directory** to:

```text
site
```

Use the default Next.js settings:

- Framework Preset: Next.js
- Install Command: `pnpm install`
- Build Command: `pnpm build`
- Output Directory: leave empty

The site copies its own assets into `public/`, so it does not depend on files outside this folder at deploy time.
