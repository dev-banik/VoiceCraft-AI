import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;

  const AuthRepositoryImpl(this.datasource);

  @override
  Stream<UserEntity?> authStateChanges() {
    return datasource.authStateChanges().map(_map);
  }

  @override
  UserEntity? get currentUser => _map(datasource.currentUser);

  UserEntity? _map(fb.User? user) {
    if (user == null) return null;
    return UserEntity(
      uid: user.uid,
      displayName: user.displayName ?? 'VoiceCraft User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      final user = await datasource.signInWithGoogle();
      final entity = _map(user);
      if (entity == null) {
        return const Result.err(AuthFailure('Sign-in failed.'));
      }
      return Result.ok(entity);
    } on AuthException catch (e) {
      return Result.err(AuthFailure(e.message));
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await datasource.signOut();
      return const Result.ok(null);
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }
}
