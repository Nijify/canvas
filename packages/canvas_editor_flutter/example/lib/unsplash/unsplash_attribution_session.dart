import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';

final class UnsplashAttributionSession {
  final Map<String, UnsplashCredit> _knownBySourceRef =
      <String, UnsplashCredit>{};

  void register(UnsplashPhoto photo) {
    _knownBySourceRef[photo.sourceRef] = photo.credit;
  }

  Map<String, UnsplashCredit> visibleCreditsForScene(
    CanvasSceneDocument scene,
  ) {
    final visible = <String, UnsplashCredit>{};

    visitSceneNodes(
      scene,
      visit: (node) {
        if (node is! ImageNode) return;

        final assetId = node.data.assetId;
        if (assetId == null) return;

        final sourceRef = scene.assets[assetId]?.sourceRef;
        if (sourceRef == null) return;

        final credit = _knownBySourceRef[sourceRef];
        if (credit != null) {
          visible[sourceRef] = credit;
        }
      },
    );

    return Map<String, UnsplashCredit>.unmodifiable(visible);
  }
}
