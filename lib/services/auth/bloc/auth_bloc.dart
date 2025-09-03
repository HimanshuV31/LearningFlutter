import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_provider.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider) : super(const AuthStateLoading()) {
   //Initialize
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();

      try{
        debugPrint("AuthBloc: Reloading user");
        await provider.reloadUser();
      }catch(_){
        debugPrint("AuthBloc: Error reloading user");
      }

      final user = provider.currentUser;
      if (user == null) {
        emit(const AuthStateLoggedOut(null));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification());
      } else {
        emit(AuthStateLoggedIn(user));
      }
    });
    //Login
    on<AuthEventLogIn>((event, emit) async {
      emit(const AuthStateLoading());
      final email= event.email;
      final password = event.password;
      try {
        final user = await provider.logIn(
          email: email,
          password:password,
        );
        if(user == null){
          debugPrint("AuthBloc (on<AuthEventLogIn>): User is null");
          // emit(const AuthStateLoggedOut(null));
          // return;
        }
        debugPrint("AuthBloc (on<AuthEventLogIn>): Reloading user");
        final freshUser= await provider.reloadUser();
        debugPrint("AuthBloc (on<AuthEventLogIn>): Reload successful");

        if (freshUser == null) {
          emit(const AuthStateLoggedOut(null));
          return;
        }
        if (!freshUser.isEmailVerified) {
          emit(const AuthStateNeedsVerification());
        } else {
          debugPrint("AuthBloc (on<AuthEventLogIn>): Attempt: User logged in");
          emit(AuthStateLoggedIn(freshUser));
          debugPrint("AuthBloc (on<AuthEventLogIn>): Success: User logged in");
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(e));
      } on Exception catch (e){
        emit(AuthStateLoggedOut(GenericAuthException(e.toString())));
      }
    });
    //Logout
    on<AuthEventLogOut>((event, emit) async {
      emit(const AuthStateLoading());
      try {
        await provider.signOut();
        emit(const AuthStateLoggedOut(null));
      } on Exception catch (e) {
        emit(AuthStateLogoutFailure(e));
      }
    });
  }
}
