import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exhibit_guide/main.dart';
import 'package:exhibit_guide/services/backend_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('local preferences persist favorites, profile, and settings', () async {
    final FavoritesController favorites = FavoritesController();
    await favorites.load();
    await favorites.toggle('winged-victory');

    final VisitorController visitor = VisitorController();
    await visitor.update(name: 'Maya Chen', email: 'maya@example.com');

    final SettingsController settings = SettingsController();
    await settings.setDarkModeEnabled(true);

    final FavoritesController restoredFavorites = FavoritesController();
    final VisitorController restoredVisitor = VisitorController();
    final SettingsController restoredSettings = SettingsController();
    await Future.wait<void>(<Future<void>>[
      restoredFavorites.load(),
      restoredVisitor.load(),
      restoredSettings.load(),
    ]);

    expect(restoredFavorites.contains('winged-victory'), isTrue);
    expect(restoredVisitor.name, 'Maya Chen');
    expect(restoredVisitor.email, 'maya@example.com');
    expect(restoredSettings.darkModeEnabled, isTrue);
  });

  test('server-mode controllers do not write browser/local preferences',
      () async {
    final FavoritesController favorites =
        FavoritesController(storeLocally: false);
    final VisitorController visitor = VisitorController(storeLocally: false);
    final SettingsController settings = SettingsController(storeLocally: false);

    await favorites.toggle('winged-victory');
    await visitor.update(
      name: 'Server User',
      email: 'server@example.com',
      token: 'session-token',
    );
    await settings.setNotificationsEnabled(false);

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('favorite_exhibit_ids'), isFalse);
    expect(preferences.containsKey('visitor_name'), isFalse);
    expect(preferences.containsKey('visitor_email'), isFalse);
    expect(preferences.containsKey('session_token'), isFalse);
    expect(preferences.containsKey('notifications_enabled'), isFalse);
  });

  testWidgets('visitor can reach the email access screen from launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ExhibitGuideApp(
        favorites: FavoritesController(),
        visitor: VisitorController(),
        settings: SettingsController(),
        backendApi: const BackendApi(),
      ),
    );

    expect(find.text('START EXPLORING'), findsOneWidget);
    await tester.tap(find.text('START EXPLORING'));
    await tester.pumpAndSettle();

    expect(find.text('SKIP'), findsOneWidget);
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Don’t have an account? Sign up'), findsOneWidget);
  });
}
