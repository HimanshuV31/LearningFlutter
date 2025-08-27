import 'package:flutter/material.dart';
import 'services/auth/auth_service.dart';
import 'constants/routes.dart';
import 'views/startup_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/verify_email_view.dart';
import 'views/notes/notes_view.dart';
import 'views/notes/create_update_note_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseInit =  AuthService.firebase().initialize(); /*Initialized the custom Auth Service*/
  runApp(MyApp(firebaseInit: firebaseInit));
}

class MyApp extends StatelessWidget {
  final Future<void> firebaseInit;
  const MyApp({super.key, required this.firebaseInit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StartupView(firebaseInit: firebaseInit,),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        notesRoute: (context) => const NotesView(),
        CreateUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
      },
    );
  }
}
