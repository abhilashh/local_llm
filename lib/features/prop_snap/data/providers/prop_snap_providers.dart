import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../datasources/local_inference_datasource.dart';
import '../datasources/ollama_datasource.dart';
import '../repositories/prop_snap_repository_impl.dart';
import '../../domain/repositories/prop_snap_repository.dart';
import '../../domain/usecases/generate_listing_usecase.dart';
import '../../../settings/presentation/providers/settings_notifier.dart';

final _httpClientProvider = Provider<http.Client>((_) => http.Client());

final inferenceDataSourceProvider = Provider<InferenceDataSource>((ref) {
  final settingsAsync = ref.watch(settingsNotifierProvider);
  return settingsAsync.when(
    // Fall back to a no-op Ollama instance while settings load
    loading: () => OllamaDataSourceImpl(
      client: ref.watch(_httpClientProvider),
      ollamaUrl: '',
      model: '',
    ),
    error: (_, __) => OllamaDataSourceImpl(
      client: ref.watch(_httpClientProvider),
      ollamaUrl: '',
      model: '',
    ),
    data: (settings) {
      if (settings.inferenceMode == InferenceMode.onDevice) {
        // Path is resolved lazily inside the datasource — no empty string passed here.
        return const LocalInferenceDataSourceImpl();
      }
      return OllamaDataSourceImpl(
        client: ref.watch(_httpClientProvider),
        ollamaUrl: settings.ollamaUrl,
        model: settings.ollamaModel,
      );
    },
  );
});

final propSnapRepositoryProvider = Provider<PropSnapRepository>(
  (ref) => PropSnapRepositoryImpl(ref.watch(inferenceDataSourceProvider)),
);

final generateListingUseCaseProvider = Provider<GenerateListingUseCase>(
  (ref) => GenerateListingUseCase(ref.watch(propSnapRepositoryProvider)),
);
