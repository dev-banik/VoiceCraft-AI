import '../error/failures.dart';

/// A minimal Either-style result type so repositories/usecases never throw
/// across layer boundaries. Avoids pulling in a full fpdart/dartz
/// dependency for a two-case union.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    if (self is Err<T>) return err(self.failure);
    throw StateError('Unreachable');
  }

  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
