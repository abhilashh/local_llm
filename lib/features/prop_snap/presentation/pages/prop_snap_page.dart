import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/ollama_datasource.dart';
import '../providers/prop_snap_notifier.dart';
import '../../../settings/presentation/providers/settings_notifier.dart';

const _tabs = [
  (type: ListingType.listing, label: 'Listing', icon: Icons.home_outlined),
  (type: ListingType.social, label: 'Social', icon: Icons.share_outlined),
  (type: ListingType.airbnb, label: 'Airbnb', icon: Icons.apartment_outlined),
  (type: ListingType.faq, label: 'FAQ', icon: Icons.quiz_outlined),
];

class PropSnapPage extends ConsumerWidget {
  const PropSnapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propSnapNotifierProvider);
    final notifier = ref.read(propSnapNotifierProvider.notifier);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final isOnDevice = settingsAsync.valueOrNull?.inferenceMode == InferenceMode.onDevice;
    final hasResults = state is PropSnapSuccess;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PropSnap'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
          bottom: hasResults
              ? TabBar(
                  tabs: _tabs.map((t) => Tab(icon: Icon(t.icon), text: t.label)).toList(),
                )
              : null,
        ),
        body: hasResults
            ? TabBarView(
                children: _tabs.map((t) {
                  final result = (state).results[t.type];
                  return result == null
                      ? const Center(child: Text('No result for this tab'))
                      : _ResultTab(result: result.description);
                }).toList(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isOnDevice)
                      _TextInputSection(notifier: notifier)
                    else
                      _PhotoPickerSection(
                        images: notifier.selectedImages,
                        notifier: notifier,
                      ),
                    const SizedBox(height: 16),
                    if (isOnDevice)
                      _OnDeviceBadge(settingsAsync: settingsAsync),
                    const SizedBox(height: 8),
                    if (state is PropSnapError) _ErrorBanner(message: state.message),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: state is PropSnapLoading ? null : notifier.generateListing,
                      icon: state is PropSnapLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(state is PropSnapLoading ? 'Generating…' : 'Generate All'),
                    ),
                    if (state is PropSnapLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          isOnDevice
                              ? 'Running on-device — this may take a few minutes…'
                              : 'Running 4 prompts in parallel…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButton: hasResults
            ? FloatingActionButton.extended(
                onPressed: notifier.clearResult,
                icon: const Icon(Icons.refresh),
                label: const Text('New'),
              )
            : null,
      ),
    );
  }
}

class _TextInputSection extends StatefulWidget {
  final PropSnapNotifier notifier;
  const _TextInputSection({required this.notifier});

  @override
  State<_TextInputSection> createState() => _TextInputSectionState();
}

class _TextInputSectionState extends State<_TextInputSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Description', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Describe the property — rooms, features, condition, location, size.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                'e.g. 3 bed 2 bath house, open-plan kitchen, hardwood floors, large backyard, recently renovated bathrooms, quiet street near schools',
            border: OutlineInputBorder(),
          ),
          onChanged: widget.notifier.setTextDescription,
        ),
      ],
    );
  }
}

class _OnDeviceBadge extends StatelessWidget {
  final AsyncValue<SettingsState> settingsAsync;
  const _OnDeviceBadge({required this.settingsAsync});

  @override
  Widget build(BuildContext context) {
    final status = settingsAsync.valueOrNull?.modelStatus;
    final isReady = status == ModelStatus.ready;
    return Row(
      children: [
        Icon(
          isReady ? Icons.offline_bolt : Icons.warning_amber_outlined,
          size: 16,
          color: isReady
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 6),
        Text(
          isReady ? 'On-device model ready' : 'Model not downloaded — go to Settings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isReady
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
        ),
      ],
    );
  }
}

class _PhotoPickerSection extends ConsumerWidget {
  final List images;
  final PropSnapNotifier notifier;
  const _PhotoPickerSection({required this.images, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos (${images.length}/5)', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: images.length < 5 ? notifier.pickImages : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          GestureDetector(
            onTap: notifier.pickImages,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: 8),
                    Text('Tap to select property photos',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(images[i].path),
                        width: 120, height: 120, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => notifier.removeImage(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultTab extends StatelessWidget {
  final String result;
  const _ResultTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(result, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
