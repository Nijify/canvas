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
mixin _$CanvasSceneDocument {

@Size2DConverter() Size2D get artboardSize;@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill get backgroundFill;@JsonKey(required: true, disallowNullValue: true) double get backgroundOpacity; List<Node> get children;
/// Create a copy of CanvasSceneDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasSceneDocumentCopyWith<CanvasSceneDocument> get copyWith => _$CanvasSceneDocumentCopyWithImpl<CanvasSceneDocument>(this as CanvasSceneDocument, _$identity);

  /// Serializes this CanvasSceneDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasSceneDocument&&(identical(other.artboardSize, artboardSize) || other.artboardSize == artboardSize)&&(identical(other.backgroundFill, backgroundFill) || other.backgroundFill == backgroundFill)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artboardSize,backgroundFill,backgroundOpacity,const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'CanvasSceneDocument(artboardSize: $artboardSize, backgroundFill: $backgroundFill, backgroundOpacity: $backgroundOpacity, children: $children)';
}


}

/// @nodoc
abstract mixin class $CanvasSceneDocumentCopyWith<$Res>  {
  factory $CanvasSceneDocumentCopyWith(CanvasSceneDocument value, $Res Function(CanvasSceneDocument) _then) = _$CanvasSceneDocumentCopyWithImpl;
@useResult
$Res call({
@Size2DConverter() Size2D artboardSize,@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill backgroundFill,@JsonKey(required: true, disallowNullValue: true) double backgroundOpacity, List<Node> children
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
@pragma('vm:prefer-inline') @override $Res call({Object? artboardSize = null,Object? backgroundFill = null,Object? backgroundOpacity = null,Object? children = null,}) {
  return _then(_self.copyWith(
artboardSize: null == artboardSize ? _self.artboardSize : artboardSize // ignore: cast_nullable_to_non_nullable
as Size2D,backgroundFill: null == backgroundFill ? _self.backgroundFill : backgroundFill // ignore: cast_nullable_to_non_nullable
as CanvasFill,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  List<Node> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  List<Node> children)  $default,) {final _that = this;
switch (_that) {
case _CanvasSceneDocument():
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@Size2DConverter()  Size2D artboardSize, @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true)  CanvasFill backgroundFill, @JsonKey(required: true, disallowNullValue: true)  double backgroundOpacity,  List<Node> children)?  $default,) {final _that = this;
switch (_that) {
case _CanvasSceneDocument() when $default != null:
return $default(_that.artboardSize,_that.backgroundFill,_that.backgroundOpacity,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasSceneDocument extends CanvasSceneDocument {
  const _CanvasSceneDocument({@Size2DConverter() this.artboardSize = const Size2D(740, 360), @CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) required this.backgroundFill, @JsonKey(required: true, disallowNullValue: true) required this.backgroundOpacity, final  List<Node> children = const <Node>[]}): _children = children,super._();
  factory _CanvasSceneDocument.fromJson(Map<String, dynamic> json) => _$CanvasSceneDocumentFromJson(json);

@override@JsonKey()@Size2DConverter() final  Size2D artboardSize;
@override@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) final  CanvasFill backgroundFill;
@override@JsonKey(required: true, disallowNullValue: true) final  double backgroundOpacity;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasSceneDocument&&(identical(other.artboardSize, artboardSize) || other.artboardSize == artboardSize)&&(identical(other.backgroundFill, backgroundFill) || other.backgroundFill == backgroundFill)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artboardSize,backgroundFill,backgroundOpacity,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'CanvasSceneDocument(artboardSize: $artboardSize, backgroundFill: $backgroundFill, backgroundOpacity: $backgroundOpacity, children: $children)';
}


}

/// @nodoc
abstract mixin class _$CanvasSceneDocumentCopyWith<$Res> implements $CanvasSceneDocumentCopyWith<$Res> {
  factory _$CanvasSceneDocumentCopyWith(_CanvasSceneDocument value, $Res Function(_CanvasSceneDocument) _then) = __$CanvasSceneDocumentCopyWithImpl;
@override @useResult
$Res call({
@Size2DConverter() Size2D artboardSize,@CanvasFillConverter()@JsonKey(required: true, disallowNullValue: true) CanvasFill backgroundFill,@JsonKey(required: true, disallowNullValue: true) double backgroundOpacity, List<Node> children
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
@override @pragma('vm:prefer-inline') $Res call({Object? artboardSize = null,Object? backgroundFill = null,Object? backgroundOpacity = null,Object? children = null,}) {
  return _then(_CanvasSceneDocument(
artboardSize: null == artboardSize ? _self.artboardSize : artboardSize // ignore: cast_nullable_to_non_nullable
as Size2D,backgroundFill: null == backgroundFill ? _self.backgroundFill : backgroundFill // ignore: cast_nullable_to_non_nullable
as CanvasFill,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}


}

// dart format on
