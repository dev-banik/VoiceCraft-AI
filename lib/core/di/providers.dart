import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/recording_local_datasource.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/datasources/remote/auth_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/datasources/remote/storage_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/recording_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/recording_usecases.dart';
import '../../domain/usecases/search_usecases.dart';
import '../../domain/usecases/sync_usecases.dart';
import '../../services/ai/enhancement_service.dart';
import '../../services/ai/noise_removal_service.dart';
import '../../services/ai/voice_theme_service.dart';
import '../../services/audio/audio_editor_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/audio_recorder_service.dart';
import '../../services/audio/waveform_service.dart';
import '../../services/storage/storage_usage_service.dart';
import '../../services/sync/connectivity_service.dart';

// ---------------------------------------------------------------------------
// Datasources
// ---------------------------------------------------------------------------

final Provider<RecordingLocalDatasource> recordingLocalDatasourceProvider =
    Provider((ref) => const RecordingLocalDatasource());

final Provider<SettingsLocalDatasource> settingsLocalDatasourceProvider =
    Provider((ref) => const SettingsLocalDatasource());

final Provider<AuthDatasource> authDatasourceProvider =
    Provider((ref) => AuthDatasource());

final Provider<FirestoreDatasource> firestoreDatasourceProvider =
    Provider((ref) => FirestoreDatasource());

final Provider<StorageDatasource> storageDatasourceProvider =
    Provider((ref) => StorageDatasource());

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final Provider<RecordingRepository> recordingRepositoryProvider =
    Provider((ref) {
  return RecordingRepositoryImpl(ref.watch(recordingLocalDatasourceProvider));
});

final Provider<AuthRepository> authRepositoryProvider = Provider((ref) {
  return AuthRepositoryImpl(ref.watch(authDatasourceProvider));
});

final Provider<SyncRepository> syncRepositoryProvider = Provider((ref) {
  return SyncRepositoryImpl(
    local: ref.watch(recordingLocalDatasourceProvider),
    firestore: ref.watch(firestoreDatasourceProvider),
    storage: ref.watch(storageDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Usecases
// ---------------------------------------------------------------------------

final Provider<RecordingUsecases> recordingUsecasesProvider = Provider(
  (ref) => RecordingUsecases(ref.watch(recordingRepositoryProvider)),
);

final Provider<SearchRecordingsUsecase> searchRecordingsUsecaseProvider =
    Provider(
  (ref) => SearchRecordingsUsecase(ref.watch(recordingRepositoryProvider)),
);

final Provider<AuthUsecases> authUsecasesProvider = Provider(
  (ref) => AuthUsecases(ref.watch(authRepositoryProvider)),
);

final Provider<SyncUsecases> syncUsecasesProvider = Provider(
  (ref) => SyncUsecases(ref.watch(syncRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Services (audio engine + AI pipeline)
// ---------------------------------------------------------------------------

final Provider<AudioRecorderService> audioRecorderServiceProvider =
    Provider((ref) {
  final service = AudioRecorderService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<AudioPlayerService> audioPlayerServiceProvider = Provider((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final Provider<WaveformService> waveformServiceProvider =
    Provider((ref) => WaveformService());

final Provider<AudioEditorService> audioEditorServiceProvider =
    Provider((ref) => AudioEditorService());

final Provider<NoiseRemovalService> noiseRemovalServiceProvider =
    Provider((ref) => NoiseRemovalService());

final Provider<VoiceThemeService> voiceThemeServiceProvider =
    Provider((ref) => VoiceThemeService());

final Provider<AudioEnhancementService> enhancementServiceProvider =
    Provider((ref) => AudioEnhancementService());

final Provider<StorageUsageService> storageUsageServiceProvider =
    Provider((ref) => StorageUsageService());

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider((ref) => ConnectivityService());

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

final StreamProvider<UserEntity?> authStateProvider =
    StreamProvider<UserEntity?>((ref) {
  return ref.watch(authUsecasesProvider).authStateChanges();
});

final Provider<bool> isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});
