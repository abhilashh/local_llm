import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_notifier.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;
  bool _initialised = false;

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveRemote() {
    ref.read(settingsNotifierProvider.notifier).setOllamaUrl(_urlController.text.trim());
    ref.read(settingsNotifierProvider.notifier).setOllamaModel(_modelController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (settings) {
        if (!_initialised) {
          _urlController = TextEditingController(text: settings.ollamaUrl);
          _modelController = TextEditingController(text: settings.ollamaModel);
          _initialised = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Inference Mode ──────────────────────────────────────
              Text('Inference Mode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<InferenceMode>(
                segments: const [
                  ButtonSegment(
                    value: InferenceMode.remote,
                    label: Text('Remote (Ollama)'),
                    icon: Icon(Icons.cloud_outlined),
                  ),
                  ButtonSegment(
                    value: InferenceMode.onDevice,
                    label: Text('On-device'),
                    icon: Icon(Icons.phone_android),
                  ),
                ],
                selected: {settings.inferenceMode},
                onSelectionChanged: (s) =>
                    ref.read(settingsNotifierProvider.notifier).setInferenceMode(s.first),
              ),

              const SizedBox(height: 24),

              // ── Remote section ──────────────────────────────────────
              if (settings.inferenceMode == InferenceMode.remote) ...[
                Text('Ollama Server', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Ollama URL',
                    hintText: 'http://192.168.1.x:11434',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'moondream or phi3.5-vision',
                    border: OutlineInputBorder(),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 4),
                Text(
                  'Run: OLLAMA_HOST=0.0.0.0 ollama serve',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _saveRemote, child: const Text('Save')),
                ),
              ],

              // ── On-device section ───────────────────────────────────
              if (settings.inferenceMode == InferenceMode.onDevice) ...[
                Text('On-device Model', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Downloads Qwen 2.5 1.5B (~1.6 GB). Runs fully offline — no photos, text description only.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _ModelDownloadSection(settings: settings),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ModelDownloadSection extends ConsumerWidget {
  final SettingsState settings;
  const _ModelDownloadSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (settings.modelStatus) {
      ModelStatus.ready => _readyTile(context),
      ModelStatus.downloading => _downloadingTile(context, settings.downloadProgress),
      ModelStatus.notDownloaded => _downloadButton(context, ref),
    };
  }

  Widget _readyTile(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
        title: const Text('Model ready'),
        subtitle: const Text('Qwen 2.5 1.5B is installed'),
      );

  Widget _downloadingTile(BuildContext context, double progress) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Downloading… ${(progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            'Keep the app open. ~1.6 GB total.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

  Widget _downloadButton(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Model (~1.6 GB)'),
            onPressed: () async {
              try {
                await ref.read(settingsNotifierProvider.notifier).downloadModel();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Requires Wi-Fi. Model files are stored on your device.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}
