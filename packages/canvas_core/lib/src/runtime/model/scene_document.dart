// Path: oss_packages/canvas_core/lib/src/runtime/model/scene_document.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/serialization/serializers.dart';

part 'scene_document.freezed.dart';
part 'scene_document.g.dart';

@freezed
abstract class CanvasSceneDocument with _$CanvasSceneDocument {
  const CanvasSceneDocument._();

  const factory CanvasSceneDocument({
    @Size2DConverter() @Default(Size2D(740, 360)) Size2D artboardSize,

    @LinearGradientSpecConverter()
    @Default(LinearGradientSpec.transparent)
    LinearGradientSpec bgGradient,

    @Default(0.0) double bgOpacity,

    @Default(<Node>[]) List<Node> children,
  }) = _CanvasSceneDocument;

  factory CanvasSceneDocument.fromJson(Map<String, dynamic> json) =>
      _$CanvasSceneDocumentFromJson(json);
}
