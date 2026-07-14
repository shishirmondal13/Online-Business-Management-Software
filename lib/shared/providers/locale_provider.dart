import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for shared preferences - must be overridden in main()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Locale provider for language management
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const String _localeKey = 'app_locale';

  LocaleNotifier(this._prefs) : super(_prefs.getString(_localeKey) ?? 'en');

  Future<void> setLocale(String locale) async {
    if (locale == state) return;
    await _prefs.setString(_localeKey, locale);
    state = locale;
  }

  bool get isEnglish => state == 'en';
  bool get isBangla => state == 'bn';
}

/// Connectivity provider
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// First launch check
final isFirstLaunchProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('first_launch') ?? true;
});

/// App initialization state
enum AppInitState { initializing, ready, error }

final appInitStateProvider = StateProvider<AppInitState>((ref) {
  return AppInitState.initializing;
});
