import 'package:flutter_test/flutter_test.dart';
import 'package:voicecraft_ai/core/error/failures.dart';
import 'package:voicecraft_ai/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok carries a value and isOk is true', () {
      const result = Result<int>.ok(42);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
    });

    test('Err carries a failure and isErr is true', () {
      const result = Result<int>.err(UnknownFailure('boom'));
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
    });

    test('when() dispatches to the matching branch', () {
      const ok = Result<String>.ok('hello');
      final okOutcome = ok.when(ok: (v) => 'ok:$v', err: (f) => 'err:${f.message}');
      expect(okOutcome, 'ok:hello');

      const err = Result<String>.err(UnknownFailure('bad'));
      final errOutcome =
          err.when(ok: (v) => 'ok:$v', err: (f) => 'err:${f.message}');
      expect(errOutcome, 'err:bad');
    });
  });
}
