// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canvas_appearance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CanvasSourceUnderlay {

 String get id; bool get enabled;@Vec2Converter() Vec2 get offset; double get blurSigma; Color32 get color;
/// Create a copy of CanvasSourceUnderlay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasSourceUnderlayCopyWith<CanvasSourceUnderlay> get copyWith => _$CanvasSourceUnderlayCopyWithImpl<CanvasSourceUnderlay>(this as CanvasSourceUnderlay, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CanvasSourceUnderlay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasSourceUnderlay&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.blurSigma, _this.blurSigma) || other.blurSigma == _this.blurSigma)&&(identical(other.color, _this.color) || other.color == _this.color));
}


@override
int get hashCode {
  final _this = this as CanvasSourceUnderlay;
  return Object.hash(runtimeType,_this.id,_this.enabled,_this.offset,_this.blurSigma,_this.color);
}

@override
String toString() {
  final _this = this as CanvasSourceUnderlay;
  return 'CanvasSourceUnderlay(id: ${_this.id}, enabled: ${_this.enabled}, offset: ${_this.offset}, blurSigma: ${_this.blurSigma}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $CanvasSourceUnderlayCopyWith<$Res>  {
  factory $CanvasSourceUnderlayCopyWith(CanvasSourceUnderlay value, $Res Function(CanvasSourceUnderlay) _then) = _$CanvasSourceUnderlayCopyWithImpl;
@useResult
$Res call({
 String id, bool enabled,@Vec2Converter() Vec2 offset, double blurSigma, Color32 color
});




}
/// @nodoc
class _$CanvasSourceUnderlayCopyWithImpl<$Res>
    implements $CanvasSourceUnderlayCopyWith<$Res> {
  _$CanvasSourceUnderlayCopyWithImpl(this._self, this._then);

  final CanvasSourceUnderlay _self;
  final $Res Function(CanvasSourceUnderlay) _then;

/// Create a copy of CanvasSourceUnderlay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enabled = null,Object? offset = null,Object? blurSigma = null,Object? color = null,}) {
  return _then(CanvasSourceUnderlay.shadow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as Vec2,blurSigma: null == blurSigma ? _self.blurSigma : blurSigma // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color32,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasSourceUnderlay].
extension CanvasSourceUnderlayPatterns on CanvasSourceUnderlay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShadowEffect value)?  shadow,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShadowEffect() when shadow != null:
return shadow(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShadowEffect value)  shadow,}){
final _that = this;
switch (_that) {
case ShadowEffect():
return shadow(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShadowEffect value)?  shadow,}){
final _that = this;
switch (_that) {
case ShadowEffect() when shadow != null:
return shadow(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)?  shadow,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShadowEffect() when shadow != null:
return shadow(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)  shadow,}) {final _that = this;
switch (_that) {
case ShadowEffect():
return shadow(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  bool enabled, @Vec2Converter()  Vec2 offset,  double blurSigma,  Color32 color)?  shadow,}) {final _that = this;
switch (_that) {
case ShadowEffect() when shadow != null:
return shadow(_that.id,_that.enabled,_that.offset,_that.blurSigma,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class ShadowEffect implements CanvasSourceUnderlay {
  const ShadowEffect({required this.id, this.enabled = true, @Vec2Converter() required this.offset, this.blurSigma = 0.0, required this.color});
  

@override final  String id;
@override@JsonKey() final  bool enabled;
@override@Vec2Converter() final  Vec2 offset;
@override@JsonKey() final  double blurSigma;
@override final  Color32 color;

/// Create a copy of CanvasSourceUnderlay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShadowEffectCopyWith<ShadowEffect> get copyWith => _$ShadowEffectCopyWithImpl<ShadowEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ShadowEffect&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.blurSigma, blurSigma) || other.blurSigma == blurSigma)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,enabled,offset,blurSigma,color);
}

@override
String toString() {
    return 'CanvasSourceUnderlay.shadow(id: $id, enabled: $enabled, offset: $offset, blurSigma: $blurSigma, color: $color)';
}


}

/// @nodoc
abstract mixin class $ShadowEffectCopyWith<$Res> implements $CanvasSourceUnderlayCopyWith<$Res> {
  factory $ShadowEffectCopyWith(ShadowEffect value, $Res Function(ShadowEffect) _then) = _$ShadowEffectCopyWithImpl;
@override @useResult
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

/// Create a copy of CanvasSourceUnderlay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enabled = null,Object? offset = null,Object? blurSigma = null,Object? color = null,}) {
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


/// @nodoc
mixin _$CanvasAppearance {

@CanvasFillConverter() CanvasFill get foreground;@_CanvasSourceUnderlayJsonConverter() List<CanvasSourceUnderlay> get underlays;
/// Create a copy of CanvasAppearance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasAppearanceCopyWith<CanvasAppearance> get copyWith => _$CanvasAppearanceCopyWithImpl<CanvasAppearance>(this as CanvasAppearance, _$identity);

  /// Serializes this CanvasAppearance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CanvasAppearance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasAppearance&&(identical(other.foreground, _this.foreground) || other.foreground == _this.foreground)&&const DeepCollectionEquality().equals(other.underlays, _this.underlays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CanvasAppearance;
  return Object.hash(runtimeType,_this.foreground,const DeepCollectionEquality().hash(_this.underlays));
}

@override
String toString() {
  final _this = this as CanvasAppearance;
  return 'CanvasAppearance(foreground: ${_this.foreground}, underlays: ${_this.underlays})';
}


}

/// @nodoc
abstract mixin class $CanvasAppearanceCopyWith<$Res>  {
  factory $CanvasAppearanceCopyWith(CanvasAppearance value, $Res Function(CanvasAppearance) _then) = _$CanvasAppearanceCopyWithImpl;
@useResult
$Res call({
@CanvasFillConverter() CanvasFill foreground,@_CanvasSourceUnderlayJsonConverter() List<CanvasSourceUnderlay> underlays
});




}
/// @nodoc
class _$CanvasAppearanceCopyWithImpl<$Res>
    implements $CanvasAppearanceCopyWith<$Res> {
  _$CanvasAppearanceCopyWithImpl(this._self, this._then);

  final CanvasAppearance _self;
  final $Res Function(CanvasAppearance) _then;

/// Create a copy of CanvasAppearance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? foreground = null,Object? underlays = null,}) {
  return _then(CanvasAppearance(
foreground: null == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as CanvasFill,underlays: null == underlays ? _self.underlays : underlays // ignore: cast_nullable_to_non_nullable
as List<CanvasSourceUnderlay>,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasAppearance].
extension CanvasAppearancePatterns on CanvasAppearance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasAppearance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasAppearance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasAppearance value)  $default,){
final _that = this;
switch (_that) {
case _CanvasAppearance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasAppearance value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasAppearance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@CanvasFillConverter()  CanvasFill foreground, @_CanvasSourceUnderlayJsonConverter()  List<CanvasSourceUnderlay> underlays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasAppearance() when $default != null:
return $default(_that.foreground,_that.underlays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@CanvasFillConverter()  CanvasFill foreground, @_CanvasSourceUnderlayJsonConverter()  List<CanvasSourceUnderlay> underlays)  $default,) {final _that = this;
switch (_that) {
case _CanvasAppearance():
return $default(_that.foreground,_that.underlays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@CanvasFillConverter()  CanvasFill foreground, @_CanvasSourceUnderlayJsonConverter()  List<CanvasSourceUnderlay> underlays)?  $default,) {final _that = this;
switch (_that) {
case _CanvasAppearance() when $default != null:
return $default(_that.foreground,_that.underlays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasAppearance implements CanvasAppearance {
  const _CanvasAppearance({@CanvasFillConverter() this.foreground = const CanvasFill.solid(0xFF111111), @_CanvasSourceUnderlayJsonConverter()  List<CanvasSourceUnderlay> underlays = const <CanvasSourceUnderlay>[]}): _underlays = underlays;
  factory _CanvasAppearance.fromJson(Map<String, dynamic> json) => _$CanvasAppearanceFromJson(json);

@override@JsonKey()@CanvasFillConverter() final  CanvasFill foreground;
 final  List<CanvasSourceUnderlay> _underlays;
@override@JsonKey()@_CanvasSourceUnderlayJsonConverter() List<CanvasSourceUnderlay> get underlays {
  if (_underlays is EqualUnmodifiableListView) return _underlays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_underlays);
}


/// Create a copy of CanvasAppearance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasAppearanceCopyWith<_CanvasAppearance> get copyWith => __$CanvasAppearanceCopyWithImpl<_CanvasAppearance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasAppearanceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasAppearance&&(identical(other.foreground, foreground) || other.foreground == foreground)&&const DeepCollectionEquality().equals(other.underlays, _underlays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,foreground,const DeepCollectionEquality().hash(_underlays));
}

@override
String toString() {
    return 'CanvasAppearance(foreground: $foreground, underlays: $underlays)';
}


}

/// @nodoc
abstract mixin class _$CanvasAppearanceCopyWith<$Res> implements $CanvasAppearanceCopyWith<$Res> {
  factory _$CanvasAppearanceCopyWith(_CanvasAppearance value, $Res Function(_CanvasAppearance) _then) = __$CanvasAppearanceCopyWithImpl;
@override @useResult
$Res call({
@CanvasFillConverter() CanvasFill foreground,@_CanvasSourceUnderlayJsonConverter() List<CanvasSourceUnderlay> underlays
});




}
/// @nodoc
class __$CanvasAppearanceCopyWithImpl<$Res>
    implements _$CanvasAppearanceCopyWith<$Res> {
  __$CanvasAppearanceCopyWithImpl(this._self, this._then);

  final _CanvasAppearance _self;
  final $Res Function(_CanvasAppearance) _then;

/// Create a copy of CanvasAppearance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foreground = null,Object? underlays = null,}) {
  return _then(_CanvasAppearance(
foreground: null == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as CanvasFill,underlays: null == underlays ? _self._underlays : underlays // ignore: cast_nullable_to_non_nullable
as List<CanvasSourceUnderlay>,
  ));
}


}

// dart format on
