import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:infinity_notes/ui/custom_toast.dart';
import '../core/auth/auth_exception.dart';
import '../core/auth/auth_service.dart';
import '../constants/routes.dart';
import '../core/dialogs.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final auth = AuthService.firebase();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    try {
      await auth.logIn(email: email, password: password);

      final user = auth.currentUser;

      if (user != null) {
        if (user.isEmailVerified) {
          if (!mounted) return;
          // Navigate to home page if email is verified
          showCustomToast(context, "Login Successful");
          Navigator.pushNamedAndRemoveUntil(context, notesRoute, (_) => false);
        } else {
          // If email not verified, show message and maybe redirect
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false, // forces the user to press a button
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Verification Pending"),
                content: const Text(
                  "Please verify your email before logging in.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                    },
                    child: const Text("Close"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pushNamed(context, verifyEmailRoute);
                    },
                    child: const Text("Verify Now"),
                  ),
                ],
              );
            },
          );
        }
      }
    } on AuthException catch (e) {
      final authError = AuthException.fromCode(e.code);
      String message = authError.message;
      String errorTitle = authError.title;
      if (e.code == "invalid-credential" || e.code == "invalid-email") {
        emailController.clear();
      }
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
      if (!mounted) return;
      await showCustomDialog(
        context: context,
        title: "Unknown Error",
        message: "Unknown Error: $e",
      );
    } finally {
      passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.cyan;
    const foregroundColor = Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Infinity Notes | Login"),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
              child: const Text("Login"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Registration button
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, registerRoute),
                  child: const Text("New User? Register."),
                ),

                // Password recovery button
                TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      showCustomDialog(
                        context: context,
                        title: "Insert Email",
                        message: "Please enter your email to reset password",
                      );
                      return;
                    }
                    try {
                      await auth.sendPasswordReset(email: email,);
                      if (!mounted) return;
                      showCustomDialog(
                        context: context,
                        title: "Reset Email Sent",
                        message:
                            "Password Reset email has been sent if the email is registered."
                            "Otherwise, kindly do the registration.",
                      );
                    } on AuthException catch (e) {
                      final authError = AuthException.fromCode(e.code);
                      if (e.code == "invalid-credential" ||
                          e.code == "invalid-email") {
                        emailController.clear();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authError.message)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Unknown Error: $e")),
                      );
                    }
                  },
                  child: const Text("Forgot Password?"),
                ),
              ],
            ),
            //Text stating Social Login
            const SizedBox(height: 17),
            const Text(
              "Or sign in with a social account",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            //Row for Social Logins
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google
                GestureDetector(
                  onTap: () async {
                    try {
                      final user = await auth.logInWithGoogle();
                      if (user != null && user.isEmailVerified) {
                        if (!mounted) return;
                        showCustomToast(context, "Login Successful via Google");
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          notesRoute,
                          (_) => false,
                        );
                      }
                    } on AuthException catch (e) {
                      if (!mounted) return;
                      if (e.code == 'cancelled') {
                        return;
                      } else {
                        await showCustomDialog(
                          context: context,
                          title: "Google Sign-In Failed",
                          message: e.toString(),
                        );
                      }
                    }
                  },
                  child: Column(
                    children: [
                      Image.asset('assets/icons/google_logo.png', height: 40),
                      const SizedBox(height: 4),
                      const Text("Google"),
                    ],
                  ),
                ),

                // Only add spacing + Apple button if on iOS
                if (Platform.isIOS) ...[
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final user = await auth.logInWithApple();
                        if (user != null && user.isEmailVerified) {
                          if (!mounted) return;
                          showCustomToast(
                            context,
                            "Login Successful via Apple",
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            notesRoute,
                            (_) => false,
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        await showCustomDialog(
                          context: context,
                          title: "Apple Sign-In Failed",
                          message: e.toString(),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Image.asset('assets/icons/apple_logo.png', height: 40),
                        const SizedBox(height: 4),
                        const Text("Apple"),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
