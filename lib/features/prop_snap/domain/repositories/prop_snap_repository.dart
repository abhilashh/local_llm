import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/ollama_datasource.dart';
import '../entities/listing_result_entity.dart';

abstract interface class PropSnapRepository {
  Future<Either<Failure, ListingResultEntity>> generateListing({
    required ListingType type,
    List<String> base64Images,
    String? textDescription,
  });
}
