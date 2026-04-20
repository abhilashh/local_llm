import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/listing_result_entity.dart';
import '../../domain/repositories/prop_snap_repository.dart';
import '../datasources/ollama_datasource.dart';

class PropSnapRepositoryImpl implements PropSnapRepository {
  final InferenceDataSource _dataSource;
  const PropSnapRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ListingResultEntity>> generateListing({
    required ListingType type,
    List<String> base64Images = const [],
    String? textDescription,
  }) async {
    try {
      final result = await _dataSource.generateListing(
        type: type,
        base64Images: base64Images,
        textDescription: textDescription,
      );
      return right(result);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }
}
