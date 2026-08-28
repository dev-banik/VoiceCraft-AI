import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'data/datasources/local/hive_boxes.dart';
import 'firebase_options.dart';
import 'services/sync/background_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveBoxes.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase is optional for the offline-first core experience — the app
    // must still boot to onboarding/dashboard/record/playback/editor even
    // if `firebase_options.dart` still holds placeholder keys (see that
    // file's header). Cloud Sign-In/Sync screens surface a clear error if
    // the user tries to use them before real Firebase config is in place.
    appLogger.w('Firebase init failed — cloud features will be disabled: $e');
  }

  try {
    await BackgroundSyncService().initialize();
  } catch (e) {
    appLogger.w('Background sync init failed: $e');
  }

  runApp(const ProviderScope(child: VoiceCraftApp()));
}
