// Live multiplayer rooms — the AgentHerd way: a full WebRTC mesh with the invite
// link as the handshake (offer in the link, answer token pasted back). No server.
//
// Topology & signaling are ported from AgentHerd: each joiner connects to the
// host first; the host then relays `signal` messages so every newcomer forms a
// DIRECT data channel with every existing member (full mesh). On top of that we
// run a tiny quiz protocol: room-challenge (start the same quiz for everyone)
// and room-score (broadcast results) → a live room leaderboard.
import { PeerManager } from './peer-manager.js';
import { encodeSDP, decodeSDP } from './codec.js';

let pm = null;
let me = null;            // { name, avatar }
let isHost = false;
let slotSeq = 0;
let pendingSlot = null;   // host: slot awaiting an answer token
let currentChallenge = null; // { quizId, title, questions }
const scores = new Map(); // name -> { score, total, done }
const avatars = new Map(); // name -> avatar emoji
let handlers = {};

export function onRoom(h) { handlers = h || {}; }
function emit(ev, ...a) { handlers[ev]?.(...a); }

export function inRoom() { return !!pm; }
export function amHost() { return isHost; }
export function myName() { return me?.name; }
export function getChallenge() { return currentChallenge; }

function ensurePM() {
  if (pm) return;
  pm = new PeerManager({
    myName: me.name,
    myPersona: me.avatar,   // reuse the persona slot to carry our avatar emoji
    myModelLabel: '',
    onPeerJoin: handlePeerJoin,
    onPeerLeave: handlePeerLeave,
    onMessage: handleMsg,
    onPeerState: (name, st) => emit('onPeerState', name, st),
  });
}

// ---- roster / scores ------------------------------------------------------
function setScore(name, score, total, done) { scores.set(name, { score, total, done }); }
function resetScores() { scores.clear(); if (me) scores.set(me.name, { score: 0, total: 0, done: false }); }

export function roster() {
  const rows = [];
  const add = (name, avatar, isMe) => {
    const s = scores.get(name);
    rows.push({ name, avatar: avatar || '🎯', isMe, score: s?.score ?? null, total: s?.total ?? null, done: !!s?.done });
  };
  if (me) add(me.name, me.avatar, true);
  for (const p of pm?.getConnected() ?? []) add(p.name, avatars.get(p.name) || p.persona, false);
  return rows;
}

// ---- host: create room & grow it -----------------------------------------
export async function createRoom(identity) {
  me = identity; isHost = true; ensurePM();
  return nextInviteLink();
}

export async function nextInviteLink() {
  const slot = `slot-${++slotSeq}`;
  const sdp = await pm.createOffer(slot);
  pendingSlot = slot;
  return `${location.origin}${location.pathname}#room=${await encodeSDP(sdp)}`;
}

export async function acceptAnswer(token) {
  if (!pendingSlot) throw new Error('No invite is awaiting an answer.');
  await pm.setAnswer(pendingSlot, await decodeSDP(token));
  pendingSlot = null;
}

// ---- joiner: open invite link & produce an answer token -------------------
export async function joinRoom(identity, offerToken) {
  me = identity; isHost = false; ensurePM();
  const offer = await decodeSDP(offerToken);
  const sdp = await pm.acceptOffer('host', offer);
  return await encodeSDP(sdp); // send this token back to the host
}

// ---- quiz protocol --------------------------------------------------------
function slim(questions) {
  return questions.map((q) => ({ q: q.question, c: q.choices, a: q.answerIndex, e: q.explanation || '' }));
}
function fatten(slimQs) {
  return slimQs.map((s, i) => ({ id: `q${i}`, question: s.q, choices: s.c, answerIndex: s.a, explanation: s.e || '', userAnswer: null }));
}

export function startChallenge(quiz) {
  currentChallenge = { quizId: quiz.id, title: quiz.title, questions: slim(quiz.questions) };
  resetScores();
  pm.broadcast({ type: 'room-challenge', ...currentChallenge });
  emit('onChallenge', challengeForPlay());
}

export function challengeForPlay() {
  if (!currentChallenge) return null;
  return {
    id: currentChallenge.quizId, title: currentChallenge.title,
    topic: currentChallenge.title, difficulty: 'room', source: 'room',
    questions: fatten(currentChallenge.questions), createdAt: Date.now(),
  };
}

export function reportScore(score, total) {
  setScore(me.name, score, total, true);
  pm.broadcast({ type: 'room-score', name: me.name, avatar: me.avatar, score, total });
  emit('onRoster', roster());
}

export function leave() {
  try { for (const p of pm?.getConnected() ?? []) p.channel?.close?.(); } catch {}
  pm = null; me = null; isHost = false; pendingSlot = null; currentChallenge = null;
  scores.clear(); avatars.clear();
}

// ---- peer events & mesh signaling (ported from AgentHerd) ------------------
function handlePeerJoin(name, hello) {
  avatars.set(name, hello.persona || '🎯');
  emit('onSystem', `${name} joined`);
  emit('onRoster', roster());

  // Bring a late joiner into an in-progress challenge.
  if (currentChallenge) pm.sendTo(name, { type: 'room-challenge', ...currentChallenge });

  // Host gossips existing members to the newcomer and asks each to offer to it.
  if (isHost) {
    const others = pm.getConnected().filter((p) => p.name !== name);
    if (others.length) {
      pm.sendTo(name, { type: 'room-members', members: others.map((p) => ({ name: p.name, avatar: avatars.get(p.name) })) });
      for (const op of others) pm.sendTo(op.name, { type: 'make-offer-for', target: name });
    }
  }
}

function handlePeerLeave(name) {
  scores.delete(name); avatars.delete(name);
  emit('onSystem', `${name} left`);
  emit('onRoster', roster());
}

async function handleMsg(fromName, msg) {
  switch (msg.type) {
    case 'make-offer-for': await makeOfferFor(msg.target, fromName); break;
    case 'signal':         await handleSignal(fromName, msg); break;
    case 'room-members':   break; // direct offers arrive via 'signal'
    case 'room-challenge':
      currentChallenge = { quizId: msg.quizId, title: msg.title, questions: msg.questions };
      resetScores();
      emit('onChallenge', challengeForPlay());
      break;
    case 'room-score':
      avatars.set(msg.name, msg.avatar || avatars.get(msg.name));
      setScore(msg.name, msg.score, msg.total, true);
      emit('onRoster', roster());
      break;
  }
}

async function makeOfferFor(target, relay) {
  const sdp = await pm.createOffer(target);
  pm.sendTo(relay, { type: 'signal', to: target, from: me.name, payload: { type: 'offer', sdp: { type: sdp.type, sdp: sdp.sdp } } });
}

async function handleSignal(fromName, msg) {
  const { to, from, payload } = msg;
  if (isHost) { pm.sendTo(to, msg); return; } // host is the relay
  if (to !== me.name) return;
  if (payload.type === 'offer') {
    const sdp = await pm.acceptOffer(from, payload.sdp);
    pm.sendTo(fromName, { type: 'signal', to: from, from: me.name, payload: { type: 'answer', sdp: { type: sdp.type, sdp: sdp.sdp } } });
  } else if (payload.type === 'answer') {
    await pm.setAnswer(from, payload.sdp);
  }
}

export function readRoomFromHash() {
  const m = location.hash.match(/room=([^&]+)/);
  return m ? m[1] : null;
}
