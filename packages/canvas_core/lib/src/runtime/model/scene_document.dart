// Path: lib/src/runtime/model/scene_document.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/ids.dart' show CanvasAssetId;
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/serialization/converters.dart';

part 'scene_document.freezed.dart';
part 'scene_document.g.dart';

/// Logical image source and its stable natural dimensions.
@freezed
abstract class CanvasImageAsset with _$CanvasImageAsset {
  const factory CanvasImageAsset({
    required String sourceRef,
    @JsonKey(required: true, disallowNullValue: true)
    @Size2DConverter()
    required Size2D intrinsicSize,
  }) = _CanvasImageAsset;

  factory CanvasImageAsset.fromJson(Map<String, dynamic> json) =>
      _$CanvasImageAssetFromJson(json);
}

@freezed
abstract class CanvasSceneDocument with _$CanvasSceneDocument {
  const CanvasSceneDocument._();

  const factory CanvasSceneDocument({
    @Size2DConverter() @Default(Size2D(740, 360)) Size2D artboardSize,

    @CanvasFillConverter()
    @JsonKey(required: true, disallowNullValue: true)
    required CanvasFill backgroundFill,

    @JsonKey(required: true, disallowNullValue: true)
    required double backgroundOpacity,

    @JsonKey(toJson: _assetsToJson, includeIfNull: false)
    @Default(<CanvasAssetId, CanvasImageAsset>{})
    Map<CanvasAssetId, CanvasImageAsset> assets,

    @Default(<Node>[]) List<Node> children,
  }) = _CanvasSceneDocument;

  factory CanvasSceneDocument.fromJson(Map<String, dynamic> json) =>
      _$CanvasSceneDocumentFromJson(json);
}

Map<String, dynamic>? _assetsToJson(
  Map<CanvasAssetId, CanvasImageAsset> assets,
) => assets.isEmpty
    ? null
    : assets.map((id, asset) => MapEntry(id, asset.toJson()));
