import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential> signInWithGoogle() async {
  if (kIsWeb) {
    // Web uses a popup—no gsi plugin flow needed.
    return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  final gsi = GoogleSignIn.instance;
  await gsi.initialize();                       // v7 requirement

  final GoogleSignInAccount account = await gsi.authenticate(); // v7 replaces signIn()
  // ignore: unnecessary_null_comparison
  if (account == null) {
    throw FirebaseAuthException(code: 'canceled', message: 'Sign-in aborted by user.');
  }

  final String? idToken = (account.authentication).idToken; // v7: idToken only
  if (idToken == null) {
    throw FirebaseAuthException(code: 'missing-id-token', message: 'Google returned no ID token.');
  }

  final credential = GoogleAuthProvider.credential(idToken: idToken); // no accessToken
  return FirebaseAuth.instance.signInWithCredential(credential);
}
