import 'package:equatable/equatable.dart';

/// Signed-in user profile, populated only after Google Sign-In. The app
/// works fully offline/anonymously without this ever being created.
class UserEntity extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl];
}
