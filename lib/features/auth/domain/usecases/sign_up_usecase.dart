import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/validators/input_validator.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    return InputValidator.email(params.email)
        .flatMap((validEmail) => InputValidator.password(params.password).map((_) => validEmail))
        .flatMap((validEmail) => InputValidator.username(params.username).map((validUsername) => (validEmail, validUsername)))
        .fold(
          (failure) async => left(failure),
          (validated) => _repository.signUpWithEmail(email: validated.$1, password: params.password, username: validated.$2),
        );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String username;
  const SignUpParams({required this.email, required this.password, required this.username});
  @override
  List<Object> get props => [email, password, username];
}
