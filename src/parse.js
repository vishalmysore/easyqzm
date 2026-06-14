// Robust parsing of model output into quiz questions.
// Small local models (esp. 1B) are wildly inconsistent: choices may be plain
// strings, objects ({text}/{label}/{option,correct:true}), or an object map
// ({A:"…",B:"…"}); the correct answer may be an index, a letter ("B"), the
// answer text, a 1-based number, or a `correct:true` flag. This module
// normalizes all of that. Kept dependency-free so it can be unit-tested.

// Pull the JSON object out of prose / code fences.
export function extractJSON(text) {
  if (!text) return null;
  let t = String(text).replace(/```json/gi, '```').trim();
  const fence = t.match(/```([\s\S]*?)```/);
  if (fence) t = fence[1].trim();
  const firstObj = t.indexOf('{');
  const firstArr = t.indexOf('[');
  let start, end;
  if (firstArr !== -1 && (firstObj === -1 || firstArr < firstObj)) {
    start = firstArr; end = t.lastIndexOf(']'); // bare top-level array
  } else {
    start = firstObj; end = t.lastIndexOf('}');
  }
  if (start === -1 || end === -1 || end < start) return null;
  const slice = t.slice(start, end + 1);
  try { return JSON.parse(slice); } catch {}
  try { return JSON.parse(slice.replace(/,\s*([}\]])/g, '$1')); } catch {} // trailing commas
  return null;
}

// Turn a single choice (string | number | object) into display text.
function choiceText(c) {
  if (c == null) return '';
  if (typeof c === 'string') return c.trim();
  if (typeof c === 'number' || typeof c === 'boolean') return String(c);
  if (typeof c === 'object') {
    const v = c.text ?? c.label ?? c.choice ?? c.option ?? c.value ?? c.answer ?? c.title ?? c.name ?? c.content;
    if (v != null && typeof v !== 'object') return String(v).trim();
    const firstStr = Object.values(c).find((x) => typeof x === 'string');
    return firstStr ? String(firstStr).trim() : '';
  }
  return String(c).trim();
}

function isFlaggedCorrect(c) {
  return !!c && typeof c === 'object' && (c.correct === true || c.isCorrect === true || c.is_correct === true);
}

// Returns { choices: string[], correctFromFlag: number }
function extractChoices(q) {
  const raw = q.choices ?? q.options ?? q.answers ?? q.answerChoices ?? q.choice;
  const collected = [];
  let correctFromFlag = -1;
  if (Array.isArray(raw)) {
    for (const c of raw) {
      const text = choiceText(c);
      if (!text) continue;
      if (correctFromFlag === -1 && isFlaggedCorrect(c)) correctFromFlag = collected.length;
      collected.push(text);
    }
  } else if (raw && typeof raw === 'object') {
    for (const v of Object.values(raw)) { // { A:"…", B:"…" } — preserve order
      const text = choiceText(v);
      if (text) collected.push(text);
    }
  }
  // de-duplicate, preserve order
  const seen = new Set();
  const choices = [];
  let flag = correctFromFlag;
  collected.forEach((t, i) => {
    const k = t.toLowerCase();
    if (seen.has(k)) { if (i === correctFromFlag) flag = -1; return; }
    seen.add(k);
    if (i === correctFromFlag) flag = choices.length;
    choices.push(t);
  });
  return { choices, correctFromFlag: flag };
}

function letterToIndex(s) {
  const m = String(s).trim().match(/^[A-Za-z][).:]?$/);
  if (!m) return -1;
  return String(s).trim().toUpperCase().charCodeAt(0) - 65;
}

function resolveAnswerIndex(q, choices, correctFromFlag) {
  const n = choices.length;
  if (correctFromFlag >= 0 && correctFromFlag < n) return correctFromFlag;

  // explicit integer index fields
  for (const c of [q.answerIndex, q.correctIndex, q.answer_index, q.correctOption]) {
    if (Number.isInteger(c) && c >= 0 && c < n) return c;
  }
  // letter or exact-text fields
  const fields = [q.answer, q.correctAnswer, q.correct, q.answerLetter,
    q.correct_answer, q.solution, q.answerKey, q.answerIndex];
  for (const f of fields) {
    if (f == null) continue;
    const li = letterToIndex(f);
    if (li >= 0 && li < n) return li;
    const ft = String(f).trim().toLowerCase();
    const mi = choices.findIndex((ch) => ch.toLowerCase() === ft);
    if (mi >= 0) return mi;
  }
  // numeric (possibly 1-based)
  for (const f of [q.answerIndex, q.answer, q.correctAnswer, q.correct]) {
    if (f == null) continue;
    const num = Number(String(f).trim());
    if (Number.isInteger(num)) {
      if (num >= 0 && num < n) return num;
      if (num - 1 >= 0 && num - 1 < n) return num - 1;
    }
  }
  return 0;
}

// Normalize raw model JSON into clean question objects, or null if unusable.
export function normalizeQuestions(raw, count = Infinity) {
  const arr = raw && (
    Array.isArray(raw.questions) ? raw.questions :
    Array.isArray(raw.quiz) ? raw.quiz :
    Array.isArray(raw.items) ? raw.items :
    Array.isArray(raw) ? raw : null
  );
  if (!arr) return null;

  const out = [];
  for (const q of arr) {
    if (!q || typeof q !== 'object') continue;
    const qText = q.question ?? q.q ?? q.text ?? q.prompt ?? q.title;
    const { choices, correctFromFlag } = extractChoices(q);
    if (!qText || choices.length < 2) continue;

    const trimmed = choices.slice(0, 6);
    let idx = resolveAnswerIndex(q, trimmed, correctFromFlag);
    if (!Number.isInteger(idx) || idx < 0 || idx >= trimmed.length) idx = 0;

    const expl = q.explanation ?? q.reason ?? q.rationale ?? q.why;
    out.push({
      id: `q${out.length}`,
      question: String(qText).trim(),
      choices: trimmed,
      answerIndex: idx,
      explanation: expl != null ? String(expl).trim() : '',
      userAnswer: null,
    });
    if (out.length >= count) break;
  }
  return out.length ? out : null;
}
