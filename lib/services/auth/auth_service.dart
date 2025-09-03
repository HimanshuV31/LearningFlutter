import 'package:infinity_notes/services/auth/auth_user.dart' as local_auth;
import 'auth_provider.dart'as local_auth;
import 'firebase_auth_provider.dart';

class AuthService implements local_auth.AuthProvider {
  final local_auth.AuthProvider provider;
  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider() as local_auth.AuthProvider);

  @override
  Future<local_auth.AuthUser> createUser({
    required String email,
    required String password,
  }) {
    return provider.createUser(email: email, password: password);
  }

  @override
  local_auth.AuthUser? get currentUser => provider.currentUser;

  @override
  Future<local_auth.AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    return provider.logIn(email: email, password: password);
  }

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> signOut() => provider.signOut();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      provider.sendPasswordReset(email: email);

  @override
  Future<void> initialize() async => await provider.initialize();

  @override
  Future<local_auth.AuthUser?> logInWithApple() async =>
      provider.logInWithApple();

  @override
  Future<local_auth.AuthUser?> logInWithGoogle() async =>
      provider.logInWithGoogle();

  @override
  Future<local_auth.AuthUser?> reloadUser() => provider.reloadUser();

}
