/// Centralized route paths/names for go_router. Kept as plain strings
/// (rather than an enum) because go_router matches on path.
class RoutePaths {
  RoutePaths._();

  static const String dashboard = '/';
  static const String record = '/record';
  static const String playback = '/playback/:recordingId';
  static const String noiseRemoval = '/noise-removal/:recordingId';
  static const String voiceThemes = '/voice-themes/:recordingId';
  static const String enhancement = '/enhancement/:recordingId';
  static const String editor = '/editor/:recordingId';
  static const String search = '/search';
  static const String settings = '/settings';

  static String playbackPath(String id) => '/playback/$id';
  static String noiseRemovalPath(String id) => '/noise-removal/$id';
  static String voiceThemesPath(String id) => '/voice-themes/$id';
  static String enhancementPath(String id) => '/enhancement/$id';
  static String editorPath(String id) => '/editor/$id';
}
