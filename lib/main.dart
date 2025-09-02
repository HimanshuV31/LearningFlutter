import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/services/auth/firebase_auth_provider.dart';
import 'package:infinity_notes/views/login_view.dart';
import 'package:infinity_notes/views/notes/create_update_note_view.dart';
import 'package:infinity_notes/views/notes/notes_view.dart';
import 'package:infinity_notes/views/register_view.dart';
import 'package:infinity_notes/views/verify_email_view.dart';
import 'constants/routes.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     MaterialApp(
//       title: 'Infinity Notes',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: BlocProvider<AuthBloc>(
//         create: (context) => AuthBloc(FirebaseAuthProvider()),
//         child: HomePage(),
//       ),
//       routes: {
//         loginRoute: (context) => const LoginView(),
//         registerRoute: (context) => const RegisterView(),
//         verifyEmailRoute: (context) => const VerifyEmailView(),
//         notesRoute: (context) => const NotesView(),
//         CreateUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
//       },
//     ),
//   );
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(FirebaseAuthProvider()),
      child: const MyApp(), // Now MyApp builds MaterialApp
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialized = false;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(!_initialized){
      context.read<AuthBloc>().add(const AuthEventInitialize());
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLoggedOut) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              loginRoute, (route) => false);
        } else if (state is AuthStateLoggedIn) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              notesRoute, (route) => false);
        } else if (state is AuthStateNeedsVerification) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              verifyEmailRoute, (route) => false);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthStateLoggedIn) {
            return const NotesView();
          } else if (state is AuthStateNeedsVerification) {
            return const VerifyEmailView();
          } else if (state is AuthStateLoginFailure || state is AuthStateLoggedOut) {
            return const LoginView();
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}

// //New HomePage with Bloc (Only for Study purposes)
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   late final TextEditingController _controller;
//   final Color foregroundColor = Colors.white;
//   final Color backgroundColor = Colors.cyanAccent;
//
//   @override
//   void initState() {
//     _controller = TextEditingController();
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => CounterBloc(),
//       child: Scaffold(
//         appBar: CustomAppBar(
//           title: "Testing Bloc",
//           foregroundColor: foregroundColor,
//           backgroundColor: Colors.black,
//         ),
//         body: BlocConsumer<CounterBloc, CounterState>(
//           listener: (context, state) {
//             _controller.clear();
//           },
//           builder: (context, state) {
//             final invalidValue = (state is CounterStateInvalidNumber)
//                 ? state.invalidValue
//                 : '';
//             return Column(
//               children: [
//                 Text("Current Value =>${state.value}"),
//                 Visibility(
//                   child: Text("Invalid input: $invalidValue"),
//                   visible: state is! CounterStateInvalidNumber,
//                 ),
//                 TextField(
//                   controller: _controller,
//                   decoration: const InputDecoration(hintText: "Enter a number"),
//                   keyboardType: TextInputType.number,
//                 ),
//                 Row(
//                   children: [
//                     ElevatedButton(
//                       onPressed: (){
//                         context
//                             .read<CounterBloc>()
//                             .add(DecrementEvent(_controller.text));
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         foregroundColor: foregroundColor,
//                       ),
//                       child: const Text("-"),
//                     ),
//                     const SizedBox(width: 15),
//                     ElevatedButton(
//                       onPressed: (){
//                         context
//                             .read<CounterBloc>()
//                             .add(IncrementEvent(_controller.text));
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: backgroundColor,
//                         foregroundColor: foregroundColor,
//                       ),
//                       child: const Text("+"),
//                     ),
//                   ],
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// //Bloc Classes
//
// @immutable
// abstract class CounterState {
//   final int value;
//
//   const CounterState(this.value);
// }
//
// class CounterStateValid extends CounterState {
//   const CounterStateValid(int value) : super(value);
// }
//
// class CounterStateInvalidNumber extends CounterState {
//   final String invalidValue;
//
//   const CounterStateInvalidNumber({
//     required this.invalidValue,
//     required int previousValue,
//   }) : super(previousValue);
// }
//
// @immutable
// abstract class CounterEvent {
//   final String value;
//
//   const CounterEvent(this.value);
// }
//
// class IncrementEvent extends CounterEvent {
//   const IncrementEvent(String value) : super(value);
// }
//
// class DecrementEvent extends CounterEvent {
//   const DecrementEvent(String value) : super(value);
// }
//
// class CounterBloc extends Bloc<CounterEvent, CounterState> {
//   CounterBloc() : super(const CounterStateValid(0)) {
//     on<IncrementEvent>((event, emit) {
//       final integer = int.tryParse(event.value);
//       if (integer == null) {
//         emit(
//           CounterStateInvalidNumber(
//             invalidValue: event.value,
//             previousValue: state.value,
//           ),
//         );
//       } else {
//         emit(CounterStateValid(state.value + integer));
//       }
//     });
//     on<DecrementEvent>((event, emit) {
//       final integer = int.tryParse(event.value);
//       if (integer == null) {
//         emit(
//           CounterStateInvalidNumber(
//             invalidValue: event.value,
//             previousValue: state.value,
//           ),
//         );
//       } else {
//         emit(CounterStateValid(state.value - integer));
//       }
//     });
//   }
// }
