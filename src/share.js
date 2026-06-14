// Async, serverless challenges. The entire challenge — questions, answers, and
// the challenger's score — is packed into the invite link's URL hash. The
// recipient opens it anytime, takes the same quiz locally, and compares.
//
// Compression + URL-safe base64 is reused from AgentHerd's encodeSDP/decodeSDP
// (it packed WebRTC SDP the same way; here we pack a challenge payload instead).

async function pack(obj) {
  const json = JSON.stringify(obj);
  const cs = new CompressionStream('deflate-raw');
  const w = cs.writable.getWriter();
  w.write(new TextEncoder().encode(json));
  w.close();
  const buf = await new Response(cs.readable).arrayBuffer();
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function unpack(token) {
  const b64 = token.trim().replace(/-/g, '+').replace(/_/g, '/');
  const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
  const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
  const ds = new DecompressionStream('deflate-raw');
  const w = ds.writable.getWriter();
  w.write(bytes);
  w.close();
  const buf = await new Response(ds.readable).arrayBuffer();
  return JSON.parse(new TextDecoder().decode(buf));
}

// Strip per-attempt fields so the link carries only the quiz + challenger score.
function slimQuestions(questions) {
  return questions.map((q) => ({
    q: q.question,
    c: q.choices,
    a: q.answerIndex,
    e: q.explanation || '',
  }));
}

function fattenQuestions(slim) {
  return slim.map((s, i) => ({
    id: `q${i}`,
    question: s.q,
    choices: s.c,
    answerIndex: s.a,
    explanation: s.e || '',
    userAnswer: null,
  }));
}

export async function buildChallengeLink({ quiz, challenger }) {
  const payload = {
    v: 1,
    quizId: quiz.id,
    topic: quiz.topic,
    title: quiz.title || quiz.topic,
    questions: slimQuestions(quiz.questions),
    challenger, // { name, avatar, score, total }
  };
  const token = await pack(payload);
  return `${location.origin}${location.pathname}#challenge=${token}`;
}

export function readChallengeFromHash() {
  const m = location.hash.match(/challenge=([^&]+)/);
  return m ? m[1] : null;
}

export async function decodeChallenge(token) {
  const p = await unpack(token);
  return {
    quizId: p.quizId,
    topic: p.topic,
    title: p.title || p.topic,
    questions: fattenQuestions(p.questions),
    challenger: p.challenger,
  };
}

export function clearHash() {
  history.replaceState(null, '', location.pathname + location.search);
}
