import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:infinity_notes/core/auth/auth_exception.dart';

import '../core/dialogs.dart';
import '../constants/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEmailValid = false;
  final bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Password rules tracking
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordsMatch = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validatePassword(String password) {
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasMinLength = password.length >= 8;
      _passwordsMatch = password == _confirmPasswordController.text;
    });
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false, // forces the user to press a button
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Registration Successful"),
            content: const Text("Please verify your email."),
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
    } on AuthException catch (e) {
      final authError = AuthException.fromCode(e.code);
      String message = authError.message;
      String errorTitle = authError.title;
      await showCustomDialog(
        context: context,
        title: errorTitle,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      await showCustomDialog(
        context: context,
        title: "Unknown Error",
        message: "Unknown Error: $e",
      );
    }
  }

  Widget _buildPasswordCriteria(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: condition ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.amber;
    const foregroundColor = Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Infinity Notes | Register"),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  suffixIcon: Icon(
                    _isEmailValid ? Icons.check_circle : Icons.cancel,
                    color: _isEmailValid ? Colors.green : Colors.red,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _isEmailValid = isValidEmail(value.trim());
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!isValidEmail(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",

                  /*The code below is for password visibility.
                  But, we'll keep it available for CONFIRM PASSWORD field only*/

                  // suffixIcon: IconButton(
                  //   icon: Icon(
                  //     _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  //   ),
                  //   onPressed: () {
                  //     setState(() {
                  //       _isPasswordVisible = !_isPasswordVisible;
                  //     });
                  //   },
                  // ),
                ),
                obscureText: !_isPasswordVisible,
                onChanged: (value) {
                  _validatePassword(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (!_hasUpperCase ||
                      !_hasLowerCase ||
                      !_hasNumber ||
                      !_hasSpecialChar ||
                      !_hasMinLength) {
                    return 'Password does not meet all criteria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                onChanged: (value) {
                  setState(() {
                    _passwordsMatch = value == _passwordController.text;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Password Criteria
              _buildPasswordCriteria(
                "At least 1 uppercase letter",
                _hasUpperCase,
              ),
              _buildPasswordCriteria(
                "At least 1 lowercase letter",
                _hasLowerCase,
              ),
              _buildPasswordCriteria("At least 1 number", _hasNumber),
              _buildPasswordCriteria("Minimum 8 characters", _hasMinLength),
              _buildPasswordCriteria(
                "At least 1 special character",
                _hasSpecialChar,
              ),
              _buildPasswordCriteria("Passwords match", _passwordsMatch),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                ),
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
