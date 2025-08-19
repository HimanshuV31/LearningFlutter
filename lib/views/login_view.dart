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

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    try {
      await AuthService.firebase().logIn(email: email, password: password);

      final user = AuthService.firebase().currentUser;

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
            Spacer(flex: 2),
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
                      await AuthService.firebase().sendPasswordReset(
                        email: email,
                      );
                      if (!mounted) return;
                      showCustomDialog(
                        context: context,
                        title: "Reset Email Sent",
                        message:
                            "Password Reset email has been sent if the email is registered. Otherwise, kindly do the registration.",
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
            Spacer(flex: 3),
            //Code for Row in which icons of Google, Apple will be shown.
            Row(),
            //After the Row block, we'll print a line of text.(Part of Column)
          ],
        ),
      ),
    );
  }
}
