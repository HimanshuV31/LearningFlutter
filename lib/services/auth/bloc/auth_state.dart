import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:infinity_notes/services/auth/auth_user.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final String? loadingText;

  const AuthState({
    required this.isLoading,
    this.loadingText = "Loading... Please wait.",
  });
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
class AuthStateLoggedIn extends AuthState {
  const AuthStateLoggedIn({
    required this.user,
    required bool isLoading,
  }): super(isLoading: isLoading);
  final AuthUser user;
}

class AuthStateNeedsVerification extends AuthState {
  const AuthStateNeedsVerification({required bool isLoading})
      : super(isLoading: isLoading);
}

class AuthStateLoggedOut extends AuthState with EquatableMixin {
  final Exception? exception;

  const AuthStateLoggedOut({
    required this.exception,
    required bool isLoading,
    String? loadingText,
  }) : super(
    isLoading: isLoading,
    loadingText: loadingText,
  );
  @override
  List<Object?> get props => [exception, isLoading];
}

class AuthStateUninitialized extends AuthState {

  const AuthStateUninitialized({required bool isLoading})
      : super(isLoading: isLoading);
}

class AuthStateRegistering extends AuthState {
  final Exception? exception;

  const AuthStateRegistering({
    required this.exception,
    required bool isLoading,
  }): super(isLoading: isLoading);
}
