// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
Node _$NodeFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'text':
          return TextNode.fromJson(
            json
          );
                case 'image':
          return ImageNode.fromJson(
            json
          );
                case 'path':
          return PathNode.fromJson(
            json
          );
                case 'icon':
          return IconNode.fromJson(
            json
          );
                case 'group':
          return GroupNode.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'Node',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$Node {

 ElementId get id;@JsonKey(includeIfNull: false) String? get name;@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D get xf;
/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeCopyWith<Node> get copyWith => _$NodeCopyWithImpl<Node>(this as Node, _$identity);

  /// Serializes this Node to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Node;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Node&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.xf, _this.xf) || other.xf == _this.xf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Node;
  return Object.hash(runtimeType,_this.id,_this.name,_this.xf);
}

@override
String toString() {
  final _this = this as Node;
  return 'Node(id: ${_this.id}, name: ${_this.name}, xf: ${_this.xf})';
}


}

/// @nodoc
abstract mixin class $NodeCopyWith<$Res>  {
  factory $NodeCopyWith(Node value, $Res Function(Node) _then) = _$NodeCopyWithImpl;
@useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf
});




}
/// @nodoc
class _$NodeCopyWithImpl<$Res>
    implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._self, this._then);

  final Node _self;
  final $Res Function(Node) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? xf = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,
  ));
}

}


/// Adds pattern-matching-related methods to [Node].
extension NodePatterns on Node {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextNode value)?  text,TResult Function( ImageNode value)?  image,TResult Function( PathNode value)?  path,TResult Function( IconNode value)?  icon,TResult Function( GroupNode value)?  group,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that);case ImageNode() when image != null:
return image(_that);case PathNode() when path != null:
return path(_that);case IconNode() when icon != null:
return icon(_that);case GroupNode() when group != null:
return group(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextNode value)  text,required TResult Function( ImageNode value)  image,required TResult Function( PathNode value)  path,required TResult Function( IconNode value)  icon,required TResult Function( GroupNode value)  group,}){
final _that = this;
switch (_that) {
case TextNode():
return text(_that);case ImageNode():
return image(_that);case PathNode():
return path(_that);case IconNode():
return icon(_that);case GroupNode():
return group(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextNode value)?  text,TResult? Function( ImageNode value)?  image,TResult? Function( PathNode value)?  path,TResult? Function( IconNode value)?  icon,TResult? Function( GroupNode value)?  group,}){
final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that);case ImageNode() when image != null:
return image(_that);case PathNode() when path != null:
return path(_that);case IconNode() when icon != null:
return icon(_that);case GroupNode() when group != null:
return group(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance)?  text,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align)?  image,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance)?  path,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance)?  icon,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  List<Node> children)?  group,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.xf,_that.assetId,_that.size,_that.fit,_that.align);case PathNode() when path != null:
return path(_that.id,_that.name,_that.xf,_that.geometry,_that.fillRule,_that.appearance);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.xf,_that.iconRef,_that.sizePx,_that.appearance);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.xf,_that.children);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance)  text,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align)  image,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance)  path,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance)  icon,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  List<Node> children)  group,}) {final _that = this;
switch (_that) {
case TextNode():
return text(_that.id,_that.name,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance);case ImageNode():
return image(_that.id,_that.name,_that.xf,_that.assetId,_that.size,_that.fit,_that.align);case PathNode():
return path(_that.id,_that.name,_that.xf,_that.geometry,_that.fillRule,_that.appearance);case IconNode():
return icon(_that.id,_that.name,_that.xf,_that.iconRef,_that.sizePx,_that.appearance);case GroupNode():
return group(_that.id,_that.name,_that.xf,_that.children);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance)?  text,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align)?  image,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance)?  path,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance)?  icon,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  List<Node> children)?  group,}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.xf,_that.assetId,_that.size,_that.fit,_that.align);case PathNode() when path != null:
return path(_that.id,_that.name,_that.xf,_that.geometry,_that.fillRule,_that.appearance);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.xf,_that.iconRef,_that.sizePx,_that.appearance);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.xf,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextNode extends Node {
  const TextNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), required this.text, required this.fontFamily, required this.fontWeight, required this.fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false) this.letterSpacing = 0.0, this.appearance = const CanvasAppearance(),  String? $type}): $type = $type ?? 'text',super._();
  factory TextNode.fromJson(Map<String, dynamic> json) => _$TextNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
 final  String text;
 final  String fontFamily;
 final  FontWeightNum fontWeight;
 final  double fontSize;
/// Additional spacing between characters in logical canvas units.
///
/// The original text must remain unchanged. Platform text implementations
/// must apply this value through their native text-layout API.
@JsonKey(toJson: _letterSpacingToJson, includeIfNull: false) final  double letterSpacing;
/// Source-derived visual appearance.
///
/// Layout and interaction geometry remain source-derived and do not expand
/// for source underlays.
@JsonKey() final  CanvasAppearance appearance;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextNodeCopyWith<TextNode> get copyWith => _$TextNodeCopyWithImpl<TextNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TextNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.text, text) || other.text == text)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,xf,text,fontFamily,fontWeight,fontSize,letterSpacing,appearance);
}

@override
String toString() {
    return 'Node.text(id: $id, name: $name, xf: $xf, text: $text, fontFamily: $fontFamily, fontWeight: $fontWeight, fontSize: $fontSize, letterSpacing: $letterSpacing, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class $TextNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $TextNodeCopyWith(TextNode value, $Res Function(TextNode) _then) = _$TextNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf, String text, String fontFamily, FontWeightNum fontWeight, double fontSize,@JsonKey(toJson: _letterSpacingToJson, includeIfNull: false) double letterSpacing, CanvasAppearance appearance
});


$CanvasAppearanceCopyWith<$Res> get appearance;

}
/// @nodoc
class _$TextNodeCopyWithImpl<$Res>
    implements $TextNodeCopyWith<$Res> {
  _$TextNodeCopyWithImpl(this._self, this._then);

  final TextNode _self;
  final $Res Function(TextNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? xf = null,Object? text = null,Object? fontFamily = null,Object? fontWeight = null,Object? fontSize = null,Object? letterSpacing = null,Object? appearance = null,}) {
  return _then(TextNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as FontWeightNum,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAppearanceCopyWith<$Res> get appearance {
  
  return $CanvasAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ImageNode extends Node {
  const ImageNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), @JsonKey(includeIfNull: false) this.assetId, @Size2DConverter() required this.size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false) this.fit = ImageFit.contain, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) this.align = const Vec2(0.5, 0.5),  String? $type}): $type = $type ?? 'image',super._();
  factory ImageNode.fromJson(Map<String, dynamic> json) => _$ImageNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
/// Null represents an intentionally unfilled image frame.
@JsonKey(includeIfNull: false) final  CanvasAssetId? assetId;
/// Editable destination-frame dimensions in document units.
@Size2DConverter() final  Size2D size;
@JsonKey(toJson: _imageFitToJson, includeIfNull: false) final  ImageFit fit;
@JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) final  Vec2 align;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageNodeCopyWith<ImageNode> get copyWith => _$ImageNodeCopyWithImpl<ImageNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.size, size) || other.size == size)&&(identical(other.fit, fit) || other.fit == fit)&&(identical(other.align, align) || other.align == align));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,xf,assetId,size,fit,align);
}

@override
String toString() {
    return 'Node.image(id: $id, name: $name, xf: $xf, assetId: $assetId, size: $size, fit: $fit, align: $align)';
}


}

/// @nodoc
abstract mixin class $ImageNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $ImageNodeCopyWith(ImageNode value, $Res Function(ImageNode) _then) = _$ImageNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf,@JsonKey(includeIfNull: false) CanvasAssetId? assetId,@Size2DConverter() Size2D size,@JsonKey(toJson: _imageFitToJson, includeIfNull: false) ImageFit fit,@JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) Vec2 align
});




}
/// @nodoc
class _$ImageNodeCopyWithImpl<$Res>
    implements $ImageNodeCopyWith<$Res> {
  _$ImageNodeCopyWithImpl(this._self, this._then);

  final ImageNode _self;
  final $Res Function(ImageNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? xf = null,Object? assetId = freezed,Object? size = null,Object? fit = null,Object? align = null,}) {
  return _then(ImageNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as CanvasAssetId?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Size2D,fit: null == fit ? _self.fit : fit // ignore: cast_nullable_to_non_nullable
as ImageFit,align: null == align ? _self.align : align // ignore: cast_nullable_to_non_nullable
as Vec2,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PathNode extends Node {
  const PathNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), @PathSourceConverter() required this.geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false) this.fillRule = FillRule.nonZero, this.appearance = const CanvasAppearance(foreground: CanvasFill.none()),  String? $type}): $type = $type ?? 'path',super._();
  factory PathNode.fromJson(Map<String, dynamic> json) => _$PathNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
/// The sole authored geometry source. Use an explicit empty source for an
/// intentionally empty path.
@PathSourceConverter() final  PathSource geometry;
@JsonKey(toJson: _fillRuleToJson, includeIfNull: false) final  FillRule fillRule;
@JsonKey() final  CanvasAppearance appearance;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathNodeCopyWith<PathNode> get copyWith => _$PathNodeCopyWithImpl<PathNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PathNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.fillRule, fillRule) || other.fillRule == fillRule)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,xf,geometry,fillRule,appearance);
}

@override
String toString() {
    return 'Node.path(id: $id, name: $name, xf: $xf, geometry: $geometry, fillRule: $fillRule, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class $PathNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $PathNodeCopyWith(PathNode value, $Res Function(PathNode) _then) = _$PathNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf,@PathSourceConverter() PathSource geometry,@JsonKey(toJson: _fillRuleToJson, includeIfNull: false) FillRule fillRule, CanvasAppearance appearance
});


$CanvasAppearanceCopyWith<$Res> get appearance;

}
/// @nodoc
class _$PathNodeCopyWithImpl<$Res>
    implements $PathNodeCopyWith<$Res> {
  _$PathNodeCopyWithImpl(this._self, this._then);

  final PathNode _self;
  final $Res Function(PathNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? xf = null,Object? geometry = null,Object? fillRule = null,Object? appearance = null,}) {
  return _then(PathNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,geometry: null == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as PathSource,fillRule: null == fillRule ? _self.fillRule : fillRule // ignore: cast_nullable_to_non_nullable
as FillRule,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAppearanceCopyWith<$Res> get appearance {
  
  return $CanvasAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class IconNode extends Node {
  const IconNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), required this.iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false) this.sizePx = 96.0, this.appearance = const CanvasAppearance(),  String? $type}): $type = $type ?? 'icon',super._();
  factory IconNode.fromJson(Map<String, dynamic> json) => _$IconNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
 final  String iconRef;
@JsonKey(toJson: _iconSizeToJson, includeIfNull: false) final  double sizePx;
@JsonKey() final  CanvasAppearance appearance;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconNodeCopyWith<IconNode> get copyWith => _$IconNodeCopyWithImpl<IconNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IconNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IconNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.sizePx, sizePx) || other.sizePx == sizePx)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,xf,iconRef,sizePx,appearance);
}

@override
String toString() {
    return 'Node.icon(id: $id, name: $name, xf: $xf, iconRef: $iconRef, sizePx: $sizePx, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class $IconNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $IconNodeCopyWith(IconNode value, $Res Function(IconNode) _then) = _$IconNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf, String iconRef,@JsonKey(toJson: _iconSizeToJson, includeIfNull: false) double sizePx, CanvasAppearance appearance
});


$CanvasAppearanceCopyWith<$Res> get appearance;

}
/// @nodoc
class _$IconNodeCopyWithImpl<$Res>
    implements $IconNodeCopyWith<$Res> {
  _$IconNodeCopyWithImpl(this._self, this._then);

  final IconNode _self;
  final $Res Function(IconNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? xf = null,Object? iconRef = null,Object? sizePx = null,Object? appearance = null,}) {
  return _then(IconNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,sizePx: null == sizePx ? _self.sizePx : sizePx // ignore: cast_nullable_to_non_nullable
as double,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAppearanceCopyWith<$Res> get appearance {
  
  return $CanvasAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class GroupNode extends Node {
  const GroupNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(),  List<Node> children = const <Node>[],  String? $type}): _children = children,$type = $type ?? 'group',super._();
  factory GroupNode.fromJson(Map<String, dynamic> json) => _$GroupNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
 final  List<Node> _children;
@JsonKey() List<Node> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupNodeCopyWith<GroupNode> get copyWith => _$GroupNodeCopyWithImpl<GroupNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.xf, xf) || other.xf == xf)&&const DeepCollectionEquality().equals(other.children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,xf,const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return 'Node.group(id: $id, name: $name, xf: $xf, children: $children)';
}


}

/// @nodoc
abstract mixin class $GroupNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $GroupNodeCopyWith(GroupNode value, $Res Function(GroupNode) _then) = _$GroupNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf, List<Node> children
});




}
/// @nodoc
class _$GroupNodeCopyWithImpl<$Res>
    implements $GroupNodeCopyWith<$Res> {
  _$GroupNodeCopyWithImpl(this._self, this._then);

  final GroupNode _self;
  final $Res Function(GroupNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? xf = null,Object? children = null,}) {
  return _then(GroupNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}


}

// dart format on
