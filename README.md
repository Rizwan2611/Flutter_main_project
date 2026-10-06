# Flutter_main_project

ExhibitGuide is a Flutter museum companion built from the supplied Figma design. Visitors can browse exhibits, save favorites, view detail pages, change settings, use a museum map, and access help content.

## Run in local demo mode

```bash
flutter pub get
flutter run -d chrome
```

In demo mode, profile, favorites, and preferences use local browser/device storage.

## Run with JSON backend storage

Start the backend in one terminal:

```bash
cd backend
npm start
```

Start the Flutter web app in a second terminal:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

The login page must show `SERVER MODE: USER DATA SAVES IN userdata.json`.

In server mode, the app clears old browser user values and does not persist user data in browser storage. A successful sign-up creates/updates [backend/data/userdata.json](backend/data/userdata.json). Refreshing the browser requires signing in again because the session token is intentionally held in memory only.

## Test and verify

```bash
flutter analyze
flutter test
npm test --prefix backend
flutter build web --release --dart-define=API_BASE_URL=http://localhost:3000
```

The backend integration test creates temporary test data and restores `userdata.json` after the test completes.

## Project documentation

See [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) for the Figma-to-Flutter workflow, data model, API routes, project files, and production recommendations.
