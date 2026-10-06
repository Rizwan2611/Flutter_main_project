import pptxgen from 'pptxgenjs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentDirectory = dirname(fileURLToPath(import.meta.url));
const root = resolve(currentDirectory, '../..');
const output = resolve(root, 'ExhibitGuide_Project_Presentation.pptx');

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'ExhibitGuide Team';
pptx.subject = 'ExhibitGuide Flutter museum companion project';
pptx.title = 'ExhibitGuide — Project Presentation';
pptx.company = 'ExhibitGuide';
pptx.lang = 'en-US';
pptx.theme = {
  headFontFace: 'Georgia',
  bodyFontFace: 'Aptos',
  lang: 'en-US',
};
pptx.defineLayout({ name: 'MOBILE', width: 13.333, height: 7.5 });

const color = {
  ink: '2B2421',
  paper: 'F8F5EF',
  clay: 'A34836',
  sand: 'ECE3D6',
  line: 'E1D8CD',
  white: 'FFFFFF',
  muted: '6F6560',
  dark: '1C1A17',
};

function base(slide, title, eyebrow = 'EXHIBITGUIDE') {
  slide.background = { color: color.paper };
  slide.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: 13.333, h: 0.13, fill: { color: color.clay }, line: { color: color.clay } });
  slide.addText(eyebrow, { x: 0.65, y: 0.42, w: 3, h: 0.2, fontFace: 'Aptos', fontSize: 8, bold: true, color: color.clay, charSpace: 1.4, margin: 0 });
  slide.addText(title, { x: 0.65, y: 0.72, w: 12, h: 0.5, fontFace: 'Georgia', fontSize: 27, bold: true, color: color.ink, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.65, y: 1.36, w: 12.05, h: 0, line: { color: color.line, width: 1 } });
  slide.addText('Museum App · Flutter · Local-first data', { x: 0.65, y: 7.1, w: 5.3, h: 0.18, fontSize: 7.5, color: color.muted, margin: 0 });
}

function bulletList(slide, items, x, y, w, fontSize = 15) {
  slide.addText(items.map((text) => ({ text, options: { bullet: { indent: 14 }, hanging: 3 } })), {
    x, y, w, h: 4.9, fontFace: 'Aptos', fontSize, color: color.ink, breakLine: true,
    paraSpaceAfterPt: 11, margin: 0.05, valign: 'top',
  });
}

function pill(slide, text, x, y, w, fill = color.sand) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h: 0.35, rectRadius: 0.06, fill: { color: fill }, line: { color: fill } });
  slide.addText(text, { x, y: y + 0.08, w, h: 0.13, align: 'center', fontSize: 8, bold: true, color: fill === color.clay ? color.white : color.clay, margin: 0 });
}

function card(slide, { x, y, w, h, title, body, icon }) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h, rectRadius: 0.05, fill: { color: color.white }, line: { color: color.line, width: 1 } });
  if (icon) slide.addText(icon, { x: x + 0.18, y: y + 0.2, w: 0.4, h: 0.3, fontSize: 18, margin: 0 });
  slide.addText(title, { x: x + 0.22 + (icon ? 0.36 : 0), y: y + 0.22, w: w - 0.44 - (icon ? 0.36 : 0), h: 0.25, fontFace: 'Georgia', fontSize: 13, bold: true, color: color.ink, margin: 0 });
  slide.addText(body, { x: x + 0.22, y: y + 0.64, w: w - 0.44, h: h - 0.82, fontSize: 9.5, color: color.muted, breakLine: false, margin: 0 });
}

// 1 — Cover
{
  const slide = pptx.addSlide();
  slide.background = { color: color.dark };
  slide.addText('MUSEUM APP', { x: 0.72, y: 0.83, w: 3, h: 0.2, fontSize: 9, bold: true, color: 'D2A59C', charSpace: 2, margin: 0 });
  slide.addText('ExhibitGuide', { x: 0.68, y: 1.4, w: 10.8, h: 0.8, fontFace: 'Georgia', fontSize: 42, bold: true, color: color.white, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.72, y: 2.48, w: 0.52, h: 0, line: { color: color.clay, width: 1.5 } });
  slide.addText('A local-first Flutter museum companion', { x: 0.72, y: 2.72, w: 5.8, h: 0.35, fontSize: 18, color: 'F1E8E0', margin: 0 });
  slide.addText('Figma design implementation · local preferences · optional secure backend', { x: 0.72, y: 3.22, w: 8.8, h: 0.4, fontSize: 11, color: 'CABEB4', margin: 0 });
  slide.addShape(pptx.ShapeType.roundRect, { x: 8.75, y: 1.48, w: 3.55, h: 3.6, rectRadius: 0.06, fill: { color: '2A2522' }, line: { color: '6E554F', width: 1 } });
  slide.addText('WHAT THIS PROJECT COVERS', { x: 9.1, y: 1.9, w: 2.85, h: 0.2, align: 'center', fontSize: 9, bold: true, color: 'D2A59C', charSpace: 1.2, margin: 0 });
  slide.addText('• Flutter mobile application\n• Figma-to-IDE process\n• Local JSON user data\n• Optional backend login\n• Project file explanation', { x: 9.22, y: 2.45, w: 2.6, h: 1.65, fontSize: 13, color: color.white, breakLine: true, paraSpaceAfterPt: 8, margin: 0 });
  slide.addShape(pptx.ShapeType.rect, { x: 0.72, y: 5.96, w: 2.55, h: 0.58, fill: { color: color.clay }, line: { color: color.clay } });
  slide.addText('PROJECT PRESENTATION', { x: 0.72, y: 6.17, w: 2.55, h: 0.14, align: 'center', fontSize: 8.5, bold: true, color: color.white, margin: 0 });
  slide.addText('2026', { x: 0.72, y: 6.9, w: 1, h: 0.18, fontSize: 8, color: 'CABEB4', margin: 0 });
}

// 2 — Problem and solution
{
  const slide = pptx.addSlide();
  base(slide, 'The museum visit, made personal');
  slide.addText('Visitors need more than a map: they need context, memory, and access even where reception is weak.', { x: 0.65, y: 1.68, w: 8.3, h: 0.42, fontSize: 16, color: color.muted, margin: 0 });
  card(slide, { x: 0.65, y: 2.4, w: 3.85, h: 2.2, icon: '⌕', title: 'Discover', body: 'Search and filter a curated collection of exhibits by artwork, artist, and era.' });
  card(slide, { x: 4.74, y: 2.4, w: 3.85, h: 2.2, icon: '♡', title: 'Remember', body: 'Save the works that matter to a personal collection that survives app restarts.' });
  card(slide, { x: 8.83, y: 2.4, w: 3.85, h: 2.2, icon: '⌂', title: 'Navigate', body: 'Use settings, map, help, and exhibit details during a visit—online or offline.' });
  slide.addShape(pptx.ShapeType.roundRect, { x: 0.65, y: 5.12, w: 12.03, h: 1.08, rectRadius: 0.05, fill: { color: color.sand }, line: { color: color.line } });
  slide.addText('Outcome', { x: 0.95, y: 5.43, w: 1.2, h: 0.2, fontFace: 'Georgia', fontSize: 15, bold: true, color: color.clay, margin: 0 });
  slide.addText('An elegant, offline-first companion that turns a passive gallery visit into a curated personal experience.', { x: 2.15, y: 5.4, w: 9.8, h: 0.25, fontSize: 13, color: color.ink, margin: 0 });
}

// 3 — Product experience
{
  const slide = pptx.addSlide();
  base(slide, 'End-to-end visitor experience');
  const steps = [
    ['01', 'Launch', 'Figma-inspired splash and onboarding'],
    ['02', 'Access', 'Local demo or backend signup/login'],
    ['03', 'Explore', 'Searchable, filterable exhibit gallery'],
    ['04', 'Save', 'Favorite exhibits and inspect details'],
    ['05', 'Personalize', 'Map, preferences, support, and about'],
  ];
  steps.forEach(([number, title, body], index) => {
    const x = 0.65 + index * 2.42;
    slide.addShape(pptx.ShapeType.roundRect, { x, y: 2.15, w: 2.05, h: 2.85, rectRadius: 0.05, fill: { color: index % 2 ? color.white : color.sand }, line: { color: color.line } });
    slide.addText(number, { x: x + 0.22, y: 2.42, w: 0.55, h: 0.2, fontSize: 11, bold: true, color: color.clay, margin: 0 });
    slide.addText(title, { x: x + 0.22, y: 2.9, w: 1.6, h: 0.3, fontFace: 'Georgia', fontSize: 16, bold: true, color: color.ink, margin: 0 });
    slide.addText(body, { x: x + 0.22, y: 3.47, w: 1.6, h: 0.85, fontSize: 9.5, color: color.muted, margin: 0 });
    if (index < steps.length - 1) slide.addShape(pptx.ShapeType.chevron, { x: x + 2.1, y: 3.22, w: 0.22, h: 0.35, fill: { color: color.clay }, line: { color: color.clay } });
  });
  slide.addText('The three-tab navigation keeps the core experience simple: Gallery · Favorites · Profile.', { x: 2.1, y: 5.75, w: 9.2, h: 0.25, align: 'center', fontSize: 13, color: color.muted, margin: 0 });
}

// 4 — Figma workflow
{
  const slide = pptx.addSlide();
  base(slide, 'How Figma was connected to the IDE');
  slide.addText('The supplied Figma file was treated as the visual source of truth, then translated into Flutter-native responsive widgets.', { x: 0.65, y: 1.65, w: 9.5, h: 0.35, fontSize: 15, color: color.muted, margin: 0 });
  const flow = [
    ['1', 'Open Figma file', 'Inspect file and top-level page metadata'],
    ['2', 'Select frame', 'Read the splash-welcome hierarchy and dimensions'],
    ['3', 'Download assets', 'Bring the original splash artwork into assets/images'],
    ['4', 'Build in Flutter', 'Use Stack, SafeArea, Column, buttons, and theme tokens'],
    ['5', 'Verify', 'Format and analyze the project'],
  ];
  flow.forEach(([number, title, detail], index) => {
    const y = 2.25 + index * 0.78;
    slide.addShape(pptx.ShapeType.ellipse, { x: 0.78, y, w: 0.43, h: 0.43, fill: { color: color.clay }, line: { color: color.clay } });
    slide.addText(number, { x: 0.78, y: y + 0.13, w: 0.43, h: 0.1, align: 'center', fontSize: 8, bold: true, color: color.white, margin: 0 });
    slide.addText(title, { x: 1.48, y: y + 0.03, w: 2.15, h: 0.18, fontSize: 12, bold: true, color: color.ink, margin: 0 });
    slide.addText(detail, { x: 3.65, y: y + 0.03, w: 5.15, h: 0.18, fontSize: 11, color: color.muted, margin: 0 });
  });
  card(slide, { x: 9.35, y: 2.02, w: 2.9, h: 3.45, title: 'What was matched', body: '• Full-screen launch layout\n• Dark visual overlay\n• Centered brand lockup\n• Clay-coloured call-to-action\n• Mobile safe-area spacing\n• Bottom home indicator treatment' });
}

// 5 — Architecture
{
  const slide = pptx.addSlide();
  base(slide, 'Offline-first architecture');
  const boxes = [
    { x: 0.75, title: 'Flutter UI', text: 'Screens, navigation, stateful interactions, Material theme', fill: color.sand },
    { x: 4.52, title: 'Local storage', text: 'shared_preferences for profile, favorites, session token, toggles', fill: color.white },
    { x: 8.29, title: 'Optional API', text: 'Node.js backend for account, favorites, and preferences sync', fill: color.sand },
  ];
  boxes.forEach((box) => {
    slide.addShape(pptx.ShapeType.roundRect, { x: box.x, y: 2.2, w: 3.0, h: 2.15, rectRadius: 0.06, fill: { color: box.fill }, line: { color: color.line } });
    slide.addText(box.title, { x: box.x + 0.24, y: 2.55, w: 2.5, h: 0.3, align: 'center', fontFace: 'Georgia', fontSize: 17, bold: true, color: color.ink, margin: 0 });
    slide.addText(box.text, { x: box.x + 0.28, y: 3.22, w: 2.44, h: 0.52, align: 'center', fontSize: 10, color: color.muted, margin: 0 });
  });
  slide.addShape(pptx.ShapeType.chevron, { x: 3.92, y: 2.93, w: 0.35, h: 0.55, fill: { color: color.clay }, line: { color: color.clay } });
  slide.addShape(pptx.ShapeType.chevron, { x: 7.69, y: 2.93, w: 0.35, h: 0.55, fill: { color: color.clay }, line: { color: color.clay } });
  slide.addText('If the API is unreachable, the app keeps using local values. When configured, successful sign-in connects the same controllers to backend synchronization.', { x: 1.2, y: 5.15, w: 10.9, h: 0.42, align: 'center', fontSize: 13, color: color.muted, margin: 0 });
}

// 6 — Storage
{
  const slide = pptx.addSlide();
  base(slide, 'What data is stored?');
  slide.addText('On device — shared_preferences', { x: 0.75, y: 1.72, w: 4, h: 0.25, fontFace: 'Georgia', fontSize: 17, bold: true, color: color.ink, margin: 0 });
  slide.addText('On backend — JSON store for local development', { x: 6.95, y: 1.72, w: 5.2, h: 0.25, fontFace: 'Georgia', fontSize: 17, bold: true, color: color.ink, margin: 0 });
  const local = ['visitor_name', 'visitor_email', 'session_token', 'favorite_exhibit_ids', 'notifications_enabled', 'offline_downloads_enabled', 'dark_mode_enabled'];
  const remote = ['id, name, email, createdAt', 'salted scrypt password hash', 'favorite exhibit IDs', 'three user preferences', 'hashed 7-day session tokens'];
  bulletList(slide, local, 0.85, 2.25, 4.8, 12);
  bulletList(slide, remote, 7.05, 2.25, 4.9, 12);
  slide.addShape(pptx.ShapeType.line, { x: 6.36, y: 1.65, w: 0, h: 4.5, line: { color: color.line, width: 1 } });
  pill(slide, 'OFFLINE FALLBACK', 2.1, 5.9, 1.9);
  pill(slide, 'DO NOT COMMIT USER DATA', 8.65, 5.9, 2.2, color.clay);
}

// 7 — Backend and security
{
  const slide = pptx.addSlide();
  base(slide, 'Backend authentication and synchronization');
  const api = [
    ['POST', '/api/auth/signup', 'Create account + token'],
    ['POST', '/api/auth/login', 'Authenticate + token'],
    ['GET / PUT', '/api/me/favorites', 'Read/update saved exhibits'],
    ['GET / PUT', '/api/me/preferences', 'Read/update toggle values'],
    ['GET', '/api/me', 'Read public profile'],
  ];
  api.forEach(([method, route, description], index) => {
    const y = 1.82 + index * 0.72;
    pill(slide, method, 0.85, y, 1.2, method === 'POST' ? color.clay : color.sand);
    slide.addText(route, { x: 2.3, y: y + 0.08, w: 2.85, h: 0.15, fontFace: 'Courier New', fontSize: 10.5, bold: true, color: color.ink, margin: 0 });
    slide.addText(description, { x: 5.35, y: y + 0.08, w: 3.5, h: 0.15, fontSize: 10.5, color: color.muted, margin: 0 });
  });
  slide.addShape(pptx.ShapeType.roundRect, { x: 9.05, y: 1.78, w: 3.0, h: 3.8, rectRadius: 0.05, fill: { color: color.sand }, line: { color: color.line } });
  slide.addText('Security included', { x: 9.35, y: 2.12, w: 2.4, h: 0.25, fontFace: 'Georgia', fontSize: 16, bold: true, color: color.ink, margin: 0 });
  bulletList(slide, ['Salted scrypt hashes', 'Bearer-token API access', 'Hashed tokens in storage', 'Private, Git-ignored database file'], 9.28, 2.72, 2.35, 10.5);
  slide.addText('Production next: HTTPS, real database, secure token vault, rate limiting, verification, and OAuth.', { x: 1.0, y: 5.95, w: 10.8, h: 0.25, align: 'center', fontSize: 12.5, color: color.clay, italic: true, margin: 0 });
}

// 8 — Files
{
  const slide = pptx.addSlide();
  base(slide, 'Important files at a glance');
  const files = [
    ['lib/main.dart', 'App flow, views, theme, local controllers, and widgets'],
    ['lib/services/backend_api.dart', 'Typed Flutter HTTP client and backend configuration'],
    ['pubspec.yaml', 'Flutter dependencies and image asset declaration'],
    ['assets/images/splash-welcome.png', 'Figma-provided splash artwork'],
    ['backend/server.mjs', 'Zero-dependency Node API and JSON persistence'],
    ['backend/README.md', 'API routes and run/configuration instructions'],
    ['PROJECT_DOCUMENTATION.md', 'Complete project, Figma, data, and setup guide'],
  ];
  files.forEach(([name, description], index) => {
    const col = index < 4 ? 0 : 1;
    const row = index < 4 ? index : index - 4;
    const x = col === 0 ? 0.75 : 6.85;
    const y = 1.75 + row * 1.18;
    slide.addShape(pptx.ShapeType.roundRect, { x, y, w: 5.65, h: 0.9, rectRadius: 0.04, fill: { color: row % 2 ? color.white : color.sand }, line: { color: color.line } });
    slide.addText(name, { x: x + 0.25, y: y + 0.18, w: 2.7, h: 0.15, fontFace: 'Courier New', fontSize: 9.5, bold: true, color: color.clay, margin: 0 });
    slide.addText(description, { x: x + 0.25, y: y + 0.48, w: 5.05, h: 0.15, fontSize: 9.4, color: color.muted, margin: 0 });
  });
}

// 9 — Run
{
  const slide = pptx.addSlide();
  base(slide, 'Run it locally');
  card(slide, { x: 0.8, y: 1.82, w: 5.65, h: 3.7, title: 'Flutter — local demo mode', body: '1. flutter pub get\n2. flutter run\n\nFavorites, profile, and toggles persist on-device. No backend is needed to explore the app.' });
  card(slide, { x: 6.88, y: 1.82, w: 5.65, h: 3.7, title: 'Backend-enabled mode', body: '1. cd backend\n2. npm start\n3. flutter run --dart-define=API_BASE_URL=http://localhost:3000\n\nAndroid emulator uses http://10.0.2.2:3000.' });
  slide.addShape(pptx.ShapeType.roundRect, { x: 1.85, y: 5.95, w: 9.65, h: 0.52, rectRadius: 0.05, fill: { color: color.dark }, line: { color: color.dark } });
  slide.addText('Use a computer LAN IP for a physical device; use HTTPS before any shared or production deployment.', { x: 1.85, y: 6.14, w: 9.65, h: 0.14, align: 'center', fontSize: 9.5, color: color.white, margin: 0 });
}

// 10 — Screens explained
{
  const slide = pptx.addSlide();
  base(slide, 'What each page does');
  const pages = [
    ['Splash and onboarding', 'Welcomes the visitor and explains the app before login.'],
    ['Login and sign up', 'Uses local demo access by default or the backend when an API URL is supplied.'],
    ['Gallery and detail', 'Lets visitors search, filter, inspect art information, and save favorites.'],
    ['Favorites and profile', 'Shows the personal collection, saved visitor details, map, support, and about links.'],
    ['Settings', 'Provides persistent toggles for notifications, offline downloads, and dark mode.'],
    ['Map and help', 'Offers a simple floor overview, location context, FAQs, and support contact information.'],
  ];
  pages.forEach(([title, detail], index) => {
    const col = index % 2;
    const row = Math.floor(index / 2);
    card(slide, { x: 0.8 + col * 6.05, y: 1.75 + row * 1.55, w: 5.55, h: 1.15, title, body: detail });
  });
}

// 11 — How login data moves
{
  const slide = pptx.addSlide();
  base(slide, 'How a user’s data is handled');
  slide.addText('Local demo mode', { x: 0.85, y: 1.75, w: 3.3, h: 0.25, fontFace: 'Georgia', fontSize: 17, bold: true, color: color.ink, margin: 0 });
  bulletList(slide, [
    'The visitor enters a name and email.',
    'The app saves profile details, favorites, and preferences in private device storage.',
    'The app still works after restart without a backend connection.',
  ], 0.85, 2.2, 4.8, 12);
  slide.addText('Backend-enabled mode', { x: 7.0, y: 1.75, w: 3.8, h: 0.25, fontFace: 'Georgia', fontSize: 17, bold: true, color: color.ink, margin: 0 });
  bulletList(slide, [
    'Signup creates a JSON user record in backend/data/userdata.json.',
    'The password is converted into a salted hash; the raw password is not saved.',
    'Login returns a session token. Favorites and preferences then synchronize to the JSON backend.',
  ], 7.0, 2.2, 5.0, 12);
  slide.addShape(pptx.ShapeType.roundRect, { x: 1.6, y: 5.45, w: 10.05, h: 0.75, rectRadius: 0.05, fill: { color: color.sand }, line: { color: color.line } });
  slide.addText('Important: backend/data/userdata.json stores account information and is ignored by Git so real user records are not uploaded to the repository.', { x: 1.92, y: 5.72, w: 9.4, h: 0.18, align: 'center', fontSize: 10.5, color: color.ink, margin: 0 });
}

// 12 — Roadmap
{
  const slide = pptx.addSlide();
  base(slide, 'Recommended next steps');
  const roadmap = [
    ['1', 'Fully offline gallery', 'Bundle the remaining artwork images as Flutter assets.'],
    ['2', 'Production backend', 'Move JSON data to PostgreSQL, Firebase, or Supabase.'],
    ['3', 'Account hardening', 'Secure device token storage, email verification, reset flows, and OAuth.'],
    ['4', 'Quality and access', 'Add widget tests, integration tests, semantics, and accessible routing.'],
  ];
  roadmap.forEach(([number, title, detail], index) => {
    const x = 0.75 + (index % 2) * 6.15;
    const y = 1.8 + Math.floor(index / 2) * 2.05;
    slide.addShape(pptx.ShapeType.ellipse, { x, y, w: 0.62, h: 0.62, fill: { color: color.clay }, line: { color: color.clay } });
    slide.addText(number, { x, y: y + 0.18, w: 0.62, h: 0.13, align: 'center', fontSize: 10, bold: true, color: color.white, margin: 0 });
    slide.addText(title, { x: x + 0.9, y: y + 0.03, w: 4.6, h: 0.24, fontFace: 'Georgia', fontSize: 16, bold: true, color: color.ink, margin: 0 });
    slide.addText(detail, { x: x + 0.9, y: y + 0.47, w: 4.5, h: 0.3, fontSize: 11, color: color.muted, margin: 0 });
  });
  slide.addText('Thank you', { x: 0.75, y: 6.15, w: 11.8, h: 0.43, align: 'center', fontFace: 'Georgia', fontSize: 26, bold: true, color: color.clay, margin: 0 });
}

await pptx.writeFile({ fileName: output });
console.log(`Created ${output}`);
