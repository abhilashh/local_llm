import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/ollama_datasource.dart';
import '../../data/providers/prop_snap_providers.dart';
import '../../domain/entities/listing_result_entity.dart';
import '../../domain/usecases/generate_listing_usecase.dart';
import '../../../settings/presentation/providers/settings_notifier.dart';

sealed class PropSnapState { const PropSnapState(); }
class PropSnapInitial extends PropSnapState { const PropSnapInitial(); }
class PropSnapLoading extends PropSnapState { const PropSnapLoading(); }
class PropSnapSuccess extends PropSnapState {
  final Map<ListingType, ListingResultEntity> results;
  const PropSnapSuccess(this.results);
}
class PropSnapError extends PropSnapState {
  final String message;
  const PropSnapError(this.message);
}

class PropSnapNotifier extends Notifier<PropSnapState> {
  final List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => List.unmodifiable(_selectedImages);

  String _textDescription = '';
  String get textDescription => _textDescription;

  @override
  PropSnapState build() => const PropSnapInitial();

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 5);
    if (picked.isNotEmpty) {
      _selectedImages
        ..clear()
        ..addAll(picked);
      state = const PropSnapInitial();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    state = const PropSnapInitial();
  }

  void setTextDescription(String value) {
    _textDescription = value;
  }

  void clearResult() {
    _textDescription = '';
    _selectedImages.clear();
    state = const PropSnapInitial();
  }

  Future<void> generateListing() async {
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    if (settings == null) {
      state = const PropSnapError('Settings not loaded. Please try again.');
      return;
    }

    final isOnDevice = settings.inferenceMode == InferenceMode.onDevice;

    if (isOnDevice) {
      if (_textDescription.trim().isEmpty) {
        state = const PropSnapError('Please enter a property description.');
        return;
      }
      if (settings.modelStatus != ModelStatus.ready) {
        state = const PropSnapError('Model not downloaded yet. Go to Settings to download it.');
        return;
      }
    } else {
      if (_selectedImages.isEmpty) {
        state = const PropSnapError('Please select at least one photo.');
        return;
      }
    }

    state = const PropSnapLoading();

    List<String> base64Images = [];
    if (!isOnDevice) {
      base64Images = await Future.wait(
        _selectedImages.map((f) async {
          final bytes = await File(f.path).readAsBytes();
          return base64Encode(bytes);
        }),
      );
    }

    final useCase = ref.read(generateListingUseCaseProvider);

    final typesToGenerate = isOnDevice ? [ListingType.listing] : ListingType.values;

    final futures = typesToGenerate.map((type) => useCase(GenerateListingParams(
          type: type,
          base64Images: base64Images,
          textDescription: isOnDevice ? _textDescription : null,
        )));

    final responses = await Future.wait(futures);

    final results = <ListingType, ListingResultEntity>{};
    String? error;

    final typeList = typesToGenerate.toList();
    for (final (i, result) in responses.indexed) {
      result.fold(
        (failure) => error ??= failure.message,
        (entity) => results[typeList[i]] = entity,
      );
    }

    if (results.isEmpty) {
      state = PropSnapError(error ?? 'Generation failed');
    } else {
      state = PropSnapSuccess(results);
    }
  }
}

final propSnapNotifierProvider = NotifierProvider<PropSnapNotifier, PropSnapState>(
  PropSnapNotifier.new,
);
