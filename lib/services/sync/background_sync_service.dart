import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/local/hive_boxes.dart';
import '../../data/datasources/local/recording_local_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/datasources/remote/storage_datasource.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../firebase_options.dart';

const String backgroundSyncTaskName = 'voicecraft.backgroundSync';
const String prefLastSyncedUid = 'last_synced_uid';

/// Registers a periodic WorkManager (Android) / BGTaskScheduler-backed
/// (iOS, via the `workmanager` plugin) job that runs a full sync for the
/// last signed-in user roughly every [AppConstants.backgroundSyncInterval].
///
/// The UID is cached in SharedPreferences on sign-in (see
/// `AuthController`) because `FirebaseAuth.currentUser` is not reliably
/// available in the separate background isolate WorkManager spins up.
class BackgroundSyncService {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncTaskName,
      frequency: AppConstants.backgroundSyncInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(backgroundSyncTaskName);
  }

  static Future<void> rememberUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefLastSyncedUid, uid);
  }

  static Future<void> forgetUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefLastSyncedUid);
  }
}

/// Entry point WorkManager invokes in a fresh background isolate. Must stay
/// a top-level (or static) function annotated `vm:entry-point` so it
/// survives tree-shaking and AOT compilation.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task != backgroundSyncTaskName) return true;

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(prefLastSyncedUid);
      if (uid == null) return true; // nobody signed in; nothing to do

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await HiveBoxes.init();

      final repo = SyncRepositoryImpl(
        local: const RecordingLocalDatasource(),
        firestore: FirestoreDatasource(),
        storage: StorageDatasource(),
      );
      final result = await repo.syncAll(uid);
      result.when(
        ok: (_) => appLogger.i('Background sync complete for $uid'),
        err: (f) => appLogger.w('Background sync failed: ${f.message}'),
      );
      return true;
    } catch (e) {
      appLogger.e('Background sync isolate crashed', error: e);
      return false;
    }
  });
}
