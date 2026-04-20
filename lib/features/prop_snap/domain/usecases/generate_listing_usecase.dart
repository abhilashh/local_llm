import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/ollama_datasource.dart';
import '../entities/listing_result_entity.dart';
import '../repositories/prop_snap_repository.dart';

class GenerateListingUseCase implements UseCase<ListingResultEntity, GenerateListingParams> {
  final PropSnapRepository _repository;
  const GenerateListingUseCase(this._repository);

  @override
  Future<Either<Failure, ListingResultEntity>> call(GenerateListingParams params) {
    final hasImages = params.base64Images.isNotEmpty;
    final hasText = params.textDescription?.trim().isNotEmpty ?? false;

    if (!hasImages && !hasText) {
      return Future.value(
        left(const ServerFailure('Please select photos or enter a property description')),
      );
    }

    return _repository.generateListing(
      type: params.type,
      base64Images: params.base64Images,
      textDescription: params.textDescription,
    );
  }
}

class GenerateListingParams extends Equatable {
  final ListingType type;
  final List<String> base64Images;
  final String? textDescription;

  const GenerateListingParams({
    required this.type,
    this.base64Images = const [],
    this.textDescription,
  });

  @override
  List<Object?> get props => [type, base64Images, textDescription];
}
