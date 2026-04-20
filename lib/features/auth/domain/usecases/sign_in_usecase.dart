import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/validators/input_validator.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) {
    if (params.password.isEmpty) return Future.value(left(const ValidationFailure('Password is required')));
    return InputValidator.email(params.email).fold(
      (failure) async => left(failure),
      (validEmail) => _repository.signInWithEmail(email: validEmail, password: params.password),
    );
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}
