// Local, self-asserted identity. No login, no server — just a stable id + a
// friendly name/avatar persisted in IndexedDB. (Same trust model as AgentHerd:
// names are self-asserted; the "account" is your browser.)
import { db } from './db.js';

const ADJ = ['Quick', 'Bright', 'Clever', 'Bold', 'Curious', 'Sharp', 'Calm', 'Swift', 'Witty', 'Keen'];
const ANI = ['Fox', 'Owl', 'Lynx', 'Otter', 'Falcon', 'Panda', 'Wolf', 'Heron', 'Tiger', 'Raven'];
const AVATARS = ['🦊', '🦉', '🐱', '🐼', '🦅', '🐯', '🐺', '🐧', '🦁', '🐨', '🦄', '🐙'];

function randomName() {
  const a = ADJ[Math.floor(Math.random() * ADJ.length)];
  const b = ANI[Math.floor(Math.random() * ANI.length)];
  return `${a}${b}${Math.floor(Math.random() * 90) + 10}`;
}

export function uid(prefix = 'id') {
  const r = (crypto.randomUUID?.() || Math.random().toString(36).slice(2) + Date.now().toString(36));
  return `${prefix}_${r.replace(/-/g, '').slice(0, 16)}`;
}

let _me = null;

export async function getMe() {
  if (_me) return _me;
  let p = await db.get('profile', 'me');
  if (!p) {
    p = {
      id: 'me',
      userId: uid('u'),
      name: randomName(),
      avatar: AVATARS[Math.floor(Math.random() * AVATARS.length)],
      createdAt: Date.now(),
    };
    await db.put('profile', p);
  }
  _me = p;
  return p;
}

export async function updateMe(patch) {
  const p = { ...(await getMe()), ...patch };
  await db.put('profile', p);
  _me = p;
  return p;
}
