import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({required String email, required String password});
  Future<Either<Failure, UserEntity>> signUpWithEmail({required String email, required String password, required String username});
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
