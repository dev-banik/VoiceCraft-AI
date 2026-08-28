/// Exceptions thrown by data sources (local disk, Hive, Firebase, FFmpeg).
/// Repositories catch these and translate them into [Failure]s for the
/// domain/presentation layers.
class LocalStorageException implements Exception {
  final String message;
  const LocalStorageException(this.message);
  @override
  String toString() => 'LocalStorageException: $message';
}

class RecordingException implements Exception {
  final String message;
  const RecordingException(this.message);
  @override
  String toString() => 'RecordingException: $message';
}

class AudioProcessingException implements Exception {
  final String message;
  const AudioProcessingException(this.message);
  @override
  String toString() => 'AudioProcessingException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => 'SyncException: $message';
}

class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}
