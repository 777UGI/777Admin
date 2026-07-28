import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_cache.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final cachedLang =
        HiveCache.settingsBox.get('language_code', defaultValue: 'en')
            as String;
    state = Locale(cachedLang);
  }

  Future<void> toggleLocale() async {
    final newCode = state.languageCode == 'en' ? 'hi' : 'en';
    state = Locale(newCode);
    await HiveCache.settingsBox.put('language_code', newCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
