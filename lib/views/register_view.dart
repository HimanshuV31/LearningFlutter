import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';
import 'package:infinity_notes/constants/routes.dart';

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

  CloseDialog? _closeDialogHandle;
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
    final _email = _emailController.text.trim();
    final _password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;
    if (!_passwordsMatch) return;

    // try {
    //   await AuthService.firebase().createUser(
    //     email: _email,
    //     password: _password,
    //   );
    //   if (!mounted) return;
    //   await showCustomRoutingDialog(
    //     context: context,
    //     title: "Verification Pending",
    //     content: "Please verify your email to continue.",
    //     routeButtonText: "Verify Now",
    //     routeToPush: verifyEmailRoute,
    //     cancelButtonText: null,
    //     cancelButtonStyle: null,
    //     barrierDismissible: false,
    //     routeButtonStyle: TextButton.styleFrom(
    //       backgroundColor: Colors.blue,
    //     ),
    //   );
    // } on AuthException catch (e) {
    //   final authError = AuthException.fromCode(e.code);
    //   String message = authError.message;
    //   String errorTitle = authError.title;
    //   await showWarningDialog(
    //     context: context,
    //     title: errorTitle,
    //     message: message,
    //   );
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text(message)));
    // } catch (e) {
    //   await showWarningDialog(
    //     context: context,
    //     title: "Unknown Error",
    //     message: "Unknown Error: $e",
    //   );
    // }
    context.read<AuthBloc>().add(AuthEventRegister(
      email: _email,
      password: _password,
    ));
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async{
        if (state is AuthStateLoggedOut && state.exception != null) {
          final closeDialog=_closeDialogHandle;
          if(!state.isLoading && closeDialog!=null){
            closeDialog();
            _closeDialogHandle=null;
          }else if(state.isLoading && closeDialog==null){
            _closeDialogHandle = showLoadingDialog(
              context: context,
              text: "Loading... .. .",
            );
          }
          // Display error dialogs for login failure
          final e = state.exception;
          if (e is AuthException) {
            await showWarningDialog(
              context: context,
              title: e.title,
              message: e.message,
            );
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Infinity Notes | Register",
          backgroundColor: Colors.black,
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
                  decoration: InputDecoration(labelText: "Password"),
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
                          _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
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
