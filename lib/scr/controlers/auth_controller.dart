import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class AuthController extends Cubit<AuthState> {
  AuthController() : super(const AuthState()) {
    _init();
  }

  late final StreamSubscription<User?> _authSub;
  final _googleSignIn = GoogleSignIn();

  void _init() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (isClosed) return;
      if (user == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } else if (user.emailVerified) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } else {
        emit(AuthState(status: AuthStatus.emailNotVerified, user: user));
      }
    });
  }

  // Login com e-mail e senha
  Future<void> signInWithEmailPassword(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _authErrorMessage(e.code),
        ),
      );
    }
  }

  // Cadastro com e-mail e senha
  Future<void> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _registerErrorMessage(e.code),
        ),
      );
    }
  }

  // Login com Google
  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _authErrorMessage(e.code),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Falha no login com Google. Tente novamente.',
        ),
      );
    }
  }

  // Verificacao de e-mail
  Future<void> checkEmailVerification() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.emailNotVerified,
            errorMessage:
                'E-mail ainda não confirmado. Verifique sua caixa de entrada.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.emailNotVerified,
          errorMessage: 'Erro ao verificar. Tente novamente.',
        ),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      emit(state.copyWith(successMessage: 'E-mail reenviado com sucesso!'));
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'too-many-requests'
          ? 'Aguarde antes de reenviar o e-mail.'
          : 'Erro ao reenviar o e-mail.';
      emit(state.copyWith(errorMessage: msg));
    }
  }

  // Logout
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  String _authErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'Usuário não encontrado.',
      'wrong-password' => 'Senha incorreta.',
      'invalid-email' => 'E-mail inválido.',
      'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
      'invalid-credential' => 'E-mail ou senha incorretos.',
      'network-request-failed' => 'Sem conexão com a internet.',
      _ => 'Erro ao entrar. Tente novamente.',
    };
  }

  String _registerErrorMessage(String code) {
    return switch (code) {
      'email-already-in-use' => 'Este e-mail já está em uso.',
      'invalid-email' => 'E-mail inválido.',
      'weak-password' => 'Senha muito fraca. Use pelo menos 6 caracteres.',
      'operation-not-allowed' => 'Cadastro por e-mail não habilitado.',
      'network-request-failed' => 'Sem conexão com a internet.',
      _ => 'Erro ao criar conta. Tente novamente.',
    };
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
