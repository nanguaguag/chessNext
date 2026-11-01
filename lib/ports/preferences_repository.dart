import '../application/app_preferences.dart';

class LoadedPreferences {
  const LoadedPreferences(this.value, {this.recovered = false});
  final AppPreferences value;
  final bool recovered;
}

abstract interface class PreferencesRepository {
  Future<LoadedPreferences?> load();
  Future<void> save(AppPreferences value);
}

class MemoryPreferencesRepository implements PreferencesRepository {
  AppPreferences? value;
  @override
  Future<LoadedPreferences?> load() async =>
      value == null ? null : LoadedPreferences(value!);
  @override
  Future<void> save(AppPreferences next) async {
    value = next;
  }
}
