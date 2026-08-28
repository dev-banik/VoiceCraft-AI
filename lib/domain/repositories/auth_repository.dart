import '../../core/utils/result.dart';
import '../entities/user_entity.dart';

/// Domain contract for Google Sign-In authentication. There is no
/// email/password path by design — see project spec.
abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();
  UserEntity? get currentUser;
  Future<Result<UserEntity>> signInWithGoogle();
  Future<Result<void>> signOut();
}
