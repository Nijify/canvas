// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canvas_stroke.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CanvasStroke {


/// Create a copy of CanvasStroke
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasStrokeCopyWith<CanvasStroke> get copyWith => _$CanvasStrokeCopyWithImpl<CanvasStroke>(this as CanvasStroke, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CanvasStroke;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasStroke&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.cap, _this.cap) || other.cap == _this.cap)&&(identical(other.join, _this.join) || other.join == _this.join)&&(identical(other.miterLimit, _this.miterLimit) || other.miterLimit == _this.miterLimit)&&const DeepCollectionEquality().equals(other.dash, _this.dash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CanvasStroke;
  return Object.hash(runtimeType,_this.color,_this.width,_this.cap,_this.join,_this.miterLimit,const DeepCollectionEquality().hash(_this.dash));
}

@override
String toString() {
  final _this = this as CanvasStroke;
  return 'CanvasStroke(color: ${_this.color}, width: ${_this.width}, cap: ${_this.cap}, join: ${_this.join}, miterLimit: ${_this.miterLimit}, dash: ${_this.dash})';
}


}

/// @nodoc
abstract mixin class $CanvasStrokeCopyWith<$Res>  {
  factory $CanvasStrokeCopyWith(CanvasStroke value, $Res Function(CanvasStroke) _then) = _$CanvasStrokeCopyWithImpl;
@useResult
$Res call({
 Color32 color, double width, StrokeCap cap, StrokeJoin join, double miterLimit, List<double> dash
});




}
/// @nodoc
class _$CanvasStrokeCopyWithImpl<$Res>
    implements $CanvasStrokeCopyWith<$Res> {
  _$CanvasStrokeCopyWithImpl(this._self, this._then);

  final CanvasStroke _self;
  final $Res Function(CanvasStroke) _then;

/// Create a copy of CanvasStroke
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = null,Object? width = null,Object? cap = null,Object? join = null,Object? miterLimit = null,Object? dash = null,}) {
  return _then(CanvasStroke(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color32,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as StrokeCap,join: null == join ? _self.join : join // ignore: cast_nullable_to_non_nullable
as StrokeJoin,miterLimit: null == miterLimit ? _self.miterLimit : miterLimit // ignore: cast_nullable_to_non_nullable
as double,dash: null == dash ? _self.dash : dash // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasStroke].
extension CanvasStrokePatterns on CanvasStroke {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
