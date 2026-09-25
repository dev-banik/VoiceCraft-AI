/// App-wide constant values that are not derived from user settings.
class AppConstants {
  AppConstants._();

  static const String appName = 'VoiceCraft AI';

  // Hive box names
  static const String recordingsBox = 'recordings_box';
  static const String settingsBox = 'settings_box';
  static const String userBox = 'user_box';

  // Shared preferences keys
  static const String prefOnboardingComplete = 'onboarding_complete';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String recordingsSubcollection = 'recordings';

  // Storage paths
  static String userRecordingsPath(String uid) => 'users/$uid/recordings';

  // Recording defaults
  static const int defaultSampleRate = 44100;
  static const int highSampleRate = 48000;

  // Editor
  static const double minTrimDurationSeconds = 0.5;

  // Sync
  static const Duration syncDebounce = Duration(seconds: 4);
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
}

/// Which shelf of the library a recording sits on.
///
/// [original] is a take exactly as recorded. [modified] is a processed copy
/// that was saved alongside its source instead of over it. [archivedOriginal]
/// is the audio a recording held before the user replaced it in place — kept
/// so that replacing is never destructive and the untouched take stays
/// reachable.
enum RecordingKind { original, modified, archivedOriginal }

extension RecordingKindLabel on RecordingKind {
  String get label {
    switch (this) {
      case RecordingKind.original:
        return 'Original';
      case RecordingKind.modified:
        return 'Modified';
      case RecordingKind.archivedOriginal:
        return 'Replaced original';
    }
  }
}

/// Supported recording output formats.
enum RecordingFormat { wav, mp3, aac }

/// Recording quality presets, mapped to bitrate by the recorder service.
enum RecordingQuality { standard, high, studio }

/// Voice transformation presets available in the Voice Themes module.
enum VoiceTheme {
  original,
  childVoice,
  youngFemale,
  youngMale,
  cartoonVoice,
  robotVoice,
  mimicryStyle,
  deepVoice,
  oldVoice,
  animeVoice,
  radioPresenter,
}

extension VoiceThemeLabel on VoiceTheme {
  String get label {
    switch (this) {
      case VoiceTheme.original:
        return 'Original';
      case VoiceTheme.childVoice:
        return 'Child Voice';
      case VoiceTheme.youngFemale:
        return 'Young Female';
      case VoiceTheme.youngMale:
        return 'Young Male';
      case VoiceTheme.cartoonVoice:
        return 'Cartoon Voice';
      case VoiceTheme.robotVoice:
        return 'Robot Voice';
      case VoiceTheme.mimicryStyle:
        return 'Mimicry Style';
      case VoiceTheme.deepVoice:
        return 'Deep Voice';
      case VoiceTheme.oldVoice:
        return 'Old Voice';
      case VoiceTheme.animeVoice:
        return 'Anime Voice';
      case VoiceTheme.radioPresenter:
        return 'Radio Presenter';
    }
  }
}
