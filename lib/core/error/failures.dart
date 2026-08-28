import 'package:equatable/equatable.dart';

/// Domain-level failure types returned to the presentation layer via
/// `Either`-style results (see [core/utils/result.dart]). Keeping these
/// separate from [Exception]s stops raw platform errors leaking into the UI.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message);
}

class RecordingFailure extends Failure {
  const RecordingFailure(super.message);
}

class AudioProcessingFailure extends Failure {
  const AudioProcessingFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
