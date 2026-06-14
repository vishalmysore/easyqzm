// WebLLM wrapper — the model runs entirely in the browser via WebGPU.
// No API key, no cloud, no server. (Init pattern reused from AgentHerd.)
import * as webllm from '@mlc-ai/web-llm';

export const MODELS = [
  { id: 'Llama-3.2-1B-Instruct-q4f16_1-MLC', label: 'Llama 3.2 · 1B', size: '~0.9 GB', note: 'Fastest' },
  { id: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC', label: 'Qwen 2.5 · 1.5B', size: '~1.1 GB', note: 'Efficient' },
  { id: 'gemma-2-2b-it-q4f16_1-MLC', label: 'Gemma 2 · 2B', size: '~1.5 GB', note: 'Balanced' },
  { id: 'Llama-3.2-3B-Instruct-q4f16_1-MLC', label: 'Llama 3.2 · 3B', size: '~2.3 GB', note: 'Better quizzes' },
  { id: 'Phi-3.5-mini-instruct-q4f16_1-MLC', label: 'Phi-3.5 Mini', size: '~2.2 GB', note: 'Strong reasoning' },
];

let engine = null;
let loadedModelId = null;
let loadingPromise = null;

export function isReady() { return !!engine; }
export function currentModelId() { return loadedModelId; }

export async function checkWebGPU() {
  if (!navigator.gpu) return false;
  try {
    const adapter = await navigator.gpu.requestAdapter();
    return !!adapter;
  } catch {
    return false;
  }
}

// Loads (and caches) a model. onProgress({ pct, text }).
export async function loadModel(modelId, onProgress) {
  if (engine && loadedModelId === modelId) return engine;
  if (loadingPromise) await loadingPromise.catch(() => {});

  loadingPromise = (async () => {
    const initProgressCallback = (p) => {
      const pct = Math.round((p.progress ?? 0) * 100);
      onProgress?.({ pct, text: p.text ?? `Loading… ${pct}%` });
    };
    if (!engine) {
      engine = await webllm.CreateMLCEngine(modelId, { initProgressCallback });
    } else {
      await engine.reload(modelId, undefined, { initProgressCallback });
    }
    loadedModelId = modelId;
    return engine;
  })();

  try {
    return await loadingPromise;
  } finally {
    loadingPromise = null;
  }
}

// --- JSON extraction: small local models wrap JSON in prose / code fences. ---
function extractJSON(text) {
  if (!text) return null;
  let t = text.replace(/```json/gi, '```').trim();
  const fence = t.match(/```([\s\S]*?)```/);
  if (fence) t = fence[1].trim();
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start === -1 || end === -1 || end < start) return null;
  let slice = t.slice(start, end + 1);
  try { return JSON.parse(slice); } catch {}
  // tolerate trailing commas
  try { return JSON.parse(slice.replace(/,\s*([}\]])/g, '$1')); } catch {}
  return null;
}

function buildPrompt({ topic, sourceText, count, difficulty }) {
  const base = sourceText
    ? `Create a multiple-choice quiz that tests understanding of the following material:\n\n"""${sourceText.slice(0, 6000)}"""`
    : `Create a multiple-choice quiz on the topic: "${topic}".`;
  return `${base}

Rules:
- Exactly ${count} questions, ${difficulty} difficulty.
- Each question has exactly 4 answer choices.
- Exactly one choice is correct.
- "answerIndex" is the 0-based index of the correct choice.
- Keep questions self-contained and unambiguous.
- Add a one-sentence "explanation" for the correct answer.

Respond with ONLY valid JSON, no prose, in exactly this shape:
{"questions":[{"question":"...","choices":["...","...","...","..."],"answerIndex":0,"explanation":"..."}]}`;
}

function normalizeQuestions(raw, count) {
  if (!raw || !Array.isArray(raw.questions)) return null;
  const out = [];
  for (const q of raw.questions) {
    const choices = Array.isArray(q.choices) ? q.choices.map(String).filter(Boolean) : [];
    if (!q.question || choices.length < 2) continue;
    let idx = Number(q.answerIndex);
    if (!Number.isInteger(idx) || idx < 0 || idx >= choices.length) idx = 0;
    out.push({
      id: `q${out.length}`,
      question: String(q.question).trim(),
      choices,
      answerIndex: idx,
      explanation: q.explanation ? String(q.explanation).trim() : '',
      userAnswer: null,
    });
    if (out.length >= count) break;
  }
  return out.length ? out : null;
}

// Generates a quiz with the local model. Retries once if JSON is malformed.
export async function generateQuiz({ topic, sourceText, count = 5, difficulty = 'medium' }) {
  if (!engine) throw new Error('Model not loaded');
  const messages = [
    { role: 'system', content: 'You are a precise quiz generator. You output only valid JSON.' },
    { role: 'user', content: buildPrompt({ topic, sourceText, count, difficulty }) },
  ];

  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await engine.chat.completions.create({
      messages,
      temperature: attempt === 0 ? 0.7 : 0.4,
      max_tokens: 2048,
    });
    const text = res.choices?.[0]?.message?.content || '';
    const questions = normalizeQuestions(extractJSON(text), count);
    if (questions) return questions;
    messages.push({ role: 'assistant', content: text });
    messages.push({ role: 'user', content: 'That was not valid JSON. Respond again with ONLY the JSON object described.' });
  }
  throw new Error('The model did not return a usable quiz. Try again or pick a larger model.');
}
