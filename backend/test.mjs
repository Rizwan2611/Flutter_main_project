import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentDirectory = dirname(fileURLToPath(import.meta.url));
const databasePath = join(currentDirectory, 'data', 'userdata.json');
const port = 3100;
const baseUrl = `http://127.0.0.1:${port}`;
const originalDatabase = await readFile(databasePath, 'utf8');
const server = spawn(process.execPath, ['server.mjs'], {
  cwd: currentDirectory,
  env: { ...process.env, PORT: String(port) },
  stdio: ['ignore', 'pipe', 'pipe'],
});

function waitForServer() {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Backend did not start.')), 5000);
    server.stdout.on('data', (chunk) => {
      if (chunk.toString().includes('API running')) {
        clearTimeout(timeout);
        resolve();
      }
    });
    server.stderr.on('data', (chunk) => {
      clearTimeout(timeout);
      reject(new Error(chunk.toString()));
    });
  });
}

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return { status: response.status, body: await response.json() };
}

try {
  await waitForServer();
  const health = await request('/health');
  assert.equal(health.status, 200);
  assert.equal(health.body.status, 'ok');

  const signup = await request('/api/auth/signup', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      name: 'QA Visitor',
      email: 'qa@example.com',
      password: 'test-pass-123',
    }),
  });
  assert.equal(signup.status, 201);
  assert.equal(signup.body.user.email, 'qa@example.com');
  assert.ok(signup.body.token);

  const headers = {
    authorization: `Bearer ${signup.body.token}`,
    'content-type': 'application/json',
  };
  const favoritesBefore = await request('/api/me/favorites', { headers });
  assert.deepEqual(favoritesBefore.body.favorites, []);

  const favoritesAfter = await request('/api/me/favorites', {
    method: 'PUT',
    headers,
    body: JSON.stringify({ favorites: ['winged-victory', 'starry-night'] }),
  });
  assert.deepEqual(favoritesAfter.body.favorites, [
    'winged-victory',
    'starry-night',
  ]);

  const preferences = await request('/api/me/preferences', {
    method: 'PUT',
    headers,
    body: JSON.stringify({ preferences: { darkModeEnabled: true } }),
  });
  assert.equal(preferences.body.preferences.darkModeEnabled, true);

  const login = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'qa@example.com', password: 'test-pass-123' }),
  });
  assert.equal(login.status, 200);

  const database = await readFile(databasePath, 'utf8');
  assert.ok(database.includes('qa@example.com'));
  assert.ok(!database.includes('test-pass-123'));
  console.log('Backend integration tests passed.');
} finally {
  server.kill();
  await writeFile(databasePath, originalDatabase);
}
