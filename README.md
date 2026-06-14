# EasyQZ 🧠 — client-only AI quizzes

**Generate quizzes with an AI that runs entirely in your browser, and challenge
friends with a link.** No server, no accounts, no API keys, no cloud bills.

EasyQZ is a complete rewrite of the original Flutter + server app into the
[**AgentHerd**](https://github.com/vishalmysore/agentHerd) pattern — local
**WebLLM/WebGPU** inference, **IndexedDB** storage, and **self-contained invite
links** for social play. Everything happens in the tab. Nothing is uploaded.

> 🔗 **Live:** [easyqz.online](https://easyqz.online/) · 🧩 Static-hosted on GitHub Pages
> · 🗄️ Original Flutter/server version preserved at tag [`flutter-legacy`](https://github.com/vishalmysore/easyqzm/tree/flutter-legacy)

---

## ✨ Features

- 🤖 **AI quiz generation in the browser** — a local model writes the questions on
  your device via WebGPU. No key, no backend, no per-token cost.
- 🎛️ **Four ways to make a quiz** — a **topic**, **pasted text/article**, a
  **category** (random subtopic), or an offline **Quick Quiz**.
- ⚡ **Quick Quiz (works offline / no GPU)** — multiple-choice questions built from a
  bundled bank of 500, so you can play even without WebGPU or a downloaded model.
- 🔗 **Challenge a friend with a link** — the whole quiz *and* your score are packed
  into the URL. Your friend opens it, takes the same quiz, and sees who won. No one
  needs to be online at the same time.
- 🏆 **Local leaderboard & history** — every score that passes through your browser
  (yours + incoming challenges) is ranked and saved locally.
- 🔒 **Private by design** — your text, quizzes, and scores never leave your machine.

---

## How it works

```
Your browser tab = the whole app
┌────────────────────────────────────────────────┐
│  WebLLM (WebGPU)  →  generates the quiz          │
│  IndexedDB        →  identity, history, scores   │
│  URL-hash link    →  async challenge a friend    │
└────────────────────────────────────────────────┘
        No HTTP / SSE / WebSocket. No backend.
```

The only network traffic is the **one-time model download** (cached afterward) from
the public MLC/WebLLM CDN. Quiz content, answers, scores, and your identity stay in
the browser. Challenges travel **inside the link** — nothing is stored on any server.

---

## Quiz modes

| Mode | Needs a model? | What it does |
|------|:---:|------|
| ✍️ **Topic** | yes | Type any topic — the model writes questions about it |
| 📄 **From text** | yes | Paste an article or notes — questions test that material |
| 🎲 **Category** | yes | Pick a category; a random subtopic keeps every quiz fresh |
| ⚡ **Quick Quiz** | **no** | Instant MCQs from the bundled 500-question bank |

Categories: Science · Math · History · Geography · Technology · Sports · General Knowledge.

---

## Challenging a friend (async, serverless)

1. Finish any quiz → tap **🔗 Challenge a friend**.
2. EasyQZ compresses the quiz + your score into a link: `…/#challenge=<token>`
   (deflate-raw + URL-safe base64 — the same packing AgentHerd uses for WebRTC tokens).
3. Send the link via any chat app, email, or SMS.
4. Your friend opens it, takes the **same** quiz locally, and the result screen shows
   **You vs Them**. They can re-challenge back with a fresh link carrying both scores.

Because the challenge lives entirely in the link, **no one has to be online at the
same time** and there's nothing to host.

---

## AI models (you pick; downloads once, then cached)

| Model | Size | Notes |
|-------|------|-------|
| Llama 3.2 · 1B | ~0.9 GB | Fastest — good for quick sessions |
| Qwen 2.5 · 1.5B | ~1.1 GB | Efficient, multilingual capable |
| Gemma 2 · 2B | ~1.5 GB | Balanced quality/speed |
| Llama 3.2 · 3B | ~2.3 GB | Better, more reliable quizzes |
| Phi-3.5 Mini | ~2.2 GB | Strong reasoning |

Larger models follow the JSON quiz format more reliably; 1B models are fastest but
occasionally need a retry (handled automatically).

---

## What "no server" changes (vs. the original)

- **No global leaderboard or trending.** With no shared backend there's no global
  store — leaderboards are **local** plus whoever's challenge links you've played.
- **No "quiz this URL" fetch.** A pure-browser app can't fetch arbitrary pages
  (CORS), so use **From text** and paste the content. It's captured into the quiz, so
  the challenge link stays self-contained.
- **No login.** Identity is a local, self-asserted name + avatar stored in your
  browser. Clearing site data resets it.

---

## Run locally

```bash
npm install
npm run dev      # http://localhost:3000
```

**Requirements:** a WebGPU browser (**Chrome/Edge 113+**) for the AI modes; a GPU
helps (integrated is fine for 1B). **Quick Quiz works everywhere**, including browsers
without WebGPU. The first AI quiz downloads model weights (~1 GB) and caches them, so
later quizzes start instantly.

---

## Build & deploy

```bash
npm run build    # → dist/  (static files only)
npm run preview  # serve the production build locally
```

Pushing to `main` builds and deploys to **GitHub Pages** via
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml). To activate:
**repo → Settings → Pages → Source → GitHub Actions**. For the custom domain, add a
`CNAME` file containing `easyqz.online` (and point DNS at GitHub Pages).

The Vite `base` is relative, so the same build works on a custom domain **and** on a
GitHub Pages project path (`/easyqzm/`) without reconfiguration.

---

## Project layout

```
index.html · style.css · challenge-bank.js   (bundled 500-question bank)
src/
  main.js       app bootstrap, hash routing, all screens
  llm.js        WebLLM/WebGPU wrapper + quiz prompts → structured JSON
  quiz.js       AI + offline generation, scoring, persistence, leaderboard
  db.js         IndexedDB stores: profile · attempts · quizzes · challenges
  identity.js   local self-asserted identity (name + avatar)
  share.js      encode/decode a challenge ⇄ URL hash
.github/workflows/deploy.yml   GitHub Pages
```

---

## Tech stack

| What | Why |
|------|-----|
| **WebLLM** | Runs LLMs in the browser via WebGPU — no API key, no cloud |
| **IndexedDB** | Local persistence for identity, history, and scores |
| **CompressionStream** | Packs a full quiz + score into a shareable URL hash |
| **Vite** | Build tooling and dev server |
| **GitHub Pages** | Static hosting — serves only HTML/JS/CSS, no server-side compute |

---

## Trust model (honest version)

The trust boundary is **possession of a challenge link** — anyone with it can take
that quiz, and the challenger's name/score in it are self-asserted (no cryptographic
identity). It has the threat model of a group chat, not a platform. Everything else
is local to your browser. This mirrors AgentHerd's design: safe among trusted peers,
appropriate for a client-only app.

---

## Migrating from the Flutter version

The original Flutter client and its Hugging Face Space server (HTTP/SSE/WebSocket +
Google-JWT auth) live on at tag `flutter-legacy`:

```bash
git checkout flutter-legacy   # restore the old app
git checkout main             # back to the client-only rewrite
```

---

## License

MIT — built by Vishal Mysore.
