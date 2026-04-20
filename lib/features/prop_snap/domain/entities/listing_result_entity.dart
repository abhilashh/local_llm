import 'package:equatable/equatable.dart';
import '../../data/datasources/ollama_datasource.dart';

class ListingResultEntity extends Equatable {
  final String description;
  final DateTime generatedAt;
  final ListingType type;

  const ListingResultEntity({
    required this.description,
    required this.generatedAt,
    required this.type,
  });

  @override
  List<Object> get props => [description, generatedAt, type];
}
