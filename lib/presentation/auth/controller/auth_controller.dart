import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../services/sync/background_sync_service.dart';

class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref ref;

  AuthController(this.ref) : super(const AsyncValue.data(null));

  Future<Result<UserEntity>> signIn() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authUsecasesProvider).signInWithGoogle();
    result.when(
      ok: (user) async {
        state = AsyncValue.data(user);
        await BackgroundSyncService.rememberUid(user.uid);
        await BackgroundSyncService().schedulePeriodicSync();
        await ref.read(syncUsecasesProvider).syncAll(user.uid);
      },
      err: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
    );
    return result;
  }

  Future<void> signOut() async {
    await ref.read(authUsecasesProvider).signOut();
    await BackgroundSyncService.forgetUid();
    await BackgroundSyncService().cancel();
    state = const AsyncValue.data(null);
  }
}

final StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>
    authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>(
  (ref) => AuthController(ref),
);
