// Client-only persistence. Everything lives in the browser via IndexedDB.
// No network, no server. Stores: profile, attempts, quizzes, challenges.

const DB_NAME = 'easyqz';
const DB_VERSION = 1;
let _dbp = null;

function open() {
  if (_dbp) return _dbp;
  _dbp = new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains('profile')) {
        db.createObjectStore('profile', { keyPath: 'id' });
      }
      if (!db.objectStoreNames.contains('attempts')) {
        const s = db.createObjectStore('attempts', { keyPath: 'id' });
        s.createIndex('by_quiz', 'quizId', { unique: false });
        s.createIndex('by_time', 'createdAt', { unique: false });
      }
      if (!db.objectStoreNames.contains('quizzes')) {
        db.createObjectStore('quizzes', { keyPath: 'id' });
      }
      if (!db.objectStoreNames.contains('challenges')) {
        db.createObjectStore('challenges', { keyPath: 'id' });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  return _dbp;
}

async function tx(store, mode, fn) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const t = db.transaction(store, mode);
    const os = t.objectStore(store);
    let result;
    Promise.resolve(fn(os)).then((r) => { result = r; });
    t.oncomplete = () => resolve(result);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  });
}

function reqP(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export const db = {
  async get(store, key) {
    return tx(store, 'readonly', (os) => reqP(os.get(key)));
  },
  async getAll(store) {
    return tx(store, 'readonly', (os) => reqP(os.getAll()));
  },
  async put(store, value) {
    await tx(store, 'readwrite', (os) => { os.put(value); });
    return value;
  },
  async delete(store, key) {
    return tx(store, 'readwrite', (os) => { os.delete(key); });
  },
  async clear(store) {
    return tx(store, 'readwrite', (os) => { os.clear(); });
  },
};
