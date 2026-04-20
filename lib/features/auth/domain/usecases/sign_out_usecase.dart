import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}
