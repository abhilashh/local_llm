import 'package:shared_preferences/shared_preferences.dart';

enum InferenceMode { remote, onDevice }

abstract interface class SettingsLocalDataSource {
  Future<String> getOllamaUrl();
  Future<void> setOllamaUrl(String url);
  Future<String> getOllamaModel();
  Future<void> setOllamaModel(String model);
  Future<InferenceMode> getInferenceMode();
  Future<void> setInferenceMode(InferenceMode mode);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _keyOllamaUrl = 'ollama_url';
  static const _keyOllamaModel = 'ollama_model';
  static const _keyInferenceMode = 'inference_mode';
  static const _defaultUrl = 'http://192.168.1.1:11434';
  static const _defaultModel = 'moondream';

  @override
  Future<String> getOllamaUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOllamaUrl) ?? _defaultUrl;
  }

  @override
  Future<void> setOllamaUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOllamaUrl, url);
  }

  @override
  Future<String> getOllamaModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOllamaModel) ?? _defaultModel;
  }

  @override
  Future<void> setOllamaModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOllamaModel, model);
  }

  @override
  Future<InferenceMode> getInferenceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyInferenceMode);
    return value == 'onDevice' ? InferenceMode.onDevice : InferenceMode.remote;
  }

  @override
  Future<void> setInferenceMode(InferenceMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyInferenceMode,
      mode == InferenceMode.onDevice ? 'onDevice' : 'remote',
    );
  }
}
