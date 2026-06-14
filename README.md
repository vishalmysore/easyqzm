# EasyQZ 🧠 — client-only AI quizzes (AgentHerd architecture)

EasyQZ generates quizzes with an LLM that runs **entirely in your browser** and lets
you **challenge friends with a link** — no server, no accounts, no API keys.

This is a complete rewrite of the original Flutter + server app into the
[AgentHerd](https://github.com/vishalmysore/agentHerd) pattern: **WebLLM + WebGPU**
for inference, **IndexedDB** for storage, and **self-contained invite links** for
social play. The previous Flutter/server version is preserved in git at tag
[`flutter-legacy`](https://github.com/vishalmysore/easyqzm/releases/tag/flutter-legacy).

## How it works

```
Your browser tab = the whole app
┌───────────────────────────────────────────────┐
│  WebLLM (WebGPU)  → generates the quiz          │
│  IndexedDB        → identity, history, scores   │
│  URL-hash link    → async challenge a friend    │
└───────────────────────────────────────────────┘
       No HTTP / SSE / WebSocket. No backend.
```

- **AI quiz generation** — pick a topic, paste an article, or choose a category. A
  local model (Llama / Qwen / Gemma / Phi) writes the questions on your device.
- **Quick Quiz (offline)** — needs no model at all; builds MCQs from a bundled bank
  of 500 questions. Works even without WebGPU.
- **Challenge a friend** — your finished quiz + score are compressed into a link
  (`#challenge=…`). Your friend opens it, takes the *same* quiz locally, and sees who
  won. Nobody needs to be online at the same time.
- **Local leaderboard & history** — every score that passes through your browser
  (yours and incoming challenges) is ranked locally.

## What "no server" changes
- **No global leaderboard / trending.** Without a shared backend there is no global
  store; leaderboards are local + among the people whose links you play.
- **Quizzing a URL** can't fetch arbitrary pages (browser CORS) — paste the article
  text instead. The text is captured into the quiz so the challenge link is self-contained.

## Run locally
```bash
npm install
npm run dev      # http://localhost:3000
```
**Requirements:** a WebGPU browser (Chrome/Edge 113+) for AI modes; a GPU helps.
First model load downloads weights (~1 GB) and caches them — later quizzes are instant.
Quick Quiz works everywhere.

## Build & deploy
```bash
npm run build    # → dist/  (static files)
```
Pushing to `main` deploys to GitHub Pages via `.github/workflows/deploy.yml`.

## Project layout
```
index.html · style.css · challenge-bank.js   (bundled 500-question bank)
src/
  main.js       app bootstrap, routing, screens
  llm.js        WebLLM wrapper + quiz prompts
  quiz.js       generation, offline mode, scoring, persistence
  db.js         IndexedDB stores: profile, attempts, quizzes, challenges
  identity.js   local self-asserted identity
  share.js      encode/decode challenge ⇄ URL hash
```

## License
MIT
