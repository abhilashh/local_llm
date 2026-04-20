import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/model_constants.dart';
import '../../data/datasources/settings_local_datasource.dart';

export '../../data/datasources/settings_local_datasource.dart' show InferenceMode;

enum ModelStatus { notDownloaded, downloading, ready }

class SettingsState {
  final String ollamaUrl;
  final String ollamaModel;
  final InferenceMode inferenceMode;
  final ModelStatus modelStatus;
  final double downloadProgress;

  const SettingsState({
    required this.ollamaUrl,
    required this.ollamaModel,
    required this.inferenceMode,
    this.modelStatus = ModelStatus.notDownloaded,
    this.downloadProgress = 0,
  });

  SettingsState copyWith({
    String? ollamaUrl,
    String? ollamaModel,
    InferenceMode? inferenceMode,
    ModelStatus? modelStatus,
    double? downloadProgress,
  }) =>
      SettingsState(
        ollamaUrl: ollamaUrl ?? this.ollamaUrl,
        ollamaModel: ollamaModel ?? this.ollamaModel,
        inferenceMode: inferenceMode ?? this.inferenceMode,
        modelStatus: modelStatus ?? this.modelStatus,
        downloadProgress: downloadProgress ?? this.downloadProgress,
      );
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late final SettingsLocalDataSource _dataSource;

  @override
  Future<SettingsState> build() async {
    _dataSource = ref.read(settingsLocalDataSourceProvider);
    final url = await _dataSource.getOllamaUrl();
    final model = await _dataSource.getOllamaModel();
    final mode = await _dataSource.getInferenceMode();
    final status = await _checkModelStatus();
    return SettingsState(
      ollamaUrl: url,
      ollamaModel: model,
      inferenceMode: mode,
      modelStatus: status,
    );
  }

  Future<ModelStatus> _checkModelStatus() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/${ModelConstants.modelFileName}');
      return await modelFile.exists() ? ModelStatus.ready : ModelStatus.notDownloaded;
    } catch (_) {
      return ModelStatus.notDownloaded;
    }
  }

  Future<void> setOllamaUrl(String url) async {
    await _dataSource.setOllamaUrl(url);
    state = state.whenData((s) => s.copyWith(ollamaUrl: url));
  }

  Future<void> setOllamaModel(String model) async {
    await _dataSource.setOllamaModel(model);
    state = state.whenData((s) => s.copyWith(ollamaModel: model));
  }

  Future<void> setInferenceMode(InferenceMode mode) async {
    await _dataSource.setInferenceMode(mode);
    state = state.whenData((s) => s.copyWith(inferenceMode: mode));
  }

  Future<void> downloadModel() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(
      modelStatus: ModelStatus.downloading,
      downloadProgress: 0,
    ));

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dio = Dio();

      await dio.download(
        ModelConstants.modelDownloadUrl,
        '${dir.path}/${ModelConstants.modelFileName}',
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = AsyncData(
              state.valueOrNull!.copyWith(downloadProgress: received / total),
            );
          }
        },
      );

      state = AsyncData(state.valueOrNull!.copyWith(
        modelStatus: ModelStatus.ready,
        downloadProgress: 1,
      ));
    } catch (e) {
      state = AsyncData(state.valueOrNull!.copyWith(
        modelStatus: ModelStatus.notDownloaded,
        downloadProgress: 0,
      ));
      rethrow;
    }
  }
}

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (_) => SettingsLocalDataSourceImpl(),
);

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
