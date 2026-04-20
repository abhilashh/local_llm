import 'package:fpdart/fpdart.dart';
import '../constants/supabase_constants.dart';
import '../errors/failures.dart';

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

abstract final class InputValidator {
  static Either<ValidationFailure, String> email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return left(const ValidationFailure('Email is required'));
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) return left(const ValidationFailure('Enter a valid email address'));
    if (trimmed.length > 254) return left(const ValidationFailure('Email address is too long'));
    return right(trimmed);
  }

  static Either<ValidationFailure, String> password(String value) {
    if (value.isEmpty) return left(const ValidationFailure('Password is required'));
    if (value.length < SupabaseConstants.minPasswordLength) {
      return left(ValidationFailure('Password must be at least ${SupabaseConstants.minPasswordLength} characters'));
    }
    if (value.length > 72) return left(const ValidationFailure('Password is too long'));
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    if (!hasUppercase || !hasDigit || !hasSpecial) {
      return left(const ValidationFailure('Password must include an uppercase letter, a number, and a special character'));
    }
    return right(value);
  }

  static Either<ValidationFailure, String> username(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return left(const ValidationFailure('Username is required'));
    if (trimmed.length < 3) return left(const ValidationFailure('Username must be at least 3 characters'));
    if (trimmed.length > SupabaseConstants.maxUsernameLength) {
      return left(ValidationFailure('Username must be at most ${SupabaseConstants.maxUsernameLength} characters'));
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_]*[a-zA-Z0-9]$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return left(const ValidationFailure('Username may only contain letters, numbers, and underscores, and must not start or end with an underscore'));
    }
    return right(trimmed);
  }

  static Either<ValidationFailure, String> messageContent(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return left(const ValidationFailure('Message cannot be empty'));
    if (trimmed.length > SupabaseConstants.maxMessageLength) {
      return left(ValidationFailure('Message must be at most ${SupabaseConstants.maxMessageLength} characters'));
    }
    return right(trimmed);
  }
}
