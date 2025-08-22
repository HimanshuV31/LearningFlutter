import 'package:flutter/material.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/views/login_view.dart';
import 'package:infinity_notes/views/notes_view.dart';
import 'package:infinity_notes/views/verify_email_view.dart';

class StartupView extends StatelessWidget {
  final Future<void> firebaseInit;
  const StartupView({super.key, required this.firebaseInit});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebaseInit, // Wait for Firebase
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Display logo while Firebase initializes
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/Infinity_Notes_Icon.png", // <-- your logo here
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.note, size: 80, color: Colors.blue);
                    },
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(), // optional loading indicator
                ],
              ),
            ),
          );
        }

        // Firebase is ready, check current user
        final user = AuthService.firebase().currentUser;
        if (user != null) {
          if (user.isEmailVerified) {
            return const NotesView();
          } else {
            return const VerifyEmailView();
          }
        }else {
          return const LoginView();
        }
      },
    );
  }
}
