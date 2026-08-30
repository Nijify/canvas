import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_proxy_client.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UnsplashPhotoSelected = void Function(UnsplashPhoto photo);

Future<CanvasAssetLibraryItem?> presentExampleAssetSelection({
  required BuildContext context,
  required CanvasAssetLibrary library,
  required UnsplashProxyClient? unsplashClient,
  required UnsplashPhotoSelected onUnsplashSelected,
}) {
  return showDialog<CanvasAssetLibraryItem>(
    context: context,
    builder: (dialogContext) => _ExampleAssetSelectionDialog(
      library: library,
      unsplashClient: unsplashClient,
      onUnsplashSelected: onUnsplashSelected,
    ),
  );
}

class UnsplashCreditBar extends StatelessWidget {
  const UnsplashCreditBar({super.key, required this.creditsBySourceRef});

  final Map<String, UnsplashCredit> creditsBySourceRef;

  @override
  Widget build(BuildContext context) {
    if (creditsBySourceRef.isEmpty) {
      return const SizedBox.shrink();
    }

    final credits = creditsBySourceRef.values.toList(growable: false)
      ..sort((a, b) => a.photographerName.compareTo(b.photographerName));

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.photo_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final credit in credits)
                      _Attribution(credit: credit, compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AssetSource { demo, unsplash }

final class _ExampleAssetSelectionDialog extends StatefulWidget {
  const _ExampleAssetSelectionDialog({
    required this.library,
    required this.unsplashClient,
    required this.onUnsplashSelected,
  });

  final CanvasAssetLibrary library;
  final UnsplashProxyClient? unsplashClient;
  final UnsplashPhotoSelected onUnsplashSelected;

  @override
  State<_ExampleAssetSelectionDialog> createState() =>
      _ExampleAssetSelectionDialogState();
}

final class _ExampleAssetSelectionDialogState
    extends State<_ExampleAssetSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();

  _AssetSource _source = _AssetSource.demo;
  List<UnsplashPhoto> _results = const <UnsplashPhoto>[];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assets'),
      content: SizedBox(
        width: 560,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<_AssetSource>(
                segments: const [
                  ButtonSegment(
                    value: _AssetSource.demo,
                    label: Text('Demo'),
                    icon: Icon(Icons.collections_outlined),
                  ),
                  ButtonSegment(
                    value: _AssetSource.unsplash,
                    label: Text('Unsplash'),
                    icon: Icon(Icons.photo_library_outlined),
                  ),
                ],
                selected: <_AssetSource>{_source},
                onSelectionChanged: (selection) {
                  setState(() {
                    _source = selection.single;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_source) {
                _AssetSource.demo => _buildDemoAssets(),
                _AssetSource.unsplash => _buildUnsplash(),
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildDemoAssets() {
    return ListView.separated(
      itemCount: widget.library.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = widget.library.items[index];

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              _assetPathFromRef(item.thumbnailRef),
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.image_outlined),
                );
              },
            ),
          ),
          title: Text(item.label),
          subtitle: Text(item.category),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }

  Widget _buildUnsplash() {
    final client = widget.unsplashClient;
    if (client == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Unsplash search is not configured. Build the example with '
            '--dart-define=UNSPLASH_PROXY_BASE_URL=https://your-proxy.example/.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Search Unsplash',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(client),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading ? null : () => _search(client),
              child: const Text('Search'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text(
                    _loading ? 'Searching…' : 'Search for a photo to add.',
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final photo = _results[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo.thumbnailUrl.toString(),
                          width: 72,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 72,
                            height: 56,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      title: Text(
                        photo.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _Attribution(credit: photo.credit),
                      onTap: () {
                        widget.onUnsplashSelected(photo);
                        Navigator.of(context).pop(photo.toAssetLibraryItem());
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _search(UnsplashProxyClient client) async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await client.search(query);
      if (!mounted) return;

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _results = const <UnsplashPhoto>[];
        _loading = false;
        _error = 'Unable to search Unsplash. Please try again.';
      });
    }
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.credit, this.compact = false});

  final UnsplashCredit credit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: style,
    );

    return Wrap(
      spacing: compact ? 1 : 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Photo by', style: style),
        TextButton(
          style: buttonStyle,
          onPressed: () => _openUrl(context, credit.attributedPhotographerUrl),
          child: Text(credit.photographerName),
        ),
        Text('on', style: style),
        TextButton(
          style: buttonStyle,
          onPressed: () => _openUrl(context, attributedUnsplashUrl),
          child: const Text('Unsplash'),
        ),
      ],
    );
  }
}

Future<void> _openUrl(BuildContext context, Uri uri) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
  } catch (_) {
    if (!context.mounted) return;
  }

  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('Unable to open link.')));
}

String _assetPathFromRef(String ref) {
  final trimmed = ref.trim();
  const prefix = 'asset:';

  if (trimmed.startsWith(prefix)) {
    return trimmed.substring(prefix.length).trim();
  }

  return trimmed;
}
