# ExhibitGuide backend

This is a zero-dependency Node.js API for local development. It stores account records, preferences, favorite exhibit IDs, and hashed session tokens in `backend/data/userdata.json`, which is deliberately ignored by Git.

## Run it

```bash
cd backend
npm start
```

The server listens at `http://localhost:3000` by default. Set `PORT` to use another port.

## Connect the Flutter app

Pass the API address at build/run time:

```bash
# iOS simulator / desktop
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For a physical phone, replace the host with your computer's LAN address and use HTTPS before any non-development deployment.

## Routes

| Method | Route | Purpose |
| --- | --- | --- |
| GET | `/health` | Server health check |
| POST | `/api/auth/signup` | Create an account and return a session token |
| POST | `/api/auth/login` | Authenticate and return a session token |
| GET | `/api/me` | Get the signed-in user's public profile |
| GET/PUT | `/api/me/favorites` | Read/replace favorite exhibit IDs |
| GET/PUT | `/api/me/preferences` | Read/update local preference values |

This JSON-file backend is ideal for demos and local development. A production deployment should use HTTPS, a managed database, secure refresh-token rotation, rate limiting, email verification, and a secret manager.
