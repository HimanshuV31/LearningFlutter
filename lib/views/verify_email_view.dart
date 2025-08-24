import 'package:flutter/material.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/ui/custom_app_bar.dart';

import '../constants/routes.dart';
import '../services/auth/auth_exception.dart';
import '../ui/dialogs.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _isSent = false;
  final auth = AuthService.firebase();

  Future<void> sendVerificationEmail() async {
    try {
      final user = auth.currentUser;
      if (user != null && !user.isEmailVerified) {
        await auth.sendEmailVerification();
        setState(() => _isSent = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent!")),
        );
      }
    } on AuthException catch (e) {
      final authError = AuthException.fromCode(e.code);
      String message = authError.message;
      String errorTitle = authError.title;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await showCustomDialog(
        context: context,
        title: errorTitle,
        message: message,
      );
    } catch (e) {
      await showCustomDialog(
        context: context,
        title: "Unknown Error",
        message: "Unknown Error: $e",
      );
    }
  }

  Future<void> checkVerified() async {
    await auth.reloadUser();
    final isVerified = auth.currentUser?.isEmailVerified ?? false;
    if (!mounted) return;
    if (isVerified) {
      Navigator.pushNamedAndRemoveUntil(context, loginRoute, (_) => false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Still not verified")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.teal;
    const foregroundColor = Colors.white;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Infinity Notes | Verify Email",
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
      ),
      body: Center(
        // Centers horizontally & vertically
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Shrinks column to content
            crossAxisAlignment: CrossAxisAlignment.center,
            // Aligns center horizontally
            children: [
              const Text("Please verify your email."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSent ? null : sendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                ),
                child: const Text("Send Verification Email"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: checkVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: foregroundColor,
                ),
                child: const Text("I have verified"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
