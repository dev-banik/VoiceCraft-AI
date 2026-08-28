// File generated normally by the FlutterFire CLI: `flutterfire configure`.
//
// This checked-in copy is a PLACEHOLDER with dummy values so the project
// compiles out of the box. Replace it by running, from the repo root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// which overwrites this file with real per-platform keys and registers the
// Android/iOS apps in your Firebase project. Do NOT hand-edit the values
// below for a real build — Google Sign-In and Firestore/Storage rules will
// reject requests signed with a placeholder API key.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'VoiceCraft AI targets Android and iOS only; web is not configured.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform. Run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'voicecraft-ai-placeholder',
    storageBucket: 'voicecraft-ai-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'voicecraft-ai-placeholder',
    storageBucket: 'voicecraft-ai-placeholder.appspot.com',
    iosBundleId: 'com.voicecraft.ai',
  );
}
