import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_provider.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider) : super(const AuthStateUninitialized()) {
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
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification());
      } else {
        emit(AuthStateLoggedIn(user));
      }
    });
    //Login
    on<AuthEventLogIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true));
      final email= event.email;
      final password = event.password;
      try {
        await provider.logIn(
          email: email,
          password:password,
        );
        final freshUser= await provider.reloadUser();
        if (freshUser == null) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          return;
        }
        if (!freshUser.isEmailVerified) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(const AuthStateNeedsVerification());
        } else {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(AuthStateLoggedIn(freshUser));
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      } on Exception catch (e){
        emit(AuthStateLoggedOut(
            exception: GenericAuthException(e.toString()),
            isLoading: false));
      }
    });
    //Google Login
    on<AuthEventGoogleSignIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true));
      try {
        final user = await provider.logInWithGoogle();
        if(user!=null){
          emit( AuthStateLoggedIn(user));
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
        }
    });
    //Apple Login
    on<AuthEventAppleSignIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true));
      try {
        final user = await provider.logInWithApple();
        if(user!=null){
          emit( AuthStateLoggedIn(user));
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
    //Logout
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.signOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      } on Exception catch (e){
        emit(AuthStateLoggedOut(
            exception: GenericAuthException(e.toString()),
            isLoading: false));
      }
    });
    //Register
    on<AuthEventRegister>((event,emit)async{
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(
          email: email,
          password: password,
        );
        emit(const AuthStateNeedsVerification());
      } on AuthException catch (e) {
        emit(AuthStateRegisterFailure(exception: e));
      } on Exception catch (e) {
        emit(AuthStateRegisterFailure(
          exception: GenericAuthException(e.toString()),
        ));
      }
    });
    //Send Verification Email
    on<AuthEventSendEmailVerification>((event, emit) async
    {
      await provider.sendEmailVerification();
      emit(state);
    });
  }
}
