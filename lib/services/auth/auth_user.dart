import "package:firebase_auth/firebase_auth.dart" show User;
import 'package:equatable/equatable.dart';

// @immutable
// class AuthUser
class AuthUser extends Equatable
{
  final String id;
  final bool isEmailVerified;
  final String email;

  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
  });

  @override
  List<Object?> get props => [id, email, isEmailVerified];

  factory AuthUser.fromFirebase(User user) => AuthUser(
    id: user.uid,
    email: user.email!,
    isEmailVerified: user.emailVerified,
  );
}
