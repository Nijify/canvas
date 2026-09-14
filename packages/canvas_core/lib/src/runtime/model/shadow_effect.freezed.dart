// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shadow_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShadowEffect {

 String get id; bool get enabled;@Vec2Converter() Vec2 get offset; double get blurSigma; Color32 get color;
/// Create a copy of ShadowEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShadowEffectCopyWith<ShadowEffect> get copyWith => _$ShadowEffectCopyWithImpl<ShadowEffect>(this as ShadowEffect, _$identity);

  /// Serializes this ShadowEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShadowEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShadowEffect&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.blurSigma, _this.blurSigma) || other.blurSigma == _this.blurSigma)&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShadowEffect;
  return Object.hash(runtimeType,_this.id,_this.enabled,_this.offset,_this.blurSigma,_this.color);
}

@override
String toString() {
  final _this = this as ShadowEffect;
  return 'ShadowEffect(id: ${_this.id}, enabled: ${_this.enabled}, offset: ${_this.offset}, blurSigma: ${_this.blurSigma}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $ShadowEffectCopyWith<$Res>  {
  factory $ShadowEffectCopyWith(ShadowEffect value, $Res Function(ShadowEffect) _then) = _$ShadowEffectCopyWithImpl;
@useResult
$Res call({
 String id, bool enabled,@Vec2Converter() Vec2 offset, double blurSigma, Color32 color
});




}
/// @nodoc
class _$ShadowEffectCopyWithImpl<$Res>
    implements $ShadowEffectCopyWith<$Res> {
  _$ShadowEffectCopyWithImpl(this._self, this._then);

  final ShadowEffect _self;
  final $Res Function(ShadowEffect) _then;

/// Create a copy of ShadowEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enabled = null,Object? offset = null,Object? blurSigma = null,Object? color = null,}) {
  return _then(ShadowEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as Vec2,blurSigma: null == blurSigma ? _self.blurSigma : blurSigma // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color32,
  ));
}

}


/// Adds pattern-matching-related methods to [ShadowEffect].
extension ShadowEffectPatterns on ShadowEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShadowEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShadowEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShadowEffect value)  $default,){
final _that = this;
switch (_that) {
case _ShadowEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShadowEffect value)?  $default,){
final _that = this;
switch (_that) {
case _ShadowEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShadowEffect() when $default != null:
return $default(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)  $default,) {final _that = this;
switch (_that) {
case _ShadowEffect():
return $default(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)?  $default,) {final _that = this;
switch (_that) {
case _ShadowEffect() when $default != null:
return $default(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShadowEffect implements ShadowEffect {
  const _ShadowEffect({required this.id, this.enabled = true, @Vec2Converter() required this.offset, this.blurSigma = 0.0, required this.color});
  factory _ShadowEffect.fromJson(Map<String, dynamic> json) => _$ShadowEffectFromJson(json);

@override final  String id;
@override@JsonKey() final  bool enabled;
@override@Vec2Converter() final  Vec2 offset;
@override@JsonKey() final  double blurSigma;
@override final  Color32 color;

/// Create a copy of ShadowEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShadowEffectCopyWith<_ShadowEffect> get copyWith => __$ShadowEffectCopyWithImpl<_ShadowEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShadowEffectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShadowEffect&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.blurSigma, blurSigma) || other.blurSigma == blurSigma)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,enabled,offset,blurSigma,color);
}

@override
String toString() {
    return 'ShadowEffect(id: $id, enabled: $enabled, offset: $offset, blurSigma: $blurSigma, color: $color)';
}


}

/// @nodoc
abstract mixin class _$ShadowEffectCopyWith<$Res> implements $ShadowEffectCopyWith<$Res> {
  factory _$ShadowEffectCopyWith(_ShadowEffect value, $Res Function(_ShadowEffect) _then) = __$ShadowEffectCopyWithImpl;
@override @useResult
$Res call({
 String id, bool enabled,@Vec2Converter() Vec2 offset, double blurSigma, Color32 color
});




}
/// @nodoc
class __$ShadowEffectCopyWithImpl<$Res>
    implements _$ShadowEffectCopyWith<$Res> {
  __$ShadowEffectCopyWithImpl(this._self, this._then);

  final _ShadowEffect _self;
  final $Res Function(_ShadowEffect) _then;

/// Create a copy of ShadowEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enabled = null,Object? offset = null,Object? blurSigma = null,Object? color = null,}) {
  return _then(_ShadowEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as Vec2,blurSigma: null == blurSigma ? _self.blurSigma : blurSigma // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color32,
  ));
}


}

// dart format on
