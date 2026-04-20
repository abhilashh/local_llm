import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({required String email, required String password}) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(email: email, password: password);
      return right(user);
    } on AppAuthException catch (e) {
      return left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({required String email, required String password, required String username}) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(email: email, password: password, username: username);
      return right(user);
    } on AppAuthException catch (e) {
      return left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return right(unit);
    } on AppAuthException catch (e) {
      return left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return right(user);
    } on AppAuthException catch (e) {
      return left(AuthFailure(e.message));
    }
  }
}
