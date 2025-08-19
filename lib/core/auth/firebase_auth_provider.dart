import 'package:firebase_core/firebase_core.dart';
import 'package:infinity_notes/core/auth/auth_exception.dart';
import 'package:infinity_notes/core/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseAuth;
import 'package:infinity_notes/core/auth/auth_user.dart';
import '../../firebase_options.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> createUser({required String email,required String password,}) async
  {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      // throw getAuthErrorMessage(e.code); /*older one*/
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e.code");
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Future<AuthUser> logIn({required String email,required String password,}) async
  {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        return AuthUser.fromFirebase(user);
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e.code");
    }
  }

  @override
  Future<void> sendEmailVerification() async
  {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }catch (e) {
      throw GenericAuthException("$e.code");
    }
  }

  @override
  Future<void> signOut() async
  {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }catch (e) {
      throw GenericAuthException("$e.code");
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }on FirebaseAuthException catch (e){
      throw AuthException.fromCode("$e.code");
    }catch (e){
      throw GenericAuthException("$e.code");
    }
  }
}
