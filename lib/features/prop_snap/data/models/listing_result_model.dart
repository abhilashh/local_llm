import '../datasources/ollama_datasource.dart';
import '../../domain/entities/listing_result_entity.dart';

class ListingResultModel extends ListingResultEntity {
  const ListingResultModel({
    required super.description,
    required super.generatedAt,
    required super.type,
  });

  factory ListingResultModel.fromOllamaResponse(
    Map<String, dynamic> json,
    ListingType type,
  ) {
    final text = (json['response'] as String? ?? '').trim();
    return ListingResultModel(description: text, generatedAt: DateTime.now(), type: type);
  }
}
