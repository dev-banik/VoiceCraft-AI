import '../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUsecases {
  final AuthRepository repository;
  const AuthUsecases(this.repository);

  Stream<UserEntity?> authStateChanges() => repository.authStateChanges();

  UserEntity? get currentUser => repository.currentUser;

  Future<Result<UserEntity>> signInWithGoogle() =>
      repository.signInWithGoogle();

  Future<Result<void>> signOut() => repository.signOut();
}
