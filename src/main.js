import '../style.css';
import { getMe, updateMe } from './identity.js';
import { MODELS, checkWebGPU, loadModel, isReady, currentModelId } from './llm.js';
import {
  CATEGORIES, pickCategoryTopic, createQuizFromTopic, createQuizFromText,
  buildOfflineQuiz, scoreQuiz, saveQuiz, saveAttempt, allAttempts, leaderboard,
} from './quiz.js';
import { buildChallengeLink, readChallengeFromHash, decodeChallenge, clearHash } from './share.js';
import * as room from './room.js';
import QRCode from 'qrcode';

const $app = document.getElementById('app');
const $pill = document.getElementById('model-pill');
const $pName = document.getElementById('profile-name');
const $pAvatar = document.getElementById('profile-avatar');

const state = {
  screen: 'home',
  me: null,
  mode: 'topic',          // topic | text | category | offline
  modelId: MODELS[0].id,
  count: 5,
  difficulty: 'medium',
  category: CATEGORIES[0].id,
  topicInput: '',
  textInput: '',
  titleInput: '',
  quiz: null,
  answers: [],
  current: 0,
  result: null,
  challenger: null,       // set when playing a received challenge
  busyText: '',
  busyStatus: '',
  webgpu: true,
  // live multiplayer room
  roomActive: false,      // we are in (or joining) a room
  roomPlaying: false,     // currently taking a room challenge
  roomRoster: [],         // [{name, avatar, isMe, score, total, done}]
  roomLog: [],            // recent join/leave system lines
  roomLink: '',           // host: current invite link
  roomAnswer: '',         // joiner: answer token to send back
  roomJoinToken: null,    // joiner: pending offer token from the link
  roomError: '',
};

// ---- helpers --------------------------------------------------------------
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => (
  { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const KEY = ['A', 'B', 'C', 'D', 'E', 'F'];

function setPill(text, cls) {
  $pill.textContent = text;
  $pill.className = 'pill ' + cls;
}
function syncModelPill() {
  if (isReady()) {
    const m = MODELS.find((x) => x.id === currentModelId());
    setPill(`model: ${m?.label || 'ready'} ✓`, 'pill-ready');
  } else {
    setPill('model: not loaded', 'pill-idle');
  }
}
function go(screen) { state.screen = screen; window.scrollTo(0, 0); render(); }

// ---- model loading + generation ------------------------------------------
function setBusyStatus(text) {
  state.busyStatus = text;
  const el = document.getElementById('busy-status');
  if (el) el.textContent = text;
  const bar = document.getElementById('busy-bar');
  const m = text.match(/(\d+)%/);
  if (bar && m) { bar.classList.remove('indet'); bar.style.width = m[1] + '%'; }
}

function setBusyTitle(text) {
  state.busyText = text;
  const el = document.getElementById('busy-title');
  if (el) el.textContent = text;
}

// Generation reports no incremental progress, so show an indeterminate bar
// instead of a frozen 0% one (which looks like a stuck reload).
function setBusyGenerating() {
  setBusyTitle('Writing your quiz…');
  const bar = document.getElementById('busy-bar');
  if (bar) { bar.style.width = ''; bar.classList.add('indet'); }
  setBusyStatus('Generating on your device — questions appear as they’re written…');
  document.getElementById('stream-area')?.classList.remove('hidden');
}

// Live preview: pull completed question texts out of the partial JSON stream so
// the user watches questions pop in as the model writes them.
function onQuizStream(full) {
  const matches = [...full.matchAll(/"question"\s*:\s*"((?:[^"\\]|\\.)*)"/g)]
    .map((m) => m[1].replace(/\\"/g, '"').replace(/\\n/g, ' ').replace(/\\\\/g, '\\'));
  const countEl = document.getElementById('stream-count');
  const listEl = document.getElementById('stream-list');
  if (countEl) countEl.textContent = matches.length
    ? `Drafted ${matches.length} question${matches.length > 1 ? 's' : ''}…`
    : 'Thinking…';
  if (listEl) {
    listEl.innerHTML = matches.map((q, i) =>
      `<div class="stream-q"><span class="stream-n">${i + 1}</span><span>${esc(q)}</span></div>`).join('');
    listEl.scrollTop = listEl.scrollHeight;
  }
}

async function ensureModel() {
  if (isReady() && currentModelId() === state.modelId) return;
  setPill('model: loading…', 'pill-loading');
  await loadModel(state.modelId, ({ pct, text }) => setBusyStatus(`Loading model… ${pct}% — ${text}`));
  syncModelPill();
}

async function handleGenerate() {
  try {
    if (state.mode === 'offline') {
      state.busyText = 'Building your quiz…';
      go('busy');
      const quiz = buildOfflineQuiz({ count: state.count, difficulty: state.difficulty === 'mixed' ? null : state.difficulty });
      await saveQuiz(quiz);
      finishGenerate(quiz);
      return;
    }

    if (!state.webgpu) { alert('WebGPU not available — use Quick Quiz (offline) instead.'); return; }

    let topic = state.topicInput.trim();
    if (state.mode === 'category') topic = pickCategoryTopic(state.category);
    if (state.mode === 'topic' && !topic) { alert('Enter a topic first.'); return; }
    if (state.mode === 'text' && !state.textInput.trim()) { alert('Paste some text first.'); return; }

    // Only show "loading model" when it actually needs loading. Once the model
    // is in memory it stays loaded for the whole session — no reload per quiz.
    const needLoad = !(isReady() && currentModelId() === state.modelId);
    state.busyText = needLoad ? 'Loading the AI model (one time per browser)…' : 'Writing your quiz…';
    state.busyStatus = needLoad ? 'Preparing the model…' : 'Starting…';
    go('busy');
    await ensureModel();
    setBusyGenerating();

    let quiz;
    if (state.mode === 'text') {
      quiz = await createQuizFromText({ text: state.textInput, title: state.titleInput.trim(), count: state.count, difficulty: state.difficulty, onStream: onQuizStream });
    } else {
      quiz = await createQuizFromTopic({ topic, count: state.count, difficulty: state.difficulty, onStream: onQuizStream });
    }
    await saveQuiz(quiz);
    finishGenerate(quiz);
  } catch (err) {
    console.error(err);
    state.busyText = '';
    go('home');
    setTimeout(() => alert('Could not generate the quiz: ' + (err?.message || err)), 50);
  }
}

function startQuiz(quiz, challenger) {
  state.quiz = quiz;
  state.challenger = challenger;
  state.answers = new Array(quiz.questions.length).fill(null);
  state.current = 0;
  state.result = null;
  go('quiz');
}

async function submitQuiz() {
  const result = scoreQuiz(state.quiz, state.answers);
  state.result = result;
  await saveAttempt({ quiz: state.quiz, result, me: state.me, challenger: state.challenger });
  if (state.roomPlaying) {
    state.roomPlaying = false;
    room.reportScore(result.score, result.total);
    state.roomRoster = room.roster();
    go('roomResult');
    return;
  }
  go('result');
}

// ---- live multiplayer room -----------------------------------------------
let connectWatch = null;
function armConnectWatch() {
  clearTimeout(connectWatch);
  connectWatch = setTimeout(() => {
    const peers = room.roster().filter((r) => !r.isMe).length;
    if (peers === 0 && (state.screen === 'roomJoin' || state.screen === 'roomLobby')) {
      state.roomError = 'Still not connected. Check the join code was pasted in full, and that both devices can reach each other — same Wi-Fi or a phone hotspot helps. Strict corporate/mobile NATs can block direct P2P.';
      render();
    }
  }, 25000);
}

// React to any roster/peer change: move a joiner into the lobby the moment a
// peer actually connects, and re-render whichever room screen is showing.
function refreshRoom() {
  const peers = (state.roomRoster || []).filter((r) => !r.isMe).length;
  if (peers > 0) { clearTimeout(connectWatch); state.roomError = ''; }
  if (state.screen === 'roomJoin' && peers > 0) { go('roomLobby'); return; }
  if (['roomLobby', 'roomJoin', 'roomResult'].includes(state.screen)) render();
}

function setupRoomEvents() {
  room.onRoom({
    onRoster: (rows) => { state.roomRoster = rows; refreshRoom(); },
    onChallenge: (quiz) => enterRoomChallenge(quiz),
    onSystem: (text) => { state.roomLog = [...state.roomLog, text].slice(-6); refreshRoom(); },
    onPeerState: (name, st) => {
      if (['failed', 'disconnected', 'closed'].includes(st) && room.roster().filter((r) => !r.isMe).length === 0) {
        state.roomError = 'Connection failed. If this keeps happening, try both devices on the same network/hotspot.';
      }
      state.roomRoster = room.roster();
      refreshRoom();
    },
  });
}

function finishGenerate(quiz) {
  if (state.genTarget === 'room') { state.genTarget = 'self'; room.startChallenge(quiz); }
  else startQuiz(quiz, null);
}

function enterRoomChallenge(quiz) {
  if (!quiz) return;
  state.roomActive = true;
  state.roomPlaying = true;
  startQuiz(quiz, null);
}

async function hostCreateRoom() {
  try {
    state.roomActive = true;
    state.roomError = '';
    state.roomLink = await room.createRoom({ name: state.me.name, avatar: state.me.avatar });
    state.roomRoster = room.roster();
    go('roomLobby');
  } catch (e) { console.error(e); alert('Could not create room: ' + (e?.message || e)); }
}

async function hostAcceptAnswer(token) {
  try { await room.acceptAnswer(token); state.roomLink = ''; state.roomError = ''; armConnectWatch(); render(); }
  catch (e) { state.roomError = 'Invalid join code. Ask them to copy it again.'; render(); }
}

async function hostInviteAnother() {
  try { state.roomLink = await room.nextInviteLink(); render(); }
  catch (e) { alert('Could not create invite: ' + (e?.message || e)); }
}

async function joinerGenerateAnswer() {
  try {
    state.roomActive = true;
    state.roomAnswer = await room.joinRoom({ name: state.me.name, avatar: state.me.avatar }, state.roomJoinToken);
    state.roomRoster = room.roster();
    armConnectWatch();
    render();
  } catch (e) { console.error(e); state.roomError = 'This invite link looks invalid or expired.'; render(); }
}

function leaveRoom() {
  room.leave();
  Object.assign(state, { roomActive: false, roomPlaying: false, roomRoster: [], roomLog: [], roomLink: '', roomAnswer: '', roomJoinToken: null, roomError: '' });
  go('home');
}

// ---- screens --------------------------------------------------------------
function render() {
  syncModelPill();
  $pName.textContent = state.me?.name || 'guest';
  $pAvatar.textContent = state.me?.avatar || '🙂';
  const r = {
    home: renderHome, busy: renderBusy, quiz: renderQuiz,
    result: renderResult, profile: renderProfile, challengeIntro: renderChallengeIntro,
    roomSetup: renderRoomSetup, roomJoin: renderRoomJoin, roomLobby: renderRoomLobby,
    roomResult: renderRoomResult,
  }[state.screen] || renderHome;
  $app.innerHTML = r();
  wire();
}

function modeCard(id, emoji, title, desc) {
  const on = state.mode === id;
  return `<button class="mode-card" data-mode="${id}" style="${on ? 'border-color:var(--primary);background:var(--primary-soft)' : ''}">
    <div class="emoji">${emoji}</div><div class="title">${title}</div><div class="desc">${desc}</div></button>`;
}
function chip(group, value, label) {
  const on = state[group] === value || (group === 'count' && state.count === value);
  return `<button class="chip" data-chip="${group}" data-value="${value}" aria-pressed="${on}">${label}</button>`;
}

function renderHome() {
  const aiMode = state.mode !== 'offline';
  const modelOpts = MODELS.map((m) => `<option value="${m.id}" ${m.id === state.modelId ? 'selected' : ''}>${m.label} — ${m.size} (${m.note})</option>`).join('');
  let inputBlock = '';
  if (state.mode === 'topic') {
    inputBlock = `<label>Topic</label><input type="text" id="topic-input" placeholder="e.g. the water cycle, Roman history, neural networks" value="${esc(state.topicInput)}" />`;
  } else if (state.mode === 'text') {
    inputBlock = `<label>Title (optional)</label><input type="text" id="title-input" placeholder="What is this about?" value="${esc(state.titleInput)}" />
      <label>Paste an article or notes</label><textarea id="text-input" placeholder="Paste the text to be quizzed on…">${esc(state.textInput)}</textarea>
      <p class="tiny muted">The text stays in your browser. (No server fetches the page for you — paste the content here.)</p>`;
  } else if (state.mode === 'category') {
    inputBlock = `<label>Pick a category</label><div class="chips">${CATEGORIES.map((c) =>
      `<button class="chip" data-chip="category" data-value="${c.id}" aria-pressed="${state.category === c.id}">${c.emoji} ${c.label}</button>`).join('')}</div>
      <p class="tiny muted">A random subtopic is chosen so every quiz is fresh.</p>`;
  } else {
    inputBlock = `<div class="banner banner-info">⚡ <strong>Quick Quiz</strong> needs no AI model — questions come from a built-in bank of 500. Great for an instant challenge or when WebGPU isn't available.</div>`;
  }

  return `
  <div class="card">
    <h1>Make a quiz 🧠</h1>
    <p class="sub">AI quizzes generated <strong>entirely in your browser</strong>. Challenge a friend with a link — no accounts, no server.</p>
    <div class="mode-grid">
      ${modeCard('topic', '✍️', 'Topic', 'Type any topic')}
      ${modeCard('text', '📄', 'From text', 'Paste an article')}
      ${modeCard('category', '🎲', 'Category', 'Pick & surprise me')}
      ${modeCard('offline', '⚡', 'Quick Quiz', 'Offline, no model')}
    </div>
    <div class="spacer"></div>
    ${inputBlock}

    <div class="row" style="margin-top:8px">
      <div><label>Questions</label><div class="chips">${[3, 5, 10].map((n) => chip('count', n, n)).join('')}</div></div>
      <div><label>Difficulty</label><div class="chips">${['easy', 'medium', 'hard'].map((d) => chip('difficulty', d, d[0].toUpperCase() + d.slice(1))).join('')}</div></div>
    </div>

    ${aiMode ? `<label>AI model (downloads once, then cached)</label><select id="model-select">${modelOpts}</select>
      ${state.webgpu ? '' : '<div class="banner banner-warn" style="margin-top:10px">⚠️ WebGPU not detected. AI modes need Chrome/Edge 113+. You can still use <strong>Quick Quiz</strong>.</div>'}` : ''}

    <div class="spacer"></div>
    <button class="btn btn-block" id="generate-btn">${aiMode ? '✨ Generate quiz' : '⚡ Start quick quiz'}</button>
    <button class="btn btn-ghost btn-block" id="play-live-btn" style="margin-top:10px">👥 Play live with friends</button>
  </div>

  <div class="card card-soft">
    <h3>Two ways to challenge friends</h3>
    <p class="tiny muted" style="margin:0 0 8px"><strong>By link (async):</strong> finish a quiz → <strong>Challenge a friend</strong>. The quiz + your score pack into a link; they take it anytime and see who won.</p>
    <p class="tiny muted" style="margin:0"><strong>Live room (real-time):</strong> <strong>Play live with friends</strong> → invite people into a peer-to-peer room and race the same quiz together. Still no server.</p>
  </div>`;
}

function renderBusy() {
  return `<div class="card center" style="padding:48px 20px">
    <div class="spin"></div>
    <h2 style="margin-top:14px" id="busy-title">${esc(state.busyText || 'Working…')}</h2>
    <div class="progress-wrap"><div class="progress-track"><div class="progress-bar" id="busy-bar"></div></div></div>
    <p class="muted" id="busy-status">${esc(state.busyStatus || 'Starting…')}</p>
    <div id="stream-area" class="stream-area hidden">
      <p class="tiny muted" id="stream-count">Thinking…</p>
      <div id="stream-list" class="stream-list"></div>
    </div>
    <p class="tiny muted">The model downloads once per browser and is cached — it won't re-download. Generating each quiz still runs the model on your device, which takes a few seconds.</p>
  </div>`;
}

function renderQuiz() {
  const q = state.quiz.questions[state.current];
  const i = state.current;
  const total = state.quiz.questions.length;
  const sel = state.answers[i];
  const opts = q.choices.map((c, idx) => {
    const on = sel === idx;
    return `<button class="option" data-opt="${idx}" aria-pressed="${on}"><span class="key">${KEY[idx]}</span><span>${esc(c)}</span></button>`;
  }).join('');
  const answeredCount = state.answers.filter((a) => a !== null).length;
  return `
  <div class="card">
    <div class="q-meta">
      <span>${esc(state.quiz.title)}</span>
      <span>Question ${i + 1} / ${total}</span>
    </div>
    <div class="progress-track"><div class="progress-bar" style="width:${Math.round(((i) / total) * 100)}%"></div></div>
    <div class="q-text">${esc(q.question)}</div>
    <div class="options">${opts}</div>
    <div class="quiz-nav">
      <button class="btn btn-ghost btn-sm" data-nav="prev" ${i === 0 ? 'disabled' : ''}>← Prev</button>
      <span class="muted tiny" style="align-self:center">${answeredCount}/${total} answered</span>
      ${i < total - 1
        ? `<button class="btn btn-sm" data-nav="next">Next →</button>`
        : `<button class="btn btn-sm" data-nav="submit">Submit ✓</button>`}
    </div>
  </div>`;
}

function renderResult() {
  const r = state.result;
  const quiz = state.quiz;
  let versus = '';
  if (state.challenger) {
    const ch = state.challenger;
    const meWin = r.score > ch.score, tie = r.score === ch.score;
    versus = `<div class="versus">
      <div class="vs-card ${meWin ? 'win' : tie ? '' : 'lose'}"><div class="vs-name">${esc(state.me.avatar)} You</div><div class="vs-score">${r.score}</div><div class="tiny muted">/ ${r.total}</div></div>
      <div class="vs-mid">${meWin ? 'You win! 🏆' : tie ? 'Tie 🤝' : 'You lost'}</div>
      <div class="vs-card ${!meWin && !tie ? 'win' : ''}"><div class="vs-name">${esc(ch.avatar || '🎯')} ${esc(ch.name)}</div><div class="vs-score">${ch.score}</div><div class="tiny muted">/ ${ch.total}</div></div>
    </div>`;
  }
  const review = r.reviewed.map((q, i) => {
    const ok = q.isCorrect;
    const yourAns = q.userAnswer == null ? '<em>skipped</em>' : esc(q.choices[q.userAnswer]);
    return `<div class="review-q">
      <div style="display:flex;gap:8px;align-items:center">
        <span class="badge ${ok ? 'badge-ok' : 'badge-no'}">${ok ? 'Correct' : 'Wrong'}</span>
        <strong>${i + 1}. ${esc(q.question)}</strong>
      </div>
      <div class="ans">Your answer: ${yourAns}${ok ? '' : ` · Correct: <strong>${esc(q.choices[q.answerIndex])}</strong>`}</div>
      ${q.explanation ? `<div class="exp">${esc(q.explanation)}</div>` : ''}
    </div>`;
  }).join('');

  return `
  <div class="card">
    <div class="score-hero">
      <div class="score-big">${r.score}/${r.total}</div>
      <div class="score-sub">${r.percentage}% · ${esc(quiz.title)}</div>
    </div>
    ${versus}
    <div class="row">
      <button class="btn" id="challenge-btn">🔗 Challenge a friend</button>
      <button class="btn btn-ghost" data-go="retry">↻ Try again</button>
      <button class="btn btn-ghost" data-go="home">🏠 New quiz</button>
    </div>
    <div id="challenge-link-area"></div>
  </div>
  <div class="card">
    <h2>Review</h2>
    ${review}
  </div>`;
}

function renderChallengeIntro() {
  const c = state.incomingChallenge;
  const ch = c.challenger || {};
  return `<div class="card center">
    <div style="font-size:42px">${esc(ch.avatar || '🎯')}</div>
    <h1>${esc(ch.name || 'A friend')} challenged you!</h1>
    <p class="sub">Topic: <strong>${esc(c.title)}</strong> · ${c.questions.length} questions</p>
    <div class="versus" style="justify-content:center">
      <div class="vs-card"><div class="vs-name">${esc(ch.name || 'Them')}</div><div class="vs-score">${ch.score ?? '–'}</div><div class="tiny muted">/ ${ch.total ?? c.questions.length}</div></div>
      <div class="vs-mid">vs</div>
      <div class="vs-card"><div class="vs-name">${esc(state.me.avatar)} You</div><div class="vs-score">?</div><div class="tiny muted">beat the score</div></div>
    </div>
    <button class="btn btn-block" id="accept-challenge">Take the challenge →</button>
    <button class="btn btn-ghost btn-block" data-go="home" style="margin-top:10px">Skip</button>
  </div>`;
}

// ---- room screens ---------------------------------------------------------
function rosterRows() {
  const rows = state.roomRoster.length ? state.roomRoster : room.roster();
  if (!rows.length) return '<tr><td colspan="3" class="empty">No one here yet.</td></tr>';
  const ranked = [...rows].sort((a, b) => (b.score ?? -1) - (a.score ?? -1));
  return ranked.map((m, i) => {
    const done = m.done && m.total != null;
    const score = done ? `${m.score}/${m.total}` : (m.score != null ? '…' : '<span class="tiny muted">waiting</span>');
    return `<tr class="${m.isMe ? 'me' : ''}">
      <td class="rank ${i === 0 && done ? 'rank-1' : ''}">${i === 0 && done ? '🥇' : i + 1}</td>
      <td><span class="dot dot-on" title="connected"></span>${esc(m.avatar)} ${esc(m.name)}${m.isMe ? ' <span class="tiny muted">(you)</span>' : ''}</td>
      <td>${score}</td></tr>`;
  }).join('');
}

function connectingNote() {
  const n = room.connectingCount();
  return n ? `<div class="tiny muted" style="margin-top:8px"><span class="dot dot-wait"></span>${n} connecting…</div>` : '';
}

function renderRoomSetup() {
  return `<div class="card">
    <h1>Play live with friends 👥</h1>
    <p class="sub">Create a room and invite people with a link. Everyone connects directly, peer-to-peer — still no server.</p>
    <button class="btn btn-block" id="create-room">Create a room →</button>
    <button class="btn btn-ghost btn-block" data-go="home" style="margin-top:10px">← Back</button>
    <p class="tiny muted" style="margin-top:14px">To join a room instead, just open the invite link your friend sends you.</p>
  </div>`;
}

function renderRoomJoin() {
  const c = state.incomingChallenge; // not used; join uses token
  if (state.roomAnswer) {
    return `<div class="card center">
      <div style="font-size:40px">🤝</div>
      <h1>Almost in!</h1>
      <p class="sub">Send this <strong>join code</strong> back to the host. Once they paste it, you're connected.</p>
      <div class="link-box"><input type="text" id="answer-token" value="${esc(state.roomAnswer)}" readonly /><button class="btn btn-sm" id="copy-answer">Copy</button></div>
      <div id="answer-copied" class="tiny" style="margin-top:6px"></div>
      <p class="tiny muted" style="margin-top:14px">Waiting for the host to connect you… this screen will update when the room is live.</p>
      <div class="card-soft card" style="margin-top:16px;text-align:left"><h3>Room</h3><table class="lb"><tbody>${rosterRows()}</tbody></table>${connectingNote()}</div>
      <button class="btn btn-ghost btn-block" id="leave-room" style="margin-top:10px">Leave</button>
    </div>`;
  }
  return `<div class="card center">
    <div style="font-size:40px">🎉</div>
    <h1>You're invited to a live room</h1>
    <p class="sub">Joining as <strong>${esc(state.me.avatar)} ${esc(state.me.name)}</strong></p>
    ${state.roomError ? `<div class="banner banner-warn">${esc(state.roomError)}</div>` : ''}
    <button class="btn btn-block" id="join-room">Generate my join code →</button>
    <button class="btn btn-ghost btn-block" data-go="home" style="margin-top:10px">Skip</button>
  </div>`;
}

function renderRoomLobby() {
  const connected = (state.roomRoster.length ? state.roomRoster : room.roster()).length;
  const aiMode = state.mode !== 'offline';
  const log = state.roomLog.slice(-4).map((l) => `<div class="tiny muted">• ${esc(l)}</div>`).join('');
  const hostControls = room.amHost() ? `
    <div class="card card-soft">
      <h3>Invite people</h3>
      ${state.roomLink ? `<div class="link-box"><input type="text" id="invite-link" value="${esc(state.roomLink)}" readonly /><button class="btn btn-sm" id="copy-invite">Copy</button></div>
        <div id="invite-copied" class="tiny" style="margin-top:6px"></div>
        <div class="qr-wrap"><canvas id="qr-code" class="qr"></canvas><span class="tiny muted">Scan to join from a phone</span></div>
        <label>Paste their join code</label>
        <div class="link-box"><input type="text" id="answer-input" placeholder="join code from your friend" /><button class="btn btn-sm" id="connect-answer">Connect</button></div>
        ${state.roomError ? `<div class="banner banner-warn" style="margin-top:8px">${esc(state.roomError)}</div>` : ''}`
        : `<button class="btn btn-sm" id="invite-another">+ Invite another player</button>`}
    </div>
    <div class="card">
      <h3>Start a challenge for the room</h3>
      <div class="chips">${['topic', 'category', 'offline'].map((m) => `<button class="chip" data-rmode="${m}" aria-pressed="${state.mode === m}">${m === 'topic' ? '✍️ Topic' : m === 'category' ? '🎲 Category' : '⚡ Quick'}</button>`).join('')}</div>
      ${state.mode === 'topic' ? `<label>Topic</label><input type="text" id="topic-input" placeholder="e.g. space, history, JavaScript" value="${esc(state.topicInput)}" />` : ''}
      ${state.mode === 'category' ? `<label>Category</label><div class="chips">${CATEGORIES.map((c) => `<button class="chip" data-chip="category" data-value="${c.id}" aria-pressed="${state.category === c.id}">${c.emoji} ${c.label}</button>`).join('')}</div>` : ''}
      <div class="row" style="margin-top:8px">
        <div><label>Questions</label><div class="chips">${[3, 5, 10].map((n) => `<button class="chip" data-chip="count" data-value="${n}" aria-pressed="${state.count === n}">${n}</button>`).join('')}</div></div>
        <div><label>Difficulty</label><div class="chips">${['easy', 'medium', 'hard'].map((d) => `<button class="chip" data-chip="difficulty" data-value="${d}" aria-pressed="${state.difficulty === d}">${d[0].toUpperCase() + d.slice(1)}</button>`).join('')}</div></div>
      </div>
      ${aiMode && !state.webgpu ? '<div class="banner banner-warn" style="margin-top:8px">⚠️ No WebGPU — use Quick for the room.</div>' : ''}
      <div class="spacer"></div>
      <button class="btn btn-block" id="start-challenge">🚀 Start challenge for everyone</button>
    </div>` : `<div class="card card-soft"><p class="muted" style="margin:0">Waiting for the host to start a challenge…</p></div>`;

  return `
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center">
      <h1 style="margin:0">Room lobby</h1>
      <span class="pill pill-ready">${connected} connected</span>
    </div>
    <p class="sub" style="margin-top:6px">${room.amHost() ? 'You are the host.' : 'Connected to the room.'} Everyone who joins plays the same quizzes live.</p>
    <table class="lb"><thead><tr><th>#</th><th>Player</th><th>Score</th></tr></thead><tbody>${rosterRows()}</tbody></table>
    ${connectingNote()}
    ${log ? `<div style="margin-top:10px">${log}</div>` : ''}
  </div>
  ${hostControls}
  <button class="btn btn-ghost btn-block" id="leave-room">Leave room</button>`;
}

function renderRoomResult() {
  const r = state.result;
  return `
  <div class="card">
    <div class="score-hero">
      <div class="score-big">${r.score}/${r.total}</div>
      <div class="score-sub">${r.percentage}% · ${esc(state.quiz.title)}</div>
    </div>
    <h2>Live room scores</h2>
    <p class="tiny muted">Updates as each player finishes.</p>
    <table class="lb"><thead><tr><th>#</th><th>Player</th><th>Score</th></tr></thead><tbody>${rosterRows()}</tbody></table>
    <div class="spacer"></div>
    <button class="btn btn-block" id="back-to-lobby">← Back to lobby</button>
    <button class="btn btn-ghost btn-block" id="leave-room" style="margin-top:10px">Leave room</button>
  </div>`;
}

async function renderProfileData() {
  const board = await leaderboard();
  const history = (await allAttempts()).slice(0, 15);
  const lbRows = board.length ? board.map((e, i) => `<tr class="${e.isMe ? 'me' : ''}">
    <td class="rank ${i === 0 ? 'rank-1' : ''}">${i === 0 ? '🥇' : i + 1}</td>
    <td>${esc(e.avatar)} ${esc(e.name)}${e.isMe ? ' <span class="tiny muted">(you)</span>' : ''}</td>
    <td>${e.percentage}%</td><td class="tiny muted">${e.score}/${e.total}</td></tr>`).join('')
    : '<tr><td colspan="4" class="empty">No scores yet — take a quiz!</td></tr>';
  const histRows = history.length ? history.map((a) => `<tr>
    <td>${esc(a.title)}</td><td>${a.score}/${a.total}</td><td>${a.percentage}%</td>
    <td class="tiny muted">${new Date(a.createdAt).toLocaleDateString()}</td>
    <td>${a.challenger ? `vs ${esc(a.challenger.name)}` : ''}</td></tr>`).join('')
    : '<tr><td colspan="5" class="empty">No history yet.</td></tr>';

  const el = document.getElementById('profile-data');
  if (el) el.innerHTML = `
    <div class="card"><h2>🏆 Local leaderboard</h2>
      <p class="tiny muted">Best score per player — you, plus everyone whose challenge links you've played.</p>
      <table class="lb"><thead><tr><th>#</th><th>Player</th><th>Best</th><th>Raw</th></tr></thead><tbody>${lbRows}</tbody></table>
    </div>
    <div class="card"><h2>📜 Recent quizzes</h2>
      <table class="lb"><thead><tr><th>Quiz</th><th>Score</th><th>%</th><th>When</th><th></th></tr></thead><tbody>${histRows}</tbody></table>
    </div>`;
}

function renderProfile() {
  const me = state.me;
  const avatars = ['🦊', '🦉', '🐱', '🐼', '🦅', '🐯', '🐺', '🐧', '🦁', '🐨', '🦄', '🐙', '🤖', '👾', '🎯', '🧠'];
  return `
  <div class="card">
    <h1>Your profile</h1>
    <p class="sub">Stored only in this browser. No account, no server.</p>
    <label>Name</label><input type="text" id="name-input" value="${esc(me.name)}" maxlength="24" />
    <label>Avatar</label>
    <div class="chips" id="avatar-pick">${avatars.map((a) => `<button class="chip" data-avatar="${a}" aria-pressed="${a === me.avatar}">${a}</button>`).join('')}</div>
    <div class="spacer"></div>
    <button class="btn btn-sm" id="save-profile">Save</button>
    <button class="btn btn-ghost btn-sm" data-go="home">← Back</button>
  </div>
  <div id="profile-data"><div class="card"><p class="muted">Loading…</p></div></div>`;
}

// ---- event wiring ---------------------------------------------------------
function wire() {
  // mode cards
  $app.querySelectorAll('[data-mode]').forEach((b) => b.onclick = () => { state.mode = b.dataset.mode; render(); });
  // chips
  $app.querySelectorAll('[data-chip]').forEach((b) => b.onclick = () => {
    const g = b.dataset.chip; let v = b.dataset.value;
    if (g === 'count') v = Number(v);
    state[g] = v; render();
  });
  // inputs (preserve without full re-render)
  const ti = document.getElementById('topic-input'); if (ti) ti.oninput = (e) => state.topicInput = e.target.value;
  const tx = document.getElementById('text-input'); if (tx) tx.oninput = (e) => state.textInput = e.target.value;
  const tt = document.getElementById('title-input'); if (tt) tt.oninput = (e) => state.titleInput = e.target.value;
  const ms = document.getElementById('model-select'); if (ms) ms.onchange = (e) => { state.modelId = e.target.value; };
  const gen = document.getElementById('generate-btn'); if (gen) gen.onclick = handleGenerate;

  // quiz
  $app.querySelectorAll('[data-opt]').forEach((b) => b.onclick = () => {
    state.answers[state.current] = Number(b.dataset.opt);
    render();
  });
  $app.querySelectorAll('[data-nav]').forEach((b) => b.onclick = () => {
    const n = b.dataset.nav;
    if (n === 'prev') state.current = Math.max(0, state.current - 1);
    else if (n === 'next') state.current = Math.min(state.quiz.questions.length - 1, state.current + 1);
    else if (n === 'submit') return submitQuiz();
    render();
  });

  // result / nav
  $app.querySelectorAll('[data-go]').forEach((b) => b.onclick = () => {
    const t = b.dataset.go;
    if (t === 'home') { state.challenger = null; go('home'); }
    else if (t === 'retry') startQuiz(state.quiz, state.challenger);
  });
  const cb = document.getElementById('challenge-btn'); if (cb) cb.onclick = onChallengeClick;
  const ac = document.getElementById('accept-challenge'); if (ac) ac.onclick = acceptChallenge;

  // room
  const pl = document.getElementById('play-live-btn'); if (pl) pl.onclick = () => go('roomSetup');
  const cr = document.getElementById('create-room'); if (cr) cr.onclick = hostCreateRoom;
  const jr = document.getElementById('join-room'); if (jr) jr.onclick = joinerGenerateAnswer;
  const ia = document.getElementById('invite-another'); if (ia) ia.onclick = hostInviteAnother;
  const sc = document.getElementById('start-challenge'); if (sc) sc.onclick = () => { state.genTarget = 'room'; handleGenerate(); };
  const bl = document.getElementById('back-to-lobby'); if (bl) bl.onclick = () => go('roomLobby');
  $app.querySelectorAll('[id=leave-room]').forEach((b) => b.onclick = leaveRoom);
  $app.querySelectorAll('[data-rmode]').forEach((b) => b.onclick = () => { state.mode = b.dataset.rmode; render(); });
  const cAns = document.getElementById('connect-answer');
  if (cAns) cAns.onclick = () => hostAcceptAnswer((document.getElementById('answer-input').value || '').trim());
  copyField('copy-invite', 'invite-link', () => state.roomLink, 'invite-copied', 'EasyQZ live room', 'Join my live quiz room!');
  copyField('copy-answer', 'answer-token', () => state.roomAnswer, 'answer-copied');
  const qr = document.getElementById('qr-code');
  if (qr && state.roomLink) {
    QRCode.toCanvas(qr, state.roomLink, { width: 176, margin: 1, errorCorrectionLevel: 'L' }, (err) => {
      if (err) qr.closest('.qr-wrap')?.classList.add('hidden'); // link too long for a scannable QR
    });
  }

  // profile
  const sp = document.getElementById('save-profile');
  if (sp) sp.onclick = async () => {
    const name = (document.getElementById('name-input').value || '').trim() || state.me.name;
    state.me = await updateMe({ name, avatar: state.me.avatar });
    render();
  };
  $app.querySelectorAll('[data-avatar]').forEach((b) => b.onclick = async () => {
    state.me = await updateMe({ avatar: b.dataset.avatar });
    render();
  });
  if (state.screen === 'profile') renderProfileData();
}

async function onChallengeClick() {
  const area = document.getElementById('challenge-link-area');
  area.innerHTML = '<p class="muted tiny">Building link…</p>';
  const link = await buildChallengeLink({
    quiz: state.quiz,
    challenger: { name: state.me.name, avatar: state.me.avatar, score: state.result.score, total: state.result.total },
  });
  area.innerHTML = `
    <div class="banner banner-info" style="margin-top:14px">
      <strong>Send this link.</strong> Your friend takes the same quiz and tries to beat ${state.result.score}/${state.result.total}.
      <div class="link-box"><input type="text" id="ch-link" value="${esc(link)}" readonly /><button class="btn btn-sm" id="copy-link">Copy</button></div>
      <div id="copy-ok" class="tiny" style="margin-top:6px"></div>
    </div>`;
  document.getElementById('copy-link').onclick = async () => {
    try {
      if (navigator.share) { await navigator.share({ title: 'EasyQZ challenge', text: `Beat my score on "${state.quiz.title}"!`, url: link }); }
      else { await navigator.clipboard.writeText(link); document.getElementById('copy-ok').textContent = 'Copied ✓'; }
    } catch { try { await navigator.clipboard.writeText(link); document.getElementById('copy-ok').textContent = 'Copied ✓'; } catch {} }
  };
  document.getElementById('ch-link').onclick = (e) => e.target.select();
}

async function acceptChallenge() {
  const c = state.incomingChallenge;
  const quiz = { id: c.quizId, topic: c.topic, title: c.title, difficulty: 'shared', source: 'challenge', questions: c.questions, createdAt: Date.now() };
  await saveQuiz(quiz);
  startQuiz(quiz, c.challenger);
}

// Generic copy/share wiring for a read-only token/link field.
function copyField(btnId, inputId, getValue, okId, shareTitle, shareText) {
  const btn = document.getElementById(btnId);
  if (!btn) return;
  const inp = document.getElementById(inputId);
  if (inp) inp.onclick = (e) => e.target.select();
  const flash = () => { const ok = document.getElementById(okId); if (ok) ok.textContent = 'Copied ✓'; };
  btn.onclick = async () => {
    const val = getValue();
    try {
      if (shareTitle && navigator.share) await navigator.share({ title: shareTitle, text: shareText, url: val });
      else { await navigator.clipboard.writeText(val); flash(); }
    } catch { try { await navigator.clipboard.writeText(val); flash(); } catch {} }
  };
}

// ---- boot -----------------------------------------------------------------
async function boot() {
  state.me = await getMe();
  state.webgpu = await checkWebGPU();
  document.getElementById('webgpu-note').textContent = state.webgpu ? 'WebGPU ready' : 'WebGPU off — Quick Quiz only';

  document.getElementById('brand-home').onclick = () => { state.challenger = null; go('home'); };
  document.getElementById('brand-home').onkeydown = (e) => { if (e.key === 'Enter') go('home'); };
  document.getElementById('profile-btn').onclick = () => go('profile');

  setupRoomEvents();

  // A live-room invite link?
  const roomToken = room.readRoomFromHash();
  if (roomToken) {
    state.roomJoinToken = roomToken;
    clearHash();
    go('roomJoin');
    return;
  }

  const token = readChallengeFromHash();
  if (token) {
    try {
      state.incomingChallenge = await decodeChallenge(token);
      clearHash();
      go('challengeIntro');
      return;
    } catch (e) {
      console.error('Bad challenge link', e);
      clearHash();
    }
  }
  render();
}

boot();
