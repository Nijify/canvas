// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CanvasImageAsset {

 String get sourceRef;@NullableSize2DConverter() Size2D? get intrinsicSize;
/// Create a copy of CanvasImageAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasImageAssetCopyWith<CanvasImageAsset> get copyWith => _$CanvasImageAssetCopyWithImpl<CanvasImageAsset>(this as CanvasImageAsset, _$identity);

  /// Serializes this CanvasImageAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasImageAsset&&(identical(other.sourceRef, sourceRef) || other.sourceRef == sourceRef)&&(identical(other.intrinsicSize, intrinsicSize) || other.intrinsicSize == intrinsicSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceRef,intrinsicSize);

@override
String toString() {
  return 'CanvasImageAsset(sourceRef: $sourceRef, intrinsicSize: $intrinsicSize)';
}


}

/// @nodoc
abstract mixin class $CanvasImageAssetCopyWith<$Res>  {
  factory $CanvasImageAssetCopyWith(CanvasImageAsset value, $Res Function(CanvasImageAsset) _then) = _$CanvasImageAssetCopyWithImpl;
@useResult
$Res call({
 String sourceRef,@NullableSize2DConverter() Size2D? intrinsicSize
});




}
/// @nodoc
class _$CanvasImageAssetCopyWithImpl<$Res>
    implements $CanvasImageAssetCopyWith<$Res> {
  _$CanvasImageAssetCopyWithImpl(this._self, this._then);

  final CanvasImageAsset _self;
  final $Res Function(CanvasImageAsset) _then;

/// Create a copy of CanvasImageAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceRef = null,Object? intrinsicSize = freezed,}) {
  return _then(_self.copyWith(
sourceRef: null == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String,intrinsicSize: freezed == intrinsicSize ? _self.intrinsicSize : intrinsicSize // ignore: cast_nullable_to_non_nullable
as Size2D?,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasImageAsset].
extension CanvasImageAssetPatterns on CanvasImageAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasImageAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasImageAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasImageAsset value)  $default,){
final _that = this;
switch (_that) {
case _CanvasImageAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasImageAsset value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasImageAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourceRef, @NullableSize2DConverter()  Size2D? intrinsicSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasImageAsset() when $default != null:
return $default(_that.sourceRef,_that.intrinsicSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourceRef, @NullableSize2DConverter()  Size2D? intrinsicSize)  $default,) {final _that = this;
switch (_that) {
case _CanvasImageAsset():
return $default(_that.sourceRef,_that.intrinsicSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourceRef, @NullableSize2DConverter()  Size2D? intrinsicSize)?  $default,) {final _that = this;
switch (_that) {
case _CanvasImageAsset() when $default != null:
return $default(_that.sourceRef,_that.intrinsicSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasImageAsset implements CanvasImageAsset {
  const _CanvasImageAsset({required this.sourceRef, @NullableSize2DConverter() this.intrinsicSize});
  factory _CanvasImageAsset.fromJson(Map<String, dynamic> json) => _$CanvasImageAssetFromJson(json);

@override final  String sourceRef;
@override@NullableSize2DConverter() final  Size2D? intrinsicSize;

/// Create a copy of CanvasImageAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasImageAssetCopyWith<_CanvasImageAsset> get copyWith => __$CanvasImageAssetCopyWithImpl<_CanvasImageAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasImageAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasImageAsset&&(identical(other.sourceRef, sourceRef) || other.sourceRef == sourceRef)&&(identical(other.intrinsicSize, intrinsicSize) || other.intrinsicSize == intrinsicSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceRef,intrinsicSize);

@override
String toString() {
  return 'CanvasImageAsset(sourceRef: $sourceRef, intrinsicSize: $intrinsicSize)';
}


}

/// @nodoc
abstract mixin class _$CanvasImageAssetCopyWith<$Res> implements $CanvasImageAssetCopyWith<$Res> {
  factory _$CanvasImageAssetCopyWith(_CanvasImageAsset value, $Res Function(_CanvasImageAsset) _then) = __$CanvasImageAssetCopyWithImpl;
@override @useResult
$Res call({
 String sourceRef,@NullableSize2DConverter() Size2D? intrinsicSize
});




}
/// @nodoc
class __$CanvasImageAssetCopyWithImpl<$Res>
    implements _$CanvasImageAssetCopyWith<$Res> {
  __$CanvasImageAssetCopyWithImpl(this._self, this._then);

  final _CanvasImageAsset _self;
  final $Res Function(_CanvasImageAsset) _then;

/// Create a copy of CanvasImageAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceRef = null,Object? intrinsicSize = freezed,}) {
  return _then(_CanvasImageAsset(
sourceRef: null == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String,intrinsicSize: freezed == intrinsicSize ? _self.intrinsicSize : intrinsicSize // ignore: cast_nullable_to_non_nullable
as Size2D?,
  ));
}


}


/// @nodoc
mixin _$CanvasSceneDocument {

@Size2DConverter() Size2D get artboardSize;@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill get backgroundFill;@JsonKey(required: true, disallowNullValue: true) double get backgroundOpacity; Map<CanvasAssetId, CanvasImageAsset> get assets; List<Node> get children;
/// Create a copy of CanvasSceneDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasSceneDocumentCopyWith<CanvasSceneDocument> get copyWith => _$CanvasSceneDocumentCopyWithImpl<CanvasSceneDocument>(this as CanvasSceneDocument, _$identity);

  /// Serializes this CanvasSceneDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasSceneDocument&&(identical(other.artboardSize, artboardSize) || other.artboardSize == artboardSize)&&(identical(other.backgroundFill, backgroundFill) || other.backgroundFill == backgroundFill)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&const DeepCollectionEquality().equals(other.assets, assets)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artboardSize,backgroundFill,backgroundOpacity,const DeepCollectionEquality().hash(assets),const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'CanvasSceneDocument(artboardSize: $artboardSize, backgroundFill: $backgroundFill, backgroundOpacity: $backgroundOpacity, assets: $assets, children: $children)';
}


}

/// @nodoc
abstract mixin class $CanvasSceneDocumentCopyWith<$Res>  {
  factory $CanvasSceneDocumentCopyWith(CanvasSceneDocument value, $Res Function(CanvasSceneDocument) _then) = _$CanvasSceneDocumentCopyWithImpl;
@useResult
$Res call({
@Size2DConverter() Size2D artboardSize,@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill backgroundFill,@JsonKey(required: true, disallowNullValue: true) double backgroundOpacity, Map<CanvasAssetId, CanvasImageAsset> assets, List<Node> children
});




}
/// @nodoc
class _$CanvasSceneDocumentCopyWithImpl<$Res>
    implements $CanvasSceneDocumentCopyWith<$Res> {
  _$CanvasSceneDocumentCopyWithImpl(this._self, this._then);

  final CanvasSceneDocument _self;
  final $Res Function(CanvasSceneDocument) _then;

/// Create a copy of CanvasSceneDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artboardSize = null,Object? backgroundFill = null,Object? backgroundOpacity = null,Object? assets = null,Object? children = null,}) {
  return _then(_self.copyWith(
artboardSize: null == artboardSize ? _self.artboardSize : artboardSize // ignore: cast_nullable_to_non_nullable
as Size2D,backgroundFill: null == backgroundFill ? _self.backgroundFill : backgroundFill // ignore: cast_nullable_to_non_nullable
as CanvasFill,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as Map<CanvasAssetId, CanvasImageAsset>,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasSceneDocument].
extension CanvasSceneDocumentPatterns on CanvasSceneDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasSceneDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasSceneDocument value)  $default,){
final _that = this;
switch (_that) {
case _CanvasSceneDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasSceneDocument value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  Map<CanvasAssetId, CanvasImageAsset> assets,  List<Node> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.assets,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  Map<CanvasAssetId, CanvasImageAsset> assets,  List<Node> children)  $default,) {final _that = this;
switch (_that) {
case _CanvasSceneDocument():
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.assets,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  Map<CanvasAssetId, CanvasImageAsset> assets,  List<Node> children)?  $default,) {final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.assets,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasSceneDocument extends CanvasSceneDocument {
  const _CanvasSceneDocument({@Size2DConverter() this.artboardSize = const Size2D(740, 360), @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) required this.backgroundFill, @JsonKey(required: true, disallowNullValue: true) required this.backgroundOpacity, final  Map<CanvasAssetId, CanvasImageAsset> assets = const <CanvasAssetId, CanvasImageAsset>{}, final  List<Node> children = const <Node>[]}): _assets = assets,_children = children,super._();
  factory _CanvasSceneDocument.fromJson(Map<String, dynamic> json) => _$CanvasSceneDocumentFromJson(json);

@override@JsonKey()@Size2DConverter() final  Size2D artboardSize;
@override@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) final  CanvasFill backgroundFill;
@override@JsonKey(required: true, disallowNullValue: true) final  double backgroundOpacity;
 final  Map<CanvasAssetId, CanvasImageAsset> _assets;
@override@JsonKey() Map<CanvasAssetId, CanvasImageAsset> get assets {
  if (_assets is EqualUnmodifiableMapView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_assets);
}

 final  List<Node> _children;
@override@JsonKey() List<Node> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of CanvasSceneDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasSceneDocumentCopyWith<_CanvasSceneDocument> get copyWith => __$CanvasSceneDocumentCopyWithImpl<_CanvasSceneDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasSceneDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasSceneDocument&&(identical(other.artboardSize, artboardSize) || other.artboardSize == artboardSize)&&(identical(other.backgroundFill, backgroundFill) || other.backgroundFill == backgroundFill)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&const DeepCollectionEquality().equals(other._assets, _assets)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artboardSize,backgroundFill,backgroundOpacity,const DeepCollectionEquality().hash(_assets),const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'CanvasSceneDocument(artboardSize: $artboardSize, backgroundFill: $backgroundFill, backgroundOpacity: $backgroundOpacity, assets: $assets, children: $children)';
}


}

/// @nodoc
abstract mixin class _$CanvasSceneDocumentCopyWith<$Res> implements $CanvasSceneDocumentCopyWith<$Res> {
  factory _$CanvasSceneDocumentCopyWith(_CanvasSceneDocument value, $Res Function(_CanvasSceneDocument) _then) = __$CanvasSceneDocumentCopyWithImpl;
@override @useResult
$Res call({
@Size2DConverter() Size2D artboardSize,@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill backgroundFill,@JsonKey(required: true, disallowNullValue: true) double backgroundOpacity, Map<CanvasAssetId, CanvasImageAsset> assets, List<Node> children
});




}
/// @nodoc
class __$CanvasSceneDocumentCopyWithImpl<$Res>
    implements _$CanvasSceneDocumentCopyWith<$Res> {
  __$CanvasSceneDocumentCopyWithImpl(this._self, this._then);

  final _CanvasSceneDocument _self;
  final $Res Function(_CanvasSceneDocument) _then;

/// Create a copy of CanvasSceneDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artboardSize = null,Object? backgroundFill = null,Object? backgroundOpacity = null,Object? assets = null,Object? children = null,}) {
  return _then(_CanvasSceneDocument(
artboardSize: null == artboardSize ? _self.artboardSize : artboardSize // ignore: cast_nullable_to_non_nullable
as Size2D,backgroundFill: null == backgroundFill ? _self.backgroundFill : backgroundFill // ignore: cast_nullable_to_non_nullable
as CanvasFill,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as Map<CanvasAssetId, CanvasImageAsset>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}


}

// dart format on
