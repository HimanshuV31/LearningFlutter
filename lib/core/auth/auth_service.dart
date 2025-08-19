import 'auth_provider.dart';
import 'auth_user.dart';
import 'firebase_auth_provider.dart';

class AuthService implements AuthProvider{
  final AuthProvider provider;
  const AuthService(this.provider);
  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,})
  {
    return provider.createUser(email: email, password: password);
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser {
   return provider.currentUser;
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) async {
    return provider.logIn(email: email, password: password);
  }

  @override
  Future<void> sendEmailVerification() async {
    return provider.sendEmailVerification() ;
  }

  @override
  Future<void> signOut() async{
    return provider.signOut();
  }
  @override
  Future<void> sendPasswordReset({required String email}) async {
    return provider.sendPasswordReset(email: email);
  }
  @override
  Future<void> initialize() async {
    await provider.initialize();
  }
}