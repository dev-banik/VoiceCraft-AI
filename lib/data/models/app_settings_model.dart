import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

/// Single Hive object (key `'settings'` in [AppConstants.settingsBox])
/// holding all user preferences from the Settings screen.
@HiveType(typeId: 1)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  final String recordingFormat;

  @HiveField(1)
  final int sampleRate;

  @HiveField(2)
  final String recordingQuality;

  @HiveField(3)
  final String themeMode; // 'system' | 'light' | 'dark'

  @HiveField(4)
  final bool autoBackupEnabled;

  @HiveField(5)
  final bool backupOnWifiOnly;

  @HiveField(6)
  final String languageCode;

  @HiveField(7)
  final String defaultVoiceTheme;

  AppSettingsModel({
    this.recordingFormat = 'wav',
    this.sampleRate = 44100,
    this.recordingQuality = 'high',
    this.themeMode = 'system',
    this.autoBackupEnabled = false,
    this.backupOnWifiOnly = true,
    this.languageCode = 'en',
    this.defaultVoiceTheme = 'original',
  });

  AppSettingsModel copyWith({
    String? recordingFormat,
    int? sampleRate,
    String? recordingQuality,
    String? themeMode,
    bool? autoBackupEnabled,
    bool? backupOnWifiOnly,
    String? languageCode,
    String? defaultVoiceTheme,
  }) {
    return AppSettingsModel(
      recordingFormat: recordingFormat ?? this.recordingFormat,
      sampleRate: sampleRate ?? this.sampleRate,
      recordingQuality: recordingQuality ?? this.recordingQuality,
      themeMode: themeMode ?? this.themeMode,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupOnWifiOnly: backupOnWifiOnly ?? this.backupOnWifiOnly,
      languageCode: languageCode ?? this.languageCode,
      defaultVoiceTheme: defaultVoiceTheme ?? this.defaultVoiceTheme,
    );
  }
}
