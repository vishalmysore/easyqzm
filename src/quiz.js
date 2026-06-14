// Quiz creation, scoring, and persistence. Two creation paths:
//   1. AI mode  — local WebLLM model generates questions (topic / pasted text)
//   2. Offline  — no model needed; builds MCQs from the bundled challenge bank
import { generateQuiz } from './llm.js';
import { CHALLENGE_BANK } from '../challenge-bank.js';
import { db } from './db.js';
import { uid } from './identity.js';

// Category presets — a chosen category picks a random subtopic to quiz on.
export const CATEGORIES = [
  { id: 'science', emoji: '🔬', label: 'Science', subs: ['chemistry', 'gravity', 'the solar system', 'cells and biology', 'electricity', 'evolution'] },
  { id: 'math', emoji: '➗', label: 'Math', subs: ['algebra', 'geometry', 'percentages', 'probability', 'number theory'] },
  { id: 'history', emoji: '🏛️', label: 'History', subs: ['ancient civilizations', 'world wars', 'the Renaissance', 'the industrial revolution', 'modern history'] },
  { id: 'geography', emoji: '🌍', label: 'Geography', subs: ['continents and oceans', 'mountains and rivers', 'climate', 'capitals of the world', 'natural disasters'] },
  { id: 'tech', emoji: '💻', label: 'Technology', subs: ['artificial intelligence', 'the internet', 'cybersecurity', 'programming basics', 'computer hardware'] },
  { id: 'sports', emoji: '⚽', label: 'Sports', subs: ['football', 'cricket', 'tennis', 'the Olympics', 'basketball'] },
  { id: 'gk', emoji: '🧠', label: 'General Knowledge', subs: ['world cultures', 'famous inventions', 'space exploration', 'literature', 'art and music'] },
];

export function pickCategoryTopic(catId) {
  const c = CATEGORIES.find((x) => x.id === catId);
  if (!c) return catId;
  return c.subs[Math.floor(Math.random() * c.subs.length)];
}

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// --- AI mode ---------------------------------------------------------------
export async function createQuizFromTopic({ topic, count, difficulty }) {
  const questions = await generateQuiz({ topic, count, difficulty });
  return makeQuiz({ topic, title: topic, difficulty, questions, source: 'ai-topic' });
}

export async function createQuizFromText({ text, title, count, difficulty }) {
  const questions = await generateQuiz({ sourceText: text, topic: title || 'your text', count, difficulty });
  return makeQuiz({ topic: title || 'Pasted text', title: title || 'Pasted text', difficulty, questions, source: 'ai-text' });
}

// --- Offline mode (no model) ----------------------------------------------
// Turns single-answer bank items into MCQs by sampling distractors from peers.
export function buildOfflineQuiz({ count = 5, difficulty = null, type = null } = {}) {
  let pool = CHALLENGE_BANK.slice();
  if (difficulty) pool = pool.filter((q) => q.difficulty === difficulty);
  if (type) pool = pool.filter((q) => q.type === type);
  if (pool.length < count) pool = CHALLENGE_BANK.slice();

  const picked = shuffle(pool).slice(0, count);
  const questions = picked.map((item, i) => {
    const sameType = CHALLENGE_BANK.filter((q) => q.type === item.type && q.answer !== item.answer);
    const distractors = shuffle(sameType)
      .map((q) => String(q.answer))
      .filter((a, idx, self) => a !== String(item.answer) && self.indexOf(a) === idx)
      .slice(0, 3);
    while (distractors.length < 3) distractors.push(String(Math.floor(Math.random() * 1000)));
    const choices = shuffle([String(item.answer), ...distractors]);
    return {
      id: `q${i}`,
      question: item.question,
      choices,
      answerIndex: choices.indexOf(String(item.answer)),
      explanation: '',
      userAnswer: null,
    };
  });
  return makeQuiz({ topic: 'Quick Quiz', title: 'Quick Quiz (offline)', difficulty: difficulty || 'mixed', questions, source: 'offline' });
}

function makeQuiz({ topic, title, difficulty, questions, source }) {
  return {
    id: uid('quiz'),
    topic,
    title,
    difficulty,
    source,
    questions,
    createdAt: Date.now(),
  };
}

// --- Scoring ---------------------------------------------------------------
export function scoreQuiz(quiz, answers) {
  // answers: array aligned to quiz.questions, each = selected index or null
  let correct = 0, incorrect = 0, skipped = 0;
  const reviewed = quiz.questions.map((q, i) => {
    const ua = answers[i];
    const isSkipped = ua === null || ua === undefined;
    const isCorrect = !isSkipped && ua === q.answerIndex;
    if (isSkipped) skipped++;
    else if (isCorrect) correct++;
    else incorrect++;
    return { ...q, userAnswer: isSkipped ? null : ua, isCorrect };
  });
  const total = quiz.questions.length;
  const percentage = total ? Math.round((correct / total) * 100) : 0;
  return { correct, incorrect, skipped, total, score: correct, percentage, reviewed };
}

// --- Persistence -----------------------------------------------------------
export async function saveQuiz(quiz) {
  await db.put('quizzes', quiz);
  return quiz;
}

export async function saveAttempt({ quiz, result, me, challenger }) {
  const attempt = {
    id: uid('att'),
    quizId: quiz.id,
    topic: quiz.topic,
    title: quiz.title,
    userId: me.userId,
    name: me.name,
    avatar: me.avatar,
    score: result.score,
    total: result.total,
    percentage: result.percentage,
    createdAt: Date.now(),
    challenger: challenger || null, // present when this was a received challenge
  };
  await db.put('attempts', attempt);
  return attempt;
}

export async function allAttempts() {
  const rows = await db.getAll('attempts');
  return rows.sort((a, b) => b.createdAt - a.createdAt);
}

// Local leaderboard: best % per participant, aggregated across every attempt
// and every challenger score that has passed through this browser.
export async function leaderboard() {
  const rows = await db.getAll('attempts');
  const board = new Map();
  const bump = (key, entry) => {
    const cur = board.get(key);
    if (!cur || entry.percentage > cur.percentage) board.set(key, entry);
  };
  for (const a of rows) {
    bump(a.userId || a.name, {
      name: a.name, avatar: a.avatar, percentage: a.percentage,
      score: a.score, total: a.total, isMe: true,
    });
    if (a.challenger && a.challenger.name) {
      const pct = a.challenger.total ? Math.round((a.challenger.score / a.challenger.total) * 100) : 0;
      bump('ch_' + a.challenger.name, {
        name: a.challenger.name, avatar: a.challenger.avatar || '🎯',
        percentage: pct, score: a.challenger.score, total: a.challenger.total, isMe: false,
      });
    }
  }
  return [...board.values()].sort((a, b) => b.percentage - a.percentage);
}
