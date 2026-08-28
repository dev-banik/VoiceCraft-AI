// This exact file path is what `flutter create` writes a default smoke
// test to when it's missing — that default references a `MyApp` class this
// project doesn't have (see `lib/app.dart`'s `VoiceCraftApp`), which would
// fail to compile. Committing a real, minimal test here instead means
// `flutter create` (run in CI to fill in Gradle/Xcode boilerplate — see
// .github/workflows/build_apk.yml) skips it rather than overwriting it.
//
// This intentionally does not boot `VoiceCraftApp` itself: doing so needs
// Hive initialized and Firebase mocked, which belongs in a proper
// integration test with real fakes (see docs/ROADMAP.md), not a smoke test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke test renders text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('VoiceCraft AI')),
      ),
    );

    expect(find.text('VoiceCraft AI'), findsOneWidget);
  });
}
