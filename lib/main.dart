import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/backend_api.dart';

const Color ink = Color(0xFF2B2421);
const Color paper = Color(0xFFF8F5EF);
const Color clay = Color(0xFFB54B3C);
const Color clayDark = Color(0xFF91382D);
const Color sand = Color(0xFFECE3D6);
const Color line = Color(0xFFE1D8CD);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const BackendApi backendApi = BackendApi();
  final FavoritesController favorites = FavoritesController();
  final VisitorController visitor = VisitorController();
  final SettingsController settings = SettingsController();
  await Future.wait<void>(<Future<void>>[
    favorites.load(),
    visitor.load(),
    settings.load(),
  ]);
  if (backendApi.isConfigured && visitor.token != null) {
    try {
      await Future.wait<void>(<Future<void>>[
        favorites.connectToBackend(backendApi, visitor.token!),
        settings.connectToBackend(backendApi, visitor.token!),
      ]);
    } catch (_) {
      // The locally saved collection stays available when the server is offline.
    }
  }
  runApp(
    ExhibitGuideApp(
      favorites: favorites,
      visitor: visitor,
      settings: settings,
      backendApi: backendApi,
    ),
  );
}

class Exhibit {
  const Exhibit({
    required this.id,
    required this.name,
    required this.artistOrOrigin,
    required this.era,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String artistOrOrigin;
  final String era;
  final String description;
  final String imageUrl;
}

class FavoritesController extends ChangeNotifier {
  FavoritesController({this.storeLocally = true});

  static const String _key = 'favorite_exhibit_ids';
  final bool storeLocally;
  final Set<String> _ids = <String>{};
  BackendApi? _backendApi;
  String? _token;

  bool contains(String id) => _ids.contains(id);
  int get count => _ids.length;

  Future<void> load() async {
    if (!storeLocally) return;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(preferences.getStringList(_key) ?? const <String>[]);
  }

  Future<bool> toggle(String id) async {
    final bool added = _ids.add(id);
    if (!added) _ids.remove(id);
    notifyListeners();
    if (storeLocally) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setStringList(_key, _ids.toList()..sort());
    }
    if (_backendApi != null && _token != null) unawaited(_syncToBackend());
    return added;
  }

  Future<void> connectToBackend(BackendApi backendApi, String token) async {
    _backendApi = backendApi;
    _token = token;
    final List<String> remoteIds = await backendApi.getFavorites(token);
    if (remoteIds.isEmpty && _ids.isNotEmpty) {
      await _syncToBackend();
      return;
    }
    _ids
      ..clear()
      ..addAll(remoteIds);
    if (storeLocally) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setStringList(_key, _ids.toList()..sort());
    }
    notifyListeners();
  }

  Future<void> _syncToBackend() async {
    try {
      await _backendApi!.putFavorites(_token!, _ids);
    } catch (_) {
      // Local favorites remain the source of truth until connectivity returns.
    }
  }
}

class VisitorController extends ChangeNotifier {
  VisitorController({this.storeLocally = true});

  static const String _nameKey = 'visitor_name';
  static const String _emailKey = 'visitor_email';
  static const String _tokenKey = 'session_token';
  final bool storeLocally;

  String _name = 'Alexandra Calder';
  String _email = 'alexandra@calder.org';
  String? _token;

  String get name => _name;
  String get email => _email;
  String? get token => _token;

  Future<void> load() async {
    if (!storeLocally) return;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _name = preferences.getString(_nameKey) ?? _name;
    _email = preferences.getString(_emailKey) ?? _email;
    _token = preferences.getString(_tokenKey);
  }

  Future<void> update({
    required String name,
    required String email,
    String? token,
  }) async {
    final String nextName = name.trim().isEmpty ? _name : name.trim();
    final String nextEmail = email.trim().isEmpty ? _email : email.trim();
    if (nextName == _name &&
        nextEmail == _email &&
        (token == null || token == _token)) {
      return;
    }
    _name = nextName;
    _email = nextEmail;
    _token = token ?? _token;
    notifyListeners();
    if (storeLocally) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, _name);
      await preferences.setString(_emailKey, _email);
      if (_token != null) await preferences.setString(_tokenKey, _token!);
    }
  }

  Future<void> clearSession() async {
    _token = null;
    if (storeLocally) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.remove(_tokenKey);
    }
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController({this.storeLocally = true});

  static const String _notificationsKey = 'notifications_enabled';
  static const String _offlineKey = 'offline_downloads_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  final bool storeLocally;

  bool _notificationsEnabled = true;
  bool _offlineDownloadsEnabled = true;
  bool _darkModeEnabled = false;
  BackendApi? _backendApi;
  String? _token;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get offlineDownloadsEnabled => _offlineDownloadsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;

  Future<void> load() async {
    if (!storeLocally) return;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _notificationsEnabled =
        preferences.getBool(_notificationsKey) ?? _notificationsEnabled;
    _offlineDownloadsEnabled =
        preferences.getBool(_offlineKey) ?? _offlineDownloadsEnabled;
    _darkModeEnabled = preferences.getBool(_darkModeKey) ?? _darkModeEnabled;
  }

  Future<void> setNotificationsEnabled(bool value) => _set(
      _notificationsKey, value, (bool next) => _notificationsEnabled = next);

  Future<void> setOfflineDownloadsEnabled(bool value) =>
      _set(_offlineKey, value, (bool next) => _offlineDownloadsEnabled = next);

  Future<void> setDarkModeEnabled(bool value) =>
      _set(_darkModeKey, value, (bool next) => _darkModeEnabled = next);

  Future<void> _set(
    String key,
    bool value,
    void Function(bool value) assign,
  ) async {
    assign(value);
    notifyListeners();
    if (storeLocally) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    }
    if (_backendApi != null && _token != null) unawaited(_syncToBackend());
  }

  Future<void> connectToBackend(BackendApi backendApi, String token) async {
    _backendApi = backendApi;
    _token = token;
    final Map<String, bool> preferences =
        await backendApi.getPreferences(token);
    _notificationsEnabled =
        preferences['notificationsEnabled'] ?? _notificationsEnabled;
    _offlineDownloadsEnabled =
        preferences['offlineDownloadsEnabled'] ?? _offlineDownloadsEnabled;
    _darkModeEnabled = preferences['darkModeEnabled'] ?? _darkModeEnabled;
    if (storeLocally) {
      final SharedPreferences local = await SharedPreferences.getInstance();
      await Future.wait<bool>(<Future<bool>>[
        local.setBool(_notificationsKey, _notificationsEnabled),
        local.setBool(_offlineKey, _offlineDownloadsEnabled),
        local.setBool(_darkModeKey, _darkModeEnabled),
      ]);
    }
    notifyListeners();
  }

  Future<void> _syncToBackend() async {
    try {
      await _backendApi!.putPreferences(_token!, <String, bool>{
        'notificationsEnabled': _notificationsEnabled,
        'offlineDownloadsEnabled': _offlineDownloadsEnabled,
        'darkModeEnabled': _darkModeEnabled,
      });
    } catch (_) {
      // Local preferences remain available offline.
    }
  }
}

class ExhibitGuideApp extends StatefulWidget {
  const ExhibitGuideApp({
    super.key,
    required this.favorites,
    required this.visitor,
    required this.settings,
    required this.backendApi,
  });

  final FavoritesController favorites;
  final VisitorController visitor;
  final SettingsController settings;
  final BackendApi backendApi;

  @override
  State<ExhibitGuideApp> createState() => _ExhibitGuideAppState();
}

class _ExhibitGuideAppState extends State<ExhibitGuideApp> {
  late AppStage _stage =
      widget.visitor.token != null ? AppStage.home : AppStage.splash;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (_, __) => MaterialApp(
        title: 'ExhibitGuide',
        debugShowCheckedModeBanner: false,
        themeMode:
            widget.settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(
            seedColor: clay,
            surface: paper,
            primary: clay,
            onPrimary: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: paper,
            foregroundColor: ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(
              color: ink,
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontFamily: 'serif',
              color: ink,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.04,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'serif',
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: TextStyle(
              fontFamily: 'serif',
              color: ink,
              fontWeight: FontWeight.w700,
            ),
            titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
            bodyLarge: TextStyle(color: Color(0xFF514945), height: 1.55),
            bodyMedium: TextStyle(color: Color(0xFF6F6560), height: 1.4),
            labelSmall: TextStyle(
              color: clay,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: const BorderSide(color: line),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: line),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: clay, width: 1.4),
              borderRadius: BorderRadius.zero,
            ),
            labelStyle: TextStyle(color: Color(0xFF6F6560)),
          ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: clay,
            brightness: Brightness.dark,
          ),
        ),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: switch (_stage) {
            AppStage.splash => SplashPage(
                key: const ValueKey<String>('splash'),
                onStart: () => setState(() => _stage = AppStage.onboarding),
              ),
            AppStage.onboarding => OnboardingPage(
                key: const ValueKey<String>('onboarding'),
                onFinish: () => setState(() => _stage = AppStage.login),
              ),
            AppStage.login => AuthPage(
                key: const ValueKey<String>('auth'),
                backendApi: widget.backendApi,
                onComplete: ({
                  required String name,
                  required String email,
                  String? token,
                }) async {
                  await widget.visitor
                      .update(name: name, email: email, token: token);
                  if (token != null && widget.backendApi.isConfigured) {
                    try {
                      await Future.wait<void>(<Future<void>>[
                        widget.favorites
                            .connectToBackend(widget.backendApi, token),
                        widget.settings
                            .connectToBackend(widget.backendApi, token),
                      ]);
                    } catch (_) {
                      // Authentication succeeded; later interactions can retry sync.
                    }
                  }
                  if (!mounted) return;
                  setState(() {
                    _stage = AppStage.home;
                  });
                },
              ),
            AppStage.home => MuseumShell(
                key: const ValueKey<String>('home'),
                favorites: widget.favorites,
                visitor: widget.visitor,
                settings: widget.settings,
                onLogout: () {
                  unawaited(widget.visitor.clearSession());
                  setState(() => _stage = AppStage.login);
                },
              ),
          },
        ),
      ),
    );
  }
}

enum AppStage { splash, onboarding, login, home }

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const _SplashArtwork(),
            ColoredBox(color: const Color(0xFF1C1A17).withValues(alpha: 0.55)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 5),
                    const _SplashTitle(),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA34836),
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        child: const Text('START EXPLORING'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(top: 21, bottom: 8),
                      child: Container(
                        width: 139,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashTitle extends StatelessWidget {
  const _SplashTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Text(
          'ExhibitGuide',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'serif',
            fontSize: 56,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(width: 32, height: 1, child: ColoredBox(color: clay)),
        SizedBox(height: 12),
        Text(
          'YOUR PERSONAL MUSEUM COMPANION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _SplashArtwork extends StatelessWidget {
  const _SplashArtwork();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash-welcome.png',
      fit: BoxFit.cover,
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _page = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<_OnboardItem> pages = <_OnboardItem>[
      _OnboardItem(
        title: 'Discover Art Like Never Before',
        text:
            'Browse compelling stories, save your favorites, and access exhibit information at your own pace.',
        image:
            'https://images.unsplash.com/photo-1561214115-f2f134cc4912?auto=format&fit=crop&w=1200&q=85',
      ),
      _OnboardItem(
        title: 'Keep Your Own Collection',
        text:
            'Build a personal archive of works you want to revisit after your museum visit.',
        image:
            'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342?auto=format&fit=crop&w=1200&q=85',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onFinish,
                  child: const Text('SKIP'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (int value) => setState(() => _page = value),
                  itemBuilder: (_, int index) =>
                      _OnboardCard(item: pages[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  pages.length,
                  (int index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: index == _page ? 22 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    color: index == _page ? clay : line,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _page == pages.length - 1
                      ? widget.onFinish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: clay,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    _page == pages.length - 1 ? 'GET STARTED' : 'NEXT',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardItem {
  const _OnboardItem({
    required this.title,
    required this.text,
    required this.image,
  });
  final String title;
  final String text;
  final String image;
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({required this.item});
  final _OnboardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              item.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: sand),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(item.title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(item.text, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 34),
      ],
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage(
      {super.key, required this.onComplete, required this.backendApi});
  final Future<void> Function({
    required String name,
    required String email,
    String? token,
  }) onComplete;
  final BackendApi backendApi;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _signUp = false;
  bool _forgot = false;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_forgot) {
      return _ForgotPassword(onBack: () => setState(() => _forgot = false));
    }
    final String heading = _signUp ? 'Create your collection' : 'Welcome back';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Center(child: MuseumMark(size: 54)),
                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      'ExhibitGuide',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(heading, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'SAVE YOUR CURATED COLLECTIONS AND EXHIBITS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_signUp) ...<Widget>[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Maya Chen',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'e.g. user@example.com',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      helperText: 'Must be at least 8 characters',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _forgot = true),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: clay,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_signUp ? 'CREATE ACCOUNT' : 'LOG IN'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _submitting ? null : _completeLocalDemo,
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Continue as Guest (Offline Mode)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _signUp = !_signUp),
                      child: Text(
                        _signUp
                            ? 'Already have an account? Log in'
                            : 'Don’t have an account? Sign up',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    final String email = _email.text.trim();
    final String password = _password.text;

    if (_signUp && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }
    if (email.isEmpty || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.backendApi.isConfigured) {
        final AuthenticatedUser user = _signUp
            ? await widget.backendApi.signUp(
                name: name,
                email: email,
                password: password,
              )
            : await widget.backendApi.logIn(
                email: email,
                password: password,
              );
        await widget.onComplete(
          name: user.name,
          email: user.email,
          token: user.token,
        );
      } else {
        await widget.onComplete(name: name, email: email);
      }
    } on BackendException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot connect to backend server at ${widget.backendApi.baseUrl}.\n'
              'Please ensure "node backend/server.mjs" is running.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _completeLocalDemo() => widget.onComplete(
        name: 'Alexandra Calder',
        email: 'alexandra@calder.org',
      );
}

class _ForgotPassword extends StatelessWidget {
  const _ForgotPassword({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: onBack)),
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const MuseumMark(size: 46),
            const SizedBox(height: 28),
            Text(
              'Reset your password',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Enter your email and we’ll send you a secure link to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link requested')),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: clay,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('SEND RESET LINK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MuseumShell extends StatefulWidget {
  const MuseumShell({
    super.key,
    required this.favorites,
    required this.visitor,
    required this.settings,
    required this.onLogout,
  });
  final FavoritesController favorites;
  final VisitorController visitor;
  final SettingsController settings;
  final VoidCallback onLogout;

  @override
  State<MuseumShell> createState() => _MuseumShellState();
}

class _MuseumShellState extends State<MuseumShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      GalleryPage(favorites: widget.favorites),
      FavoritesPage(favorites: widget.favorites),
      ProfilePage(
        visitor: widget.visitor,
        favorites: widget.favorites,
        settings: widget.settings,
        onLogout: widget.onLogout,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int value) => setState(() => _tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF3DDD8),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.favorites});
  final FavoritesController favorites;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String _query = '';
  String _filter = 'All';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Exhibit> filtered = exhibits.where((Exhibit item) {
      final String query = _query.toLowerCase();
      final bool matchQuery = item.name.toLowerCase().contains(query) ||
          item.era.toLowerCase().contains(query);
      return matchQuery && (_filter == 'All' || item.era.contains(_filter));
    }).toList();
    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ExhibitGuide',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CURATED STORIES OF ART',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.search, color: ink),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search artists, eras, artworks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children:
                  <String>['All', 'Renaissance', 'Impressionism', 'Modern']
                      .map(
                        (String value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: _filter == value,
                            onSelected: (_) => setState(() => _filter = value),
                            selectedColor: const Color(0xFFF1D9D4),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _NoResults()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: .59,
                    ),
                    itemBuilder: (_, int index) => ExhibitTile(
                      exhibit: filtered[index],
                      favorites: widget.favorites,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off_outlined, size: 44, color: clay),
            const SizedBox(height: 12),
            Text(
              'No exhibits found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
}

class ExhibitTile extends StatelessWidget {
  const ExhibitTile({
    super.key,
    required this.exhibit,
    required this.favorites,
  });
  final Exhibit exhibit;
  final FavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DetailPage(exhibit: exhibit, favorites: favorites),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Hero(
                    tag: exhibit.id,
                    child: ExhibitImage(exhibit: exhibit),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: FavoriteButton(
                      exhibit: exhibit,
                      favorites: favorites,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exhibit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exhibit.era,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: clay, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.favorites});
  final FavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: favorites,
        builder: (_, __) {
          final List<Exhibit> saved = exhibits
              .where((Exhibit item) => favorites.contains(item.id))
              .toList();
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'My Favorites',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text('EDIT', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Expanded(
                child: saved.isEmpty
                    ? const _FavoritesEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                        itemCount: saved.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, int index) => _FavoriteRow(
                          exhibit: saved[index],
                          favorites: favorites,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.favorite_border, size: 48, color: clay),
              const SizedBox(height: 16),
              Text(
                'Your collection is waiting',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart on any exhibit to save it here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({required this.exhibit, required this.favorites});
  final Exhibit exhibit;
  final FavoritesController favorites;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  DetailPage(exhibit: exhibit, favorites: favorites),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ExhibitImage(exhibit: exhibit),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exhibit.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exhibit.artistOrOrigin,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exhibit.era,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                FavoriteButton(exhibit: exhibit, favorites: favorites),
              ],
            ),
          ),
        ),
      );
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.exhibit, required this.favorites});
  final Exhibit exhibit;
  final FavoritesController favorites;
  @override
  Widget build(BuildContext context) {
    final double imageHeight =
        (MediaQuery.sizeOf(context).height * .34).clamp(240, 330).toDouble();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          FavoriteButton(exhibit: exhibit, favorites: favorites),
        ],
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: imageHeight,
            child: ColoredBox(
              color: sand,
              child: Hero(
                tag: exhibit.id,
                child: InteractiveViewer(
                  maxScale: 4,
                  child: SizedBox.expand(
                    child: ExhibitImage(exhibit: exhibit, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'HIGHLIGHTED PIECE',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  exhibit.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  exhibit.artistOrOrigin,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  exhibit.era,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 22),
                Text(
                  exhibit.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 15),
                Text(
                  'EXHIBIT LOCATION & INFORMATION',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                const _InfoBox(
                  icon: Icons.place_outlined,
                  title: 'Gallery 2, East Wing',
                  caption: 'Level 1 · Permanent Collection',
                ),
                const SizedBox(height: 10),
                const _InfoBox(
                  icon: Icons.schedule_outlined,
                  title: 'On view today',
                  caption: 'Museum open until 6:00 PM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.caption,
  });
  final IconData icon;
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: clay),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(caption, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.exhibit,
    required this.favorites,
    this.compact = false,
  });
  final Exhibit exhibit;
  final FavoritesController favorites;
  final bool compact;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: favorites,
        builder: (_, __) {
          final bool saved = favorites.contains(exhibit.id);
          return IconButton(
            visualDensity: compact ? VisualDensity.compact : null,
            style: compact
                ? IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .92),
                  )
                : null,
            onPressed: () async {
              final bool added = await favorites.toggle(exhibit.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      added ? 'Added to Favorites' : 'Removed from Favorites',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                color: clay),
          );
        },
      );
}

class ExhibitImage extends StatelessWidget {
  const ExhibitImage({
    super.key,
    required this.exhibit,
    this.fit = BoxFit.cover,
  });
  final Exhibit exhibit;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.network(
        exhibit.imageUrl,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: sand,
          child: Center(child: Icon(Icons.image_outlined, color: clay)),
        ),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.visitor,
    required this.favorites,
    required this.settings,
    required this.onLogout,
  });
  final VisitorController visitor;
  final FavoritesController favorites;
  final SettingsController settings;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[favorites, visitor]),
          builder: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsPage(settings: settings),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF1D9D4),
                  child: Text(
                    visitor.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: clay,
                      fontFamily: 'serif',
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  visitor.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  visitor.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'Member since 2024',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              _ProfileTile(
                icon: Icons.favorite_border,
                title: 'My Favorites',
                trailing: '${favorites.count} saved',
              ),
              const SizedBox(height: 10),
              _ProfileTile(
                icon: Icons.map_outlined,
                title: 'Museum Map',
                trailing: 'Floor 2',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MuseumMapPage()),
                ),
              ),
              const SizedBox(height: 10),
              _ProfileTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => Navigator.of(
                  context,
                ).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpPage())),
              ),
              const SizedBox(height: 10),
              _ProfileTile(
                icon: Icons.info_outline,
                title: 'About ExhibitGuide',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: clay,
                    side: const BorderSide(color: clay),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('LOG OUT'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: clay),
          title: Text(title),
          trailing: Text(
            trailing ?? '›',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListenableBuilder(
          listenable: settings,
          builder: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: <Widget>[
              Text(
                'VISIT PREFERENCES',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              _SettingSwitch(
                icon: Icons.notifications_outlined,
                title: 'Notification Preferences',
                subtitle: 'Updates about exhibits and your museum visit.',
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              const SizedBox(height: 10),
              _SettingSwitch(
                icon: Icons.download_for_offline_outlined,
                title: 'Download for Offline',
                subtitle:
                    'Keep your saved exhibits available without a connection.',
                value: settings.offlineDownloadsEnabled,
                onChanged: settings.setOfflineDownloadsEnabled,
              ),
              const SizedBox(height: 10),
              _SettingSwitch(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use a lower-light color palette throughout the app.',
                value: settings.darkModeEnabled,
                onChanged: settings.setDarkModeEnabled,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sand,
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.phone_iphone_outlined, color: clay),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your preferences and favorites are stored locally on this device.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: clay,
          secondary: Icon(icon, color: clay),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle:
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About ExhibitGuide')),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const MuseumMark(size: 56),
              const SizedBox(height: 20),
              Text(
                'Your personal museum companion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Discover art, save the works that move you, and keep exhibition information close at hand as you explore.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 12),
              Text('EXHIBITGUIDE',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text('Version 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}

class MuseumMapPage extends StatelessWidget {
  const MuseumMapPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Museum Map')),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('FLOOR 2', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: line),
                  ),
                  child: const _MuseumMapDrawing(),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'HIGHLIGHTED EXHIBITS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              const _InfoBox(
                icon: Icons.museum_outlined,
                title: 'West Gallery',
                caption: 'European art, 1500–1850',
              ),
            ],
          ),
        ),
      );
}

class _MuseumMapDrawing extends StatelessWidget {
  const _MuseumMapDrawing();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MapPainter(), child: const SizedBox.expand());
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFB9AFA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final Rect main = Rect.fromLTWH(
      size.width * .10,
      size.height * .16,
      size.width * .80,
      size.height * .60,
    );
    canvas.drawRect(main, paint);
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(main.left, main.top + main.height * i / 4),
        Offset(main.right, main.top + main.height * i / 4),
        paint,
      );
    }
    canvas.drawLine(
      Offset(main.left + main.width * .33, main.top),
      Offset(main.left + main.width * .33, main.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(main.left + main.width * .68, main.top),
      Offset(main.left + main.width * .68, main.bottom),
      paint,
    );
    final Paint pin = Paint()..color = clay;
    canvas.drawCircle(Offset(size.width * .54, size.height * .42), 7, pin);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 10),
            ...<String>[
              'How do I save favorites?',
              'Can I use the app offline?',
              'How do I navigate the museum?',
            ].map(
              (String question) => Card(
                child: ExpansionTile(
                  title: Text(question),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Use the controls on each exhibit screen to manage your visit and saved collection.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('CONTACT SUPPORT',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            const _InfoBox(
              icon: Icons.email_outlined,
              title: 'support@exhibitguide.org',
              caption: 'We usually reply within 24 hours.',
            ),
          ],
        ),
      );
}

class MuseumMark extends StatelessWidget {
  const MuseumMark({super.key, this.size = 40, this.light = false});
  final double size;
  final bool light;
  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MuseumMarkPainter(light: light)),
      );
}

class _MuseumMarkPainter extends CustomPainter {
  const _MuseumMarkPainter({required this.light});
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final Color color = light ? Colors.white : clay;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .045;
    final Paint fill = Paint()..color = color;
    final double w = size.width;
    canvas.drawCircle(Offset(w * .5, w * .27), w * .09, fill);
    final Path roof = Path()
      ..moveTo(w * .16, w * .55)
      ..lineTo(w * .5, w * .34)
      ..lineTo(w * .84, w * .55);
    canvas.drawPath(roof, stroke);
    for (final double x in <double>[.28, .42, .58, .72]) {
      canvas.drawLine(Offset(w * x, w * .55), Offset(w * x, w * .77), stroke);
    }
    canvas.drawLine(Offset(w * .18, w * .80), Offset(w * .82, w * .80), stroke);
  }

  @override
  bool shouldRepaint(covariant _MuseumMarkPainter oldDelegate) =>
      oldDelegate.light != light;
}

const List<Exhibit> exhibits = <Exhibit>[
  Exhibit(
    id: 'winged-victory',
    name: 'Winged Victory of Samothrace',
    artistOrOrigin: 'Unknown, Hellenistic Greece',
    era: 'c. 190 BCE · Hellenistic',
    description:
        'A marble celebration of Nike, the goddess of victory, staged as if she has just alighted on the prow of a ship. The figure’s wind-swept drapery gives the work an unforgettable sense of movement.',
    imageUrl:
        'https://images.unsplash.com/photo-1561214115-f2f134cc4912?auto=format&fit=crop&w=1200&q=85',
  ),
  Exhibit(
    id: 'starry-night',
    name: 'The Starry Night',
    artistOrOrigin: 'Vincent van Gogh',
    era: '1889 · Post-Impressionism',
    description:
        'Painted at Saint-Rémy, this nocturne transforms a remembered village and observed sky into a field of energetic, luminous brushwork.',
    imageUrl:
        'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342?auto=format&fit=crop&w=1200&q=85',
  ),
  Exhibit(
    id: 'psyche-cupid',
    name: 'Psyche Revived by Cupid’s Kiss',
    artistOrOrigin: 'Antonio Canova',
    era: '1787–1793 · Neoclassical',
    description:
        'Canova captures the instant Cupid awakens Psyche, balancing delicate emotion with an exacting ideal of classical form.',
    imageUrl:
        'https://images.unsplash.com/photo-1761334859641-139cffff4a47?auto=format&fit=crop&w=1200&q=85',
  ),
  Exhibit(
    id: 'thinker',
    name: 'The Thinker',
    artistOrOrigin: 'Auguste Rodin',
    era: '1904 · Modern sculpture',
    description:
        'Originally conceived for The Gates of Hell, Rodin’s concentrated figure became an enduring emblem of thought and creative intensity.',
    imageUrl:
        'https://images.unsplash.com/photo-1760029976977-253e8e11cb48?auto=format&fit=crop&w=1200&q=85',
  ),
  Exhibit(
    id: 'liberty',
    name: 'Lady with an Ermine',
    artistOrOrigin: 'Leonardo da Vinci',
    era: 'c. 1489–1490 · Renaissance',
    description:
        'Leonardo’s portrait joins a composed sitter with the symbolic alertness of her ermine, revealing his unmatched sensitivity to gesture and light.',
    imageUrl:
        'https://images.unsplash.com/photo-1763337582390-2d0d50d1fa5f?auto=format&fit=crop&w=1200&q=85',
  ),
  Exhibit(
    id: 'scream',
    name: 'The Scream',
    artistOrOrigin: 'Edvard Munch',
    era: '1893 · Expressionism',
    description:
        'Munch’s vivid composition turns a moment of private anxiety into a universal image of modern emotional experience.',
    imageUrl:
        'https://images.unsplash.com/photo-1774514580459-8e64f26b51f4?auto=format&fit=crop&w=1200&q=85',
  ),
];
