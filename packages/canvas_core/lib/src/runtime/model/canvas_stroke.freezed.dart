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

 Color32 get color; double get width; StrokeCap get cap; StrokeJoin get join; double get miterLimit; List<double> get dash;
/// Create a copy of CanvasStroke
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasStrokeCopyWith<CanvasStroke> get copyWith => _$CanvasStrokeCopyWithImpl<CanvasStroke>(this as CanvasStroke, _$identity);

  /// Serializes this CanvasStroke to a JSON map.
  Map<String, dynamic> toJson();


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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasStroke value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasStroke() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasStroke value)  $default,){
final _that = this;
switch (_that) {
case _CanvasStroke():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasStroke value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasStroke() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Color32 color,  double width,  StrokeCap cap,  StrokeJoin join,  double miterLimit,  List<double> dash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasStroke() when $default != null:
return $default(_that.color,_that.width,_that.cap,_that.join,_that.miterLimit,_that.dash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Color32 color,  double width,  StrokeCap cap,  StrokeJoin join,  double miterLimit,  List<double> dash)  $default,) {final _that = this;
switch (_that) {
case _CanvasStroke():
return $default(_that.color,_that.width,_that.cap,_that.join,_that.miterLimit,_that.dash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Color32 color,  double width,  StrokeCap cap,  StrokeJoin join,  double miterLimit,  List<double> dash)?  $default,) {final _that = this;
switch (_that) {
case _CanvasStroke() when $default != null:
return $default(_that.color,_that.width,_that.cap,_that.join,_that.miterLimit,_that.dash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasStroke implements CanvasStroke {
  const _CanvasStroke({required this.color, this.width = 4.0, this.cap = StrokeCap.butt, this.join = StrokeJoin.miter, this.miterLimit = 4.0,  List<double> dash = const <double>[]}): _dash = dash;
  factory _CanvasStroke.fromJson(Map<String, dynamic> json) => _$CanvasStrokeFromJson(json);

@override final  Color32 color;
@override@JsonKey() final  double width;
@override@JsonKey() final  StrokeCap cap;
@override@JsonKey() final  StrokeJoin join;
@override@JsonKey() final  double miterLimit;
 final  List<double> _dash;
@override@JsonKey() List<double> get dash {
  if (_dash is EqualUnmodifiableListView) return _dash;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dash);
}


/// Create a copy of CanvasStroke
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasStrokeCopyWith<_CanvasStroke> get copyWith => __$CanvasStrokeCopyWithImpl<_CanvasStroke>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasStrokeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasStroke&&(identical(other.color, color) || other.color == color)&&(identical(other.width, width) || other.width == width)&&(identical(other.cap, cap) || other.cap == cap)&&(identical(other.join, join) || other.join == join)&&(identical(other.miterLimit, miterLimit) || other.miterLimit == miterLimit)&&const DeepCollectionEquality().equals(other.dash, _dash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,color,width,cap,join,miterLimit,const DeepCollectionEquality().hash(_dash));
}

@override
String toString() {
    return 'CanvasStroke(color: $color, width: $width, cap: $cap, join: $join, miterLimit: $miterLimit, dash: $dash)';
}


}

/// @nodoc
abstract mixin class _$CanvasStrokeCopyWith<$Res> implements $CanvasStrokeCopyWith<$Res> {
  factory _$CanvasStrokeCopyWith(_CanvasStroke value, $Res Function(_CanvasStroke) _then) = __$CanvasStrokeCopyWithImpl;
@override @useResult
$Res call({
 Color32 color, double width, StrokeCap cap, StrokeJoin join, double miterLimit, List<double> dash
});




}
/// @nodoc
class __$CanvasStrokeCopyWithImpl<$Res>
    implements _$CanvasStrokeCopyWith<$Res> {
  __$CanvasStrokeCopyWithImpl(this._self, this._then);

  final _CanvasStroke _self;
  final $Res Function(_CanvasStroke) _then;

/// Create a copy of CanvasStroke
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = null,Object? width = null,Object? cap = null,Object? join = null,Object? miterLimit = null,Object? dash = null,}) {
  return _then(_CanvasStroke(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color32,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as StrokeCap,join: null == join ? _self.join : join // ignore: cast_nullable_to_non_nullable
as StrokeJoin,miterLimit: null == miterLimit ? _self.miterLimit : miterLimit // ignore: cast_nullable_to_non_nullable
as double,dash: null == dash ? _self._dash : dash // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}

// dart format on
