import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_user.dart';

@immutable
abstract class AuthState{
  const AuthState();
}
// class AuthStateLoginFailure extends AuthState{
//   final Exception exception;
//   const AuthStateLoginFailure(this.exception);
// }
// class AuthStateLoading extends AuthState{
//   const AuthStateLoading();
// }
// class AuthStateLogoutFailure extends AuthState{
//   final Exception exception;
//   const AuthStateLogoutFailure(this.exception);
// }
class AuthStateLoggedIn extends AuthState{
  const AuthStateLoggedIn(this.user);
  final AuthUser user;
}
class AuthStateNeedsVerification extends AuthState{
  const AuthStateNeedsVerification();
}
class AuthStateLoggedOut extends AuthState with EquatableMixin{
  final Exception? exception;
  final bool isLoading;
  const AuthStateLoggedOut({ required this.exception, this.isLoading = false});
  @override
  List<Object?> get props => [exception,isLoading];
}
class AuthStateUninitialized extends AuthState{
  const AuthStateUninitialized();
}
class AuthStateRegisterFailure extends AuthState{
  final Exception? exception;
  const AuthStateRegisterFailure({required this.exception});
}
class AuthStateRegistering extends AuthState {
  const AuthStateRegistering();
}