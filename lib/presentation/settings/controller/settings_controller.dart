import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/local/settings_local_datasource.dart';
import '../../../data/models/app_settings_model.dart';

final Provider<SettingsLocalDatasource> settingsDatasourceProvider =
    Provider((ref) => const SettingsLocalDatasource());

class SettingsController extends StateNotifier<AppSettingsModel> {
  final SettingsLocalDatasource _datasource;

  SettingsController(this._datasource) : super(_datasource.get());

  Future<void> _update(AppSettingsModel Function(AppSettingsModel) apply) async {
    state = apply(state);
    await _datasource.save(state);
  }

  Future<void> setRecordingFormat(RecordingFormat format) =>
      _update((s) => s.copyWith(recordingFormat: format.name));

  Future<void> setSampleRate(int rate) =>
      _update((s) => s.copyWith(sampleRate: rate));

  Future<void> setRecordingQuality(RecordingQuality quality) =>
      _update((s) => s.copyWith(recordingQuality: quality.name));

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode.name));

  Future<void> setAutoBackup(bool enabled) =>
      _update((s) => s.copyWith(autoBackupEnabled: enabled));

  Future<void> setBackupOnWifiOnly(bool enabled) =>
      _update((s) => s.copyWith(backupOnWifiOnly: enabled));

  Future<void> setDefaultVoiceTheme(VoiceTheme theme) =>
      _update((s) => s.copyWith(defaultVoiceTheme: theme.name));

  ThemeMode get themeMode {
    switch (state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final StateNotifierProvider<SettingsController, AppSettingsModel>
    settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettingsModel>((ref) {
  return SettingsController(ref.watch(settingsDatasourceProvider));
});
