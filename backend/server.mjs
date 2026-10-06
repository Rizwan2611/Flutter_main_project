import { createHash, randomBytes, randomUUID, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const scrypt = promisify(scryptCallback);
const port = Number(process.env.PORT ?? 3000);
const currentDirectory = dirname(fileURLToPath(import.meta.url));
const storePath = join(currentDirectory, 'data', 'userdata.json');
const tokenLifetimeMs = 1000 * 60 * 60 * 24 * 7;

const defaultStore = () => ({ users: [], sessions: [] });

async function readStore() {
  try {
    return JSON.parse(await readFile(storePath, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return defaultStore();
    throw error;
  }
}

async function writeStore(store) {
  await mkdir(dirname(storePath), { recursive: true });
  const temporaryPath = `${storePath}.tmp`;
  await writeFile(temporaryPath, JSON.stringify(store, null, 2));
  await rename(temporaryPath, storePath);
}

function normalizeEmail(value) {
  return String(value ?? '').trim().toLowerCase();
}

function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, createdAt: user.createdAt };
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const derivedKey = await scrypt(password, salt, 64);
  return `${salt}:${derivedKey.toString('hex')}`;
}

async function passwordMatches(password, storedValue) {
  const [salt, expectedHex] = storedValue.split(':');
  if (!salt || !expectedHex) return false;
  const actual = await scrypt(password, salt, 64);
  const expected = Buffer.from(expectedHex, 'hex');
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

function send(response, status, body) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
  });
  response.end(JSON.stringify(body));
}

async function readBody(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error('Body must be valid JSON.');
  }
}

async function authenticatedUser(request, store) {
  const authorization = request.headers.authorization ?? '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  const session = store.sessions.find(
    (item) => item.tokenHash === hashToken(token) && item.expiresAt > Date.now(),
  );
  if (!session) return null;
  return store.users.find((user) => user.id === session.userId) ?? null;
}

async function createSession(user, store) {
  store.sessions = store.sessions.filter((item) => item.expiresAt > Date.now());
  const token = randomBytes(48).toString('base64url');
  store.sessions.push({
    id: randomUUID(),
    userId: user.id,
    tokenHash: hashToken(token),
    expiresAt: Date.now() + tokenLifetimeMs,
  });
  await writeStore(store);
  return token;
}

const server = createServer(async (request, response) => {
  console.log(`${new Date().toISOString()} ${request.method} ${request.url}`);
  if (request.method === 'OPTIONS') return send(response, 204, {});

  try {
    const url = new URL(request.url, `http://${request.headers.host ?? 'localhost'}`);
    if (request.method === 'GET' && url.pathname === '/') {
      return send(response, 200, {
        status: 'ExhibitGuide API is running',
        nextStep: 'Run the Flutter app and create an account from its Sign Up screen.',
        health: '/health',
        signUp: 'POST /api/auth/signup',
        logIn: 'POST /api/auth/login',
        note: 'Protected routes require a Bearer token from a successful signup or login.',
      });
    }
    if (request.method === 'GET' && url.pathname === '/health') {
      return send(response, 200, { status: 'ok' });
    }

    const store = await readStore();
    if (request.method === 'POST' && url.pathname === '/api/auth/signup') {
      const { name, email, password } = await readBody(request);
      const normalizedEmail = normalizeEmail(email);
      if (!String(name ?? '').trim() || !/^\S+@\S+\.\S+$/.test(normalizedEmail)) {
        return send(response, 400, { error: 'A name and valid email are required.' });
      }
      if (typeof password !== 'string' || password.length < 8) {
        return send(response, 400, { error: 'Password must be at least 8 characters.' });
      }
      if (store.users.some((user) => user.email === normalizedEmail)) {
        return send(response, 409, { error: 'An account already exists for this email.' });
      }
      const user = {
        id: randomUUID(),
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: await hashPassword(password),
        favorites: [],
        preferences: { notificationsEnabled: true, offlineDownloadsEnabled: true, darkModeEnabled: false },
        createdAt: new Date().toISOString(),
      };
      store.users.push(user);
      const token = await createSession(user, store);
      return send(response, 201, { token, user: publicUser(user) });
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/login') {
      const { email, password } = await readBody(request);
      const user = store.users.find((item) => item.email === normalizeEmail(email));
      if (!user || !(await passwordMatches(String(password ?? ''), user.passwordHash))) {
        return send(response, 401, { error: 'Invalid email or password.' });
      }
      const token = await createSession(user, store);
      return send(response, 200, { token, user: publicUser(user) });
    }

    const user = await authenticatedUser(request, store);
    if (!user) return send(response, 401, { error: 'Authentication required.' });

    if (request.method === 'GET' && url.pathname === '/api/me') {
      return send(response, 200, { user: publicUser(user) });
    }
    if (url.pathname === '/api/me/favorites') {
      if (request.method === 'GET') return send(response, 200, { favorites: user.favorites });
      if (request.method === 'PUT') {
        const { favorites } = await readBody(request);
        if (!Array.isArray(favorites) || favorites.some((id) => typeof id !== 'string')) {
          return send(response, 400, { error: 'Favorites must be an array of string IDs.' });
        }
        user.favorites = [...new Set(favorites)];
        await writeStore(store);
        return send(response, 200, { favorites: user.favorites });
      }
    }
    if (url.pathname === '/api/me/preferences') {
      if (request.method === 'GET') return send(response, 200, { preferences: user.preferences });
      if (request.method === 'PUT') {
        const { preferences } = await readBody(request);
        if (!preferences || typeof preferences !== 'object') {
          return send(response, 400, { error: 'Preferences must be an object.' });
        }
        for (const key of ['notificationsEnabled', 'offlineDownloadsEnabled', 'darkModeEnabled']) {
          if (key in preferences && typeof preferences[key] === 'boolean') user.preferences[key] = preferences[key];
        }
        await writeStore(store);
        return send(response, 200, { preferences: user.preferences });
      }
    }
    return send(response, 404, { error: 'Route not found.' });
  } catch (error) {
    console.error(error);
    return send(response, 400, { error: error.message ?? 'Request could not be processed.' });
  }
});

server.listen(port, () => console.log(`ExhibitGuide API running at http://localhost:${port}`));
