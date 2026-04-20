import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<UserModel> signUpWithEmail({required String email, required String password, required String username});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  const AuthRemoteDataSourceImpl(this._supabase);

  AppAuthException _sanitiseAuthError(Object e) {
    if (e is AuthApiException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('over_email_send_rate_limit') || msg.contains('email rate limit')) {
        return const AppAuthException('Too many sign-up attempts. Please wait a few minutes before trying again');
      }
      if (msg.contains('user already registered') || msg.contains('already been registered')) {
        return const AppAuthException('An account with this email already exists');
      }
      if (msg.contains('invalid login credentials') || msg.contains('invalid email or password')) {
        return const AppAuthException('Invalid email or password');
      }
      return switch (e.statusCode) {
        '400' => const AppAuthException('Invalid email or password'),
        '422' => const AppAuthException('Email address is already in use'),
        '429' => const AppAuthException('Too many attempts. Please wait a few minutes and try again'),
        _ => const AppAuthException('Authentication failed. Please try again'),
      };
    }
    return const AppAuthException('Something went wrong. Please try again');
  }

  @override
  Future<UserModel> signInWithEmail({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) throw const AppAuthException('Sign in failed');
      return UserModel(id: user.id, email: user.email ?? email);
    } on AppAuthException {
      rethrow;
    } catch (e) {
      throw _sanitiseAuthError(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail({required String email, required String password, required String username}) async {
    try {
      final response = await _supabase.auth.signUp(email: email, password: password, data: {'username': username});
      final user = response.user;
      if (user == null) throw const AppAuthException('Sign up failed');
      await _supabase.from(SupabaseConstants.profilesTable).upsert({'id': user.id, 'email': email, 'username': username});
      return UserModel(id: user.id, email: email, username: username);
    } on AppAuthException {
      rethrow;
    } catch (e) {
      throw _sanitiseAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final profile = await _supabase.from(SupabaseConstants.profilesTable).select().eq('id', user.id).maybeSingle();
      return UserModel(id: user.id, email: user.email ?? '', username: profile?['username'] as String?, avatarUrl: profile?['avatar_url'] as String?);
    } catch (_) {
      return null;
    }
  }
}
