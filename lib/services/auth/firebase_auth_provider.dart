import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseAuth, OAuthProvider, GoogleAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_provider.dart';
import 'package:infinity_notes/services/auth/auth_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../firebase_options.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
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
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
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
  Future<void> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
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
  Future<void> signOut() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
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
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode("$e.code");
    } catch (e) {
      throw GenericAuthException("$e.code");
    }
  }

  @override
  Future<AuthUser?> logInWithGoogle() async {
    if (kIsWeb) {
      final userCred = await FirebaseAuth.instance.signInWithPopup(
        GoogleAuthProvider(),
      );
      return AuthUser.fromFirebase(userCred.user!);
    }

    final gsi = GoogleSignIn.instance;
    await gsi.initialize();

    final account = await gsi.authenticate();
    // ignore: unnecessary_null_comparison
    if (account == null) return null;

    final idToken = (account.authentication).idToken;
    if (idToken == null) {
      throw GenericAuthException('missing-id-token');
    }

    final oauth = GoogleAuthProvider.credential(idToken: idToken);
    final userCred = await FirebaseAuth.instance.signInWithCredential(oauth);
    return AuthUser.fromFirebase(userCred.user!);
  }

  @override
  Future<AuthUser?> logInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      oauthCredential,
    );
    return AuthUser.fromFirebase(userCredential.user!);
  }


  Future<void> reloadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // refresh user from Firebase
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }
}
