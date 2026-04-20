import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthState { const AuthState(); }
class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _checkCurrentUser();
    return const AuthInitial();
  }

  Future<void> _checkCurrentUser() async {
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = const AuthUnauthenticated(),
      (user) => state = user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await _repository.signInWithEmail(email: email, password: password);
    result.fold((failure) => state = AuthError(failure.message), (user) => state = AuthAuthenticated(user));
  }

  Future<void> signUp({required String email, required String password, required String username}) async {
    state = const AuthLoading();
    final result = await _repository.signUpWithEmail(email: email, password: password, username: username);
    result.fold((failure) => state = AuthError(failure.message), (user) => state = AuthAuthenticated(user));
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    final result = await _repository.signOut();
    result.fold((failure) => state = AuthError(failure.message), (_) => state = const AuthUnauthenticated());
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
