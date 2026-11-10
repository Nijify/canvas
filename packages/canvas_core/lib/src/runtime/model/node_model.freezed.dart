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

/// @nodoc
mixin _$GroupBehaviorRef {

 String get type; int get version; Map<String, dynamic> get data;
/// Create a copy of GroupBehaviorRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupBehaviorRefCopyWith<GroupBehaviorRef> get copyWith => _$GroupBehaviorRefCopyWithImpl<GroupBehaviorRef>(this as GroupBehaviorRef, _$identity);

  /// Serializes this GroupBehaviorRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupBehaviorRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupBehaviorRef&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.version, _this.version) || other.version == _this.version)&&const DeepCollectionEquality().equals(other.data, _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupBehaviorRef;
  return Object.hash(runtimeType,_this.type,_this.version,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as GroupBehaviorRef;
  return 'GroupBehaviorRef(type: ${_this.type}, version: ${_this.version}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $GroupBehaviorRefCopyWith<$Res>  {
  factory $GroupBehaviorRefCopyWith(GroupBehaviorRef value, $Res Function(GroupBehaviorRef) _then) = _$GroupBehaviorRefCopyWithImpl;
@useResult
$Res call({
 String type, int version, Map<String, dynamic> data
});




}
/// @nodoc
class _$GroupBehaviorRefCopyWithImpl<$Res>
    implements $GroupBehaviorRefCopyWith<$Res> {
  _$GroupBehaviorRefCopyWithImpl(this._self, this._then);

  final GroupBehaviorRef _self;
  final $Res Function(GroupBehaviorRef) _then;

/// Create a copy of GroupBehaviorRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? version = null,Object? data = null,}) {
  return _then(GroupBehaviorRef(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupBehaviorRef].
extension GroupBehaviorRefPatterns on GroupBehaviorRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupBehaviorRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupBehaviorRef() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupBehaviorRef value)  $default,){
final _that = this;
switch (_that) {
case _GroupBehaviorRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupBehaviorRef value)?  $default,){
final _that = this;
switch (_that) {
case _GroupBehaviorRef() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  int version,  Map<String, dynamic> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupBehaviorRef() when $default != null:
return $default(_that.type,_that.version,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  int version,  Map<String, dynamic> data)  $default,) {final _that = this;
switch (_that) {
case _GroupBehaviorRef():
return $default(_that.type,_that.version,_that.data);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  int version,  Map<String, dynamic> data)?  $default,) {final _that = this;
switch (_that) {
case _GroupBehaviorRef() when $default != null:
return $default(_that.type,_that.version,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupBehaviorRef implements GroupBehaviorRef {
  const _GroupBehaviorRef({required this.type, required this.version, required  Map<String, dynamic> data}): _data = data;
  factory _GroupBehaviorRef.fromJson(Map<String, dynamic> json) => _$GroupBehaviorRefFromJson(json);

@override final  String type;
@override final  int version;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of GroupBehaviorRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupBehaviorRefCopyWith<_GroupBehaviorRef> get copyWith => __$GroupBehaviorRefCopyWithImpl<_GroupBehaviorRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupBehaviorRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupBehaviorRef&&(identical(other.type, type) || other.type == type)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,version,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'GroupBehaviorRef(type: $type, version: $version, data: $data)';
}


}

/// @nodoc
abstract mixin class _$GroupBehaviorRefCopyWith<$Res> implements $GroupBehaviorRefCopyWith<$Res> {
  factory _$GroupBehaviorRefCopyWith(_GroupBehaviorRef value, $Res Function(_GroupBehaviorRef) _then) = __$GroupBehaviorRefCopyWithImpl;
@override @useResult
$Res call({
 String type, int version, Map<String, dynamic> data
});




}
/// @nodoc
class __$GroupBehaviorRefCopyWithImpl<$Res>
    implements _$GroupBehaviorRefCopyWith<$Res> {
  __$GroupBehaviorRefCopyWithImpl(this._self, this._then);

  final _GroupBehaviorRef _self;
  final $Res Function(_GroupBehaviorRef) _then;

/// Create a copy of GroupBehaviorRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? version = null,Object? data = null,}) {
  return _then(_GroupBehaviorRef(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

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

 ElementId get id;@JsonKey(includeIfNull: false) String? get name;@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool get hidden;@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D get xf;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Node&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden)&&(identical(other.xf, _this.xf) || other.xf == _this.xf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Node;
  return Object.hash(runtimeType,_this.id,_this.name,_this.hidden,_this.xf);
}

@override
String toString() {
  final _this = this as Node;
  return 'Node(id: ${_this.id}, name: ${_this.name}, hidden: ${_this.hidden}, xf: ${_this.xf})';
}


}

/// @nodoc
abstract mixin class $NodeCopyWith<$Res>  {
  factory $NodeCopyWith(Node value, $Res Function(Node) _then) = _$NodeCopyWithImpl;
@useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  text,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align, @JsonKey(includeIfNull: false)  String? role)?  image,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  path,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  icon,TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  GroupBehaviorRef? behavior,  List<Node> children)?  group,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.hidden,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance,_that.role);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.hidden,_that.xf,_that.assetId,_that.size,_that.fit,_that.align,_that.role);case PathNode() when path != null:
return path(_that.id,_that.name,_that.hidden,_that.xf,_that.geometry,_that.fillRule,_that.appearance,_that.role);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.hidden,_that.xf,_that.iconRef,_that.sizePx,_that.appearance,_that.role);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.hidden,_that.xf,_that.behavior,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)  text,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align, @JsonKey(includeIfNull: false)  String? role)  image,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)  path,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)  icon,required TResult Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  GroupBehaviorRef? behavior,  List<Node> children)  group,}) {final _that = this;
switch (_that) {
case TextNode():
return text(_that.id,_that.name,_that.hidden,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance,_that.role);case ImageNode():
return image(_that.id,_that.name,_that.hidden,_that.xf,_that.assetId,_that.size,_that.fit,_that.align,_that.role);case PathNode():
return path(_that.id,_that.name,_that.hidden,_that.xf,_that.geometry,_that.fillRule,_that.appearance,_that.role);case IconNode():
return icon(_that.id,_that.name,_that.hidden,_that.xf,_that.iconRef,_that.sizePx,_that.appearance,_that.role);case GroupNode():
return group(_that.id,_that.name,_that.hidden,_that.xf,_that.behavior,_that.children);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)  double letterSpacing,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  text,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  CanvasAssetId? assetId, @Size2DConverter()  Size2D size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false)  ImageFit fit, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false)  Vec2 align, @JsonKey(includeIfNull: false)  String? role)?  image,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @PathSourceConverter()  PathSource geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)  FillRule fillRule,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  path,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf,  String iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)  double sizePx,  CanvasAppearance appearance, @JsonKey(includeIfNull: false)  String? role)?  icon,TResult? Function( ElementId id, @JsonKey(includeIfNull: false)  String? name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false)  bool hidden, @JsonKey(includeIfNull: false)@Affine2DConverter()  Affine2D xf, @JsonKey(includeIfNull: false)  GroupBehaviorRef? behavior,  List<Node> children)?  group,}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.hidden,_that.xf,_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.appearance,_that.role);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.hidden,_that.xf,_that.assetId,_that.size,_that.fit,_that.align,_that.role);case PathNode() when path != null:
return path(_that.id,_that.name,_that.hidden,_that.xf,_that.geometry,_that.fillRule,_that.appearance,_that.role);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.hidden,_that.xf,_that.iconRef,_that.sizePx,_that.appearance,_that.role);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.hidden,_that.xf,_that.behavior,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextNode extends Node {
  const TextNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false) this.hidden = false, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), required this.text, required this.fontFamily, required this.fontWeight, required this.fontSize, @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false) this.letterSpacing = 0.0, this.appearance = const CanvasAppearance(), @JsonKey(includeIfNull: false) this.role,  String? $type}): $type = $type ?? 'text',super._();
  factory TextNode.fromJson(Map<String, dynamic> json) => _$TextNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(toJson: _hiddenToJson, includeIfNull: false) final  bool hidden;
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
@JsonKey(includeIfNull: false) final  String? role;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TextNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.text, text) || other.text == text)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,hidden,xf,text,fontFamily,fontWeight,fontSize,letterSpacing,appearance,role);
}

@override
String toString() {
    return 'Node.text(id: $id, name: $name, hidden: $hidden, xf: $xf, text: $text, fontFamily: $fontFamily, fontWeight: $fontWeight, fontSize: $fontSize, letterSpacing: $letterSpacing, appearance: $appearance, role: $role)';
}


}

/// @nodoc
abstract mixin class $TextNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $TextNodeCopyWith(TextNode value, $Res Function(TextNode) _then) = _$TextNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf, String text, String fontFamily, FontWeightNum fontWeight, double fontSize,@JsonKey(toJson: _letterSpacingToJson, includeIfNull: false) double letterSpacing, CanvasAppearance appearance,@JsonKey(includeIfNull: false) String? role
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,Object? text = null,Object? fontFamily = null,Object? fontWeight = null,Object? fontSize = null,Object? letterSpacing = null,Object? appearance = null,Object? role = freezed,}) {
  return _then(TextNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as FontWeightNum,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
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
  const ImageNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false) this.hidden = false, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), @JsonKey(includeIfNull: false) this.assetId, @Size2DConverter() required this.size, @JsonKey(toJson: _imageFitToJson, includeIfNull: false) this.fit = ImageFit.contain, @JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) this.align = const Vec2(0.5, 0.5), @JsonKey(includeIfNull: false) this.role,  String? $type}): $type = $type ?? 'image',super._();
  factory ImageNode.fromJson(Map<String, dynamic> json) => _$ImageNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(toJson: _hiddenToJson, includeIfNull: false) final  bool hidden;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
/// Null represents an intentionally unfilled image frame.
@JsonKey(includeIfNull: false) final  CanvasAssetId? assetId;
/// Editable destination-frame dimensions in document units.
@Size2DConverter() final  Size2D size;
@JsonKey(toJson: _imageFitToJson, includeIfNull: false) final  ImageFit fit;
@JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) final  Vec2 align;
@JsonKey(includeIfNull: false) final  String? role;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.size, size) || other.size == size)&&(identical(other.fit, fit) || other.fit == fit)&&(identical(other.align, align) || other.align == align)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,hidden,xf,assetId,size,fit,align,role);
}

@override
String toString() {
    return 'Node.image(id: $id, name: $name, hidden: $hidden, xf: $xf, assetId: $assetId, size: $size, fit: $fit, align: $align, role: $role)';
}


}

/// @nodoc
abstract mixin class $ImageNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $ImageNodeCopyWith(ImageNode value, $Res Function(ImageNode) _then) = _$ImageNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf,@JsonKey(includeIfNull: false) CanvasAssetId? assetId,@Size2DConverter() Size2D size,@JsonKey(toJson: _imageFitToJson, includeIfNull: false) ImageFit fit,@JsonKey(fromJson: Vec2.fromJson, toJson: _imageAlignToJson, includeIfNull: false) Vec2 align,@JsonKey(includeIfNull: false) String? role
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,Object? assetId = freezed,Object? size = null,Object? fit = null,Object? align = null,Object? role = freezed,}) {
  return _then(ImageNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as CanvasAssetId?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Size2D,fit: null == fit ? _self.fit : fit // ignore: cast_nullable_to_non_nullable
as ImageFit,align: null == align ? _self.align : align // ignore: cast_nullable_to_non_nullable
as Vec2,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PathNode extends Node {
  const PathNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false) this.hidden = false, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), @PathSourceConverter() required this.geometry, @JsonKey(toJson: _fillRuleToJson, includeIfNull: false) this.fillRule = FillRule.nonZero, this.appearance = const CanvasAppearance(foreground: CanvasFill.none()), @JsonKey(includeIfNull: false) this.role,  String? $type}): $type = $type ?? 'path',super._();
  factory PathNode.fromJson(Map<String, dynamic> json) => _$PathNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(toJson: _hiddenToJson, includeIfNull: false) final  bool hidden;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
/// The sole authored geometry source. Use an explicit empty source for an
/// intentionally empty path.
@PathSourceConverter() final  PathSource geometry;
@JsonKey(toJson: _fillRuleToJson, includeIfNull: false) final  FillRule fillRule;
@JsonKey() final  CanvasAppearance appearance;
@JsonKey(includeIfNull: false) final  String? role;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PathNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.fillRule, fillRule) || other.fillRule == fillRule)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,hidden,xf,geometry,fillRule,appearance,role);
}

@override
String toString() {
    return 'Node.path(id: $id, name: $name, hidden: $hidden, xf: $xf, geometry: $geometry, fillRule: $fillRule, appearance: $appearance, role: $role)';
}


}

/// @nodoc
abstract mixin class $PathNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $PathNodeCopyWith(PathNode value, $Res Function(PathNode) _then) = _$PathNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf,@PathSourceConverter() PathSource geometry,@JsonKey(toJson: _fillRuleToJson, includeIfNull: false) FillRule fillRule, CanvasAppearance appearance,@JsonKey(includeIfNull: false) String? role
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,Object? geometry = null,Object? fillRule = null,Object? appearance = null,Object? role = freezed,}) {
  return _then(PathNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,geometry: null == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as PathSource,fillRule: null == fillRule ? _self.fillRule : fillRule // ignore: cast_nullable_to_non_nullable
as FillRule,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
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
  const IconNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false) this.hidden = false, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), required this.iconRef, @JsonKey(toJson: _iconSizeToJson, includeIfNull: false) this.sizePx = 96.0, this.appearance = const CanvasAppearance(), @JsonKey(includeIfNull: false) this.role,  String? $type}): $type = $type ?? 'icon',super._();
  factory IconNode.fromJson(Map<String, dynamic> json) => _$IconNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(toJson: _hiddenToJson, includeIfNull: false) final  bool hidden;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
 final  String iconRef;
@JsonKey(toJson: _iconSizeToJson, includeIfNull: false) final  double sizePx;
@JsonKey() final  CanvasAppearance appearance;
@JsonKey(includeIfNull: false) final  String? role;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IconNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.sizePx, sizePx) || other.sizePx == sizePx)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,hidden,xf,iconRef,sizePx,appearance,role);
}

@override
String toString() {
    return 'Node.icon(id: $id, name: $name, hidden: $hidden, xf: $xf, iconRef: $iconRef, sizePx: $sizePx, appearance: $appearance, role: $role)';
}


}

/// @nodoc
abstract mixin class $IconNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $IconNodeCopyWith(IconNode value, $Res Function(IconNode) _then) = _$IconNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf, String iconRef,@JsonKey(toJson: _iconSizeToJson, includeIfNull: false) double sizePx, CanvasAppearance appearance,@JsonKey(includeIfNull: false) String? role
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,Object? iconRef = null,Object? sizePx = null,Object? appearance = null,Object? role = freezed,}) {
  return _then(IconNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,sizePx: null == sizePx ? _self.sizePx : sizePx // ignore: cast_nullable_to_non_nullable
as double,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as CanvasAppearance,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
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
  const GroupNode({required this.id, @JsonKey(includeIfNull: false) this.name, @JsonKey(toJson: _hiddenToJson, includeIfNull: false) this.hidden = false, @JsonKey(includeIfNull: false)@Affine2DConverter() this.xf = const Affine2D.identity(), @JsonKey(includeIfNull: false) this.behavior,  List<Node> children = const <Node>[],  String? $type}): _children = children,$type = $type ?? 'group',super._();
  factory GroupNode.fromJson(Map<String, dynamic> json) => _$GroupNodeFromJson(json);

@override final  ElementId id;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(toJson: _hiddenToJson, includeIfNull: false) final  bool hidden;
@override@JsonKey(includeIfNull: false)@Affine2DConverter() final  Affine2D xf;
@JsonKey(includeIfNull: false) final  GroupBehaviorRef? behavior;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.behavior, behavior) || other.behavior == behavior)&&const DeepCollectionEquality().equals(other.children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,hidden,xf,behavior,const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return 'Node.group(id: $id, name: $name, hidden: $hidden, xf: $xf, behavior: $behavior, children: $children)';
}


}

/// @nodoc
abstract mixin class $GroupNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $GroupNodeCopyWith(GroupNode value, $Res Function(GroupNode) _then) = _$GroupNodeCopyWithImpl;
@override @useResult
$Res call({
 ElementId id,@JsonKey(includeIfNull: false) String? name,@JsonKey(toJson: _hiddenToJson, includeIfNull: false) bool hidden,@JsonKey(includeIfNull: false)@Affine2DConverter() Affine2D xf,@JsonKey(includeIfNull: false) GroupBehaviorRef? behavior, List<Node> children
});


$GroupBehaviorRefCopyWith<$Res>? get behavior;

}
/// @nodoc
class _$GroupNodeCopyWithImpl<$Res>
    implements $GroupNodeCopyWith<$Res> {
  _$GroupNodeCopyWithImpl(this._self, this._then);

  final GroupNode _self;
  final $Res Function(GroupNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? xf = null,Object? behavior = freezed,Object? children = null,}) {
  return _then(GroupNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ElementId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Affine2D,behavior: freezed == behavior ? _self.behavior : behavior // ignore: cast_nullable_to_non_nullable
as GroupBehaviorRef?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupBehaviorRefCopyWith<$Res>? get behavior {
    if (_self.behavior == null) {
    return null;
  }

  return $GroupBehaviorRefCopyWith<$Res>(_self.behavior!, (value) {
    return _then(_self.copyWith(behavior: value));
  });
}
}

// dart format on
