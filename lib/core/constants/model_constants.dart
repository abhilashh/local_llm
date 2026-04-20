class ModelConstants {
  ModelConstants._();

  // Qwen 2.5 1.5B Instruct — MediaPipe .task format (~1.6 GB, single file, no auth required)
  // Public repo: https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct
  static const String modelDownloadUrl =
      'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task';

  static const String modelFileName = 'Qwen2.5-1.5B-Instruct_q8.task';

  // No mmproj needed — flutter_gemma uses a single .task file
}
