import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';


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

    context.read<AuthBloc>().add(AuthEventLogIn(email, password));
    // try {
      // await auth.logIn(email: email, password: password);
      //
      // final user = auth.currentUser;
      //
      // if (user != null) {
      //   if (user.isEmailVerified) {
      //     if (!mounted) return;
      //     // Navigate to home page if email is verified
      //     showCustomToast(context, "Login Successful");
      //     Navigator.pushNamedAndRemoveUntil(context, notesRoute, (_) => false);
      //   } else {
      //     // If email not verified, show message and maybe redirect
      //     if (!mounted) return;
      //     await showCustomRoutingDialog(
      //       context: context,
      //       title: "Verification Pending",
      //       content: "Please verify your email to continue.",
      //       routeButtonText: "Verify Now",
      //       routeToPush: verifyEmailRoute,
      //       cancelButtonText: null,
      //       cancelButtonStyle: null,
      //       barrierDismissible: false,
      //       routeButtonStyle: TextButton.styleFrom(
      //         backgroundColor: Colors.blue,
      //       ),
      //     );
      //   }
      // }
    // } on AuthException catch (e) {
    //   final authError = AuthException.fromCode(e.code);
    //   String message = authError.message;
    //   String errorTitle = authError.title;
    //   if (e.code == "invalid-credential" || e.code == "invalid-email") {
    //     emailController.clear();
    //   }
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text(message)));
    //   await showWarningDialog(
    //     context: context,
    //     title: errorTitle,
    //     message: message,
    //   );
    // } catch (e) {
    //   if (!mounted) return;
    //   await showWarningDialog(
    //     context: context,
    //     title: "Unknown Error",
    //     message: "Unknown Error: $e",
    //   );
    // } finally {
    //   passwordController.clear();
    // }
  }
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.cyan;
    const foregroundColor = Colors.white;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
         if (state is AuthStateNeedsVerification) {
          // Navigate to verify email screen
          context.read<AuthBloc>().add(const AuthEventShouldVerifyEmail());
        } else if (state is AuthStateLoggedOut && state.exception != null) {
          // Display error dialogs for login failure
          final e = state.exception;
          if (e is AuthException) {
            showWarningDialog(
              context: context,
              title: e.title,
              message: e.message,
            );
            emailController.clear();
            passwordController.clear();
          }
        }
      },

      child: Scaffold(
      appBar: CustomAppBar(
        title: "Infinity Notes | Login",
        backgroundColor: Colors.black,
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
                  // onPressed: () => Navigator.pushNamed(context, registerRoute),
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthEventShouldRegister());
                  },
                  child: const Text("New User? Register."),
                ),

                // Password recovery button
                TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      showWarningDialog(
                        context: context,
                        title: "Insert Email",
                        message: "Please enter your email to reset password",
                      );
                      return;
                    }
                    try {
                      // await auth.sendPasswordReset(email: email);
                      context.read<AuthBloc>().add(AuthEventResetPassword(email));
                      if (!mounted) return;
                      showWarningDialog(
                        context: context,
                        title: "Reset Email Sent",
                        message:
                            "Password Reset email has been sent if the email is "
                                "registered.Otherwise, kindly do the registration.",
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
                  //   try {
                  //     final user = await auth.logInWithGoogle();
                  //     if (user != null) {
                  //       if (!mounted) return;
                  //       showCustomToast(context, "Login Successful via Google");
                  //       Navigator.pushNamedAndRemoveUntil(
                  //         context,
                  //         notesRoute,
                  //         (_) => false,
                  //       );
                  //     }
                  //   } on AuthException catch (e) {
                  //     if (!mounted) return;
                  //     if (e.code == 'cancelled') {
                  //       return;
                  //     } else {
                  //       await showWarningDialog(
                  //         context: context,
                  //         title: "Google Sign-In Failed",
                  //         message: e.toString(),
                  //       );
                  //     }
                  //   }
                    context.read<AuthBloc>().add(AuthEventGoogleSignIn());
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
                if (PlatformUtils.isIOS) ...[
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () async {
                      // try {
                      //   final user = await auth.logInWithApple();
                      //   if (user != null && user.isEmailVerified) {
                      //     if (!mounted) return;
                      //     showCustomToast(
                      //       context,
                      //       "Login Successful via Apple",
                      //     );
                      //     Navigator.pushNamedAndRemoveUntil(
                      //       context,
                      //       notesRoute,
                      //       (_) => false,
                      //     );
                      //   }
                      // } catch (e) {
                      //   if (!mounted) return;
                      //   await showWarningDialog(
                      //     context: context,
                      //     title: "Apple Sign-In Failed",
                      //     message: e.toString(),
                      //   );
                      // }
                      context.read<AuthBloc>().add(AuthEventAppleSignIn());
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
    ),
    );
  }
}
