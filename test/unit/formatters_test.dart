import 'package:flutter_test/flutter_test.dart';
import 'package:voicecraft_ai/core/utils/formatters.dart';

void main() {
  group('Formatters.duration', () {
    test('formats seconds under a minute', () {
      expect(Formatters.duration(const Duration(seconds: 42)), '00:42');
    });

    test('formats minutes and seconds', () {
      expect(
        Formatters.duration(const Duration(minutes: 3, seconds: 5)),
        '03:05',
      );
    });

    test('formats hours when present', () {
      expect(
        Formatters.duration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '01:02:03',
      );
    });
  });

  group('Formatters.fileSize', () {
    test('formats bytes', () {
      expect(Formatters.fileSize(512), '512 B');
    });

    test('formats megabytes', () {
      expect(Formatters.fileSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('zero bytes', () {
      expect(Formatters.fileSize(0), '0 B');
    });
  });
}
