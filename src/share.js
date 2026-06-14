// Async, serverless challenges. The entire challenge — questions, answers, and
// the challenger's score — is packed into the invite link's URL hash. The
// recipient opens it anytime, takes the same quiz locally, and compares.
import { pack, unpack } from './codec.js';

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
