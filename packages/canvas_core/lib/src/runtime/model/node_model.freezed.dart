// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transform2D {

@Vec2Converter() Vec2 get position; double get rotationRad;@Vec2Converter() Vec2 get scale; OriginKind get origin;@NullableVec2Converter() Vec2? get customPivotPx;
/// Create a copy of Transform2D
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Transform2DCopyWith<Transform2D> get copyWith => _$Transform2DCopyWithImpl<Transform2D>(this as Transform2D, _$identity);

  /// Serializes this Transform2D to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transform2D&&(identical(other.position, position) || other.position == position)&&(identical(other.rotationRad, rotationRad) || other.rotationRad == rotationRad)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.customPivotPx, customPivotPx) || other.customPivotPx == customPivotPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,rotationRad,scale,origin,customPivotPx);

@override
String toString() {
  return 'Transform2D(position: $position, rotationRad: $rotationRad, scale: $scale, origin: $origin, customPivotPx: $customPivotPx)';
}


}

/// @nodoc
abstract mixin class $Transform2DCopyWith<$Res>  {
  factory $Transform2DCopyWith(Transform2D value, $Res Function(Transform2D) _then) = _$Transform2DCopyWithImpl;
@useResult
$Res call({
@Vec2Converter() Vec2 position, double rotationRad,@Vec2Converter() Vec2 scale, OriginKind origin,@NullableVec2Converter() Vec2? customPivotPx
});




}
/// @nodoc
class _$Transform2DCopyWithImpl<$Res>
    implements $Transform2DCopyWith<$Res> {
  _$Transform2DCopyWithImpl(this._self, this._then);

  final Transform2D _self;
  final $Res Function(Transform2D) _then;

/// Create a copy of Transform2D
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? rotationRad = null,Object? scale = null,Object? origin = null,Object? customPivotPx = freezed,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Vec2,rotationRad: null == rotationRad ? _self.rotationRad : rotationRad // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as Vec2,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as OriginKind,customPivotPx: freezed == customPivotPx ? _self.customPivotPx : customPivotPx // ignore: cast_nullable_to_non_nullable
as Vec2?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transform2D].
extension Transform2DPatterns on Transform2D {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transform2D value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transform2D() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transform2D value)  $default,){
final _that = this;
switch (_that) {
case _Transform2D():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transform2D value)?  $default,){
final _that = this;
switch (_that) {
case _Transform2D() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@Vec2Converter()  Vec2 position,  double rotationRad, @Vec2Converter()  Vec2 scale,  OriginKind origin, @NullableVec2Converter()  Vec2? customPivotPx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transform2D() when $default != null:
return $default(_that.position,_that.rotationRad,_that.scale,_that.origin,_that.customPivotPx);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@Vec2Converter()  Vec2 position,  double rotationRad, @Vec2Converter()  Vec2 scale,  OriginKind origin, @NullableVec2Converter()  Vec2? customPivotPx)  $default,) {final _that = this;
switch (_that) {
case _Transform2D():
return $default(_that.position,_that.rotationRad,_that.scale,_that.origin,_that.customPivotPx);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@Vec2Converter()  Vec2 position,  double rotationRad, @Vec2Converter()  Vec2 scale,  OriginKind origin, @NullableVec2Converter()  Vec2? customPivotPx)?  $default,) {final _that = this;
switch (_that) {
case _Transform2D() when $default != null:
return $default(_that.position,_that.rotationRad,_that.scale,_that.origin,_that.customPivotPx);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transform2D implements Transform2D {
  const _Transform2D({@Vec2Converter() this.position = Vec2.zero, this.rotationRad = 0.0, @Vec2Converter() this.scale = const Vec2(1, 1), this.origin = OriginKind.center, @NullableVec2Converter() this.customPivotPx});
  factory _Transform2D.fromJson(Map<String, dynamic> json) => _$Transform2DFromJson(json);

@override@JsonKey()@Vec2Converter() final  Vec2 position;
@override@JsonKey() final  double rotationRad;
@override@JsonKey()@Vec2Converter() final  Vec2 scale;
@override@JsonKey() final  OriginKind origin;
@override@NullableVec2Converter() final  Vec2? customPivotPx;

/// Create a copy of Transform2D
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Transform2DCopyWith<_Transform2D> get copyWith => __$Transform2DCopyWithImpl<_Transform2D>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Transform2DToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transform2D&&(identical(other.position, position) || other.position == position)&&(identical(other.rotationRad, rotationRad) || other.rotationRad == rotationRad)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.customPivotPx, customPivotPx) || other.customPivotPx == customPivotPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,rotationRad,scale,origin,customPivotPx);

@override
String toString() {
  return 'Transform2D(position: $position, rotationRad: $rotationRad, scale: $scale, origin: $origin, customPivotPx: $customPivotPx)';
}


}

/// @nodoc
abstract mixin class _$Transform2DCopyWith<$Res> implements $Transform2DCopyWith<$Res> {
  factory _$Transform2DCopyWith(_Transform2D value, $Res Function(_Transform2D) _then) = __$Transform2DCopyWithImpl;
@override @useResult
$Res call({
@Vec2Converter() Vec2 position, double rotationRad,@Vec2Converter() Vec2 scale, OriginKind origin,@NullableVec2Converter() Vec2? customPivotPx
});




}
/// @nodoc
class __$Transform2DCopyWithImpl<$Res>
    implements _$Transform2DCopyWith<$Res> {
  __$Transform2DCopyWithImpl(this._self, this._then);

  final _Transform2D _self;
  final $Res Function(_Transform2D) _then;

/// Create a copy of Transform2D
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? rotationRad = null,Object? scale = null,Object? origin = null,Object? customPivotPx = freezed,}) {
  return _then(_Transform2D(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Vec2,rotationRad: null == rotationRad ? _self.rotationRad : rotationRad // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as Vec2,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as OriginKind,customPivotPx: freezed == customPivotPx ? _self.customPivotPx : customPivotPx // ignore: cast_nullable_to_non_nullable
as Vec2?,
  ));
}


}


/// @nodoc
mixin _$TextData {

 String get text; String get fontFamily; FontWeightNum get fontWeight; double get fontSize; int get letterSpacing;@CanvasFillConverter() CanvasFill get fill; double get shadowOffset;
/// Create a copy of TextData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDataCopyWith<TextData> get copyWith => _$TextDataCopyWithImpl<TextData>(this as TextData, _$identity);

  /// Serializes this TextData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextData&&(identical(other.text, text) || other.text == text)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.shadowOffset, shadowOffset) || other.shadowOffset == shadowOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fontFamily,fontWeight,fontSize,letterSpacing,fill,shadowOffset);

@override
String toString() {
  return 'TextData(text: $text, fontFamily: $fontFamily, fontWeight: $fontWeight, fontSize: $fontSize, letterSpacing: $letterSpacing, fill: $fill, shadowOffset: $shadowOffset)';
}


}

/// @nodoc
abstract mixin class $TextDataCopyWith<$Res>  {
  factory $TextDataCopyWith(TextData value, $Res Function(TextData) _then) = _$TextDataCopyWithImpl;
@useResult
$Res call({
 String text, String fontFamily, FontWeightNum fontWeight, double fontSize, int letterSpacing,@CanvasFillConverter() CanvasFill fill, double shadowOffset
});




}
/// @nodoc
class _$TextDataCopyWithImpl<$Res>
    implements $TextDataCopyWith<$Res> {
  _$TextDataCopyWithImpl(this._self, this._then);

  final TextData _self;
  final $Res Function(TextData) _then;

/// Create a copy of TextData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? fontFamily = null,Object? fontWeight = null,Object? fontSize = null,Object? letterSpacing = null,Object? fill = null,Object? shadowOffset = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as FontWeightNum,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as int,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,shadowOffset: null == shadowOffset ? _self.shadowOffset : shadowOffset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TextData].
extension TextDataPatterns on TextData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TextData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TextData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TextData value)  $default,){
final _that = this;
switch (_that) {
case _TextData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TextData value)?  $default,){
final _that = this;
switch (_that) {
case _TextData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize,  int letterSpacing, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TextData() when $default != null:
return $default(_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.fill,_that.shadowOffset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize,  int letterSpacing, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)  $default,) {final _that = this;
switch (_that) {
case _TextData():
return $default(_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.fill,_that.shadowOffset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String fontFamily,  FontWeightNum fontWeight,  double fontSize,  int letterSpacing, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)?  $default,) {final _that = this;
switch (_that) {
case _TextData() when $default != null:
return $default(_that.text,_that.fontFamily,_that.fontWeight,_that.fontSize,_that.letterSpacing,_that.fill,_that.shadowOffset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TextData extends TextData {
  const _TextData({required this.text, required this.fontFamily, required this.fontWeight, required this.fontSize, this.letterSpacing = 0, @CanvasFillConverter() this.fill = const CanvasFill.solid(0xFF111111), this.shadowOffset = 0}): assert(fill is! CanvasFillNone, 'Text fill cannot be none'),super._();
  factory _TextData.fromJson(Map<String, dynamic> json) => _$TextDataFromJson(json);

@override final  String text;
@override final  String fontFamily;
@override final  FontWeightNum fontWeight;
@override final  double fontSize;
@override@JsonKey() final  int letterSpacing;
@override@JsonKey()@CanvasFillConverter() final  CanvasFill fill;
@override@JsonKey() final  double shadowOffset;

/// Create a copy of TextData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextDataCopyWith<_TextData> get copyWith => __$TextDataCopyWithImpl<_TextData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextData&&(identical(other.text, text) || other.text == text)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.shadowOffset, shadowOffset) || other.shadowOffset == shadowOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fontFamily,fontWeight,fontSize,letterSpacing,fill,shadowOffset);

@override
String toString() {
  return 'TextData(text: $text, fontFamily: $fontFamily, fontWeight: $fontWeight, fontSize: $fontSize, letterSpacing: $letterSpacing, fill: $fill, shadowOffset: $shadowOffset)';
}


}

/// @nodoc
abstract mixin class _$TextDataCopyWith<$Res> implements $TextDataCopyWith<$Res> {
  factory _$TextDataCopyWith(_TextData value, $Res Function(_TextData) _then) = __$TextDataCopyWithImpl;
@override @useResult
$Res call({
 String text, String fontFamily, FontWeightNum fontWeight, double fontSize, int letterSpacing,@CanvasFillConverter() CanvasFill fill, double shadowOffset
});




}
/// @nodoc
class __$TextDataCopyWithImpl<$Res>
    implements _$TextDataCopyWith<$Res> {
  __$TextDataCopyWithImpl(this._self, this._then);

  final _TextData _self;
  final $Res Function(_TextData) _then;

/// Create a copy of TextData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? fontFamily = null,Object? fontWeight = null,Object? fontSize = null,Object? letterSpacing = null,Object? fill = null,Object? shadowOffset = null,}) {
  return _then(_TextData(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as FontWeightNum,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as int,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,shadowOffset: null == shadowOffset ? _self.shadowOffset : shadowOffset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ImageData {

@NullableSize2DConverter() Size2D? get size; String? get sourcePath; ImageFit get fit;@Vec2Converter() Vec2 get align;
/// Create a copy of ImageData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageDataCopyWith<ImageData> get copyWith => _$ImageDataCopyWithImpl<ImageData>(this as ImageData, _$identity);

  /// Serializes this ImageData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageData&&(identical(other.size, size) || other.size == size)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.fit, fit) || other.fit == fit)&&(identical(other.align, align) || other.align == align));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,size,sourcePath,fit,align);

@override
String toString() {
  return 'ImageData(size: $size, sourcePath: $sourcePath, fit: $fit, align: $align)';
}


}

/// @nodoc
abstract mixin class $ImageDataCopyWith<$Res>  {
  factory $ImageDataCopyWith(ImageData value, $Res Function(ImageData) _then) = _$ImageDataCopyWithImpl;
@useResult
$Res call({
@NullableSize2DConverter() Size2D? size, String? sourcePath, ImageFit fit,@Vec2Converter() Vec2 align
});




}
/// @nodoc
class _$ImageDataCopyWithImpl<$Res>
    implements $ImageDataCopyWith<$Res> {
  _$ImageDataCopyWithImpl(this._self, this._then);

  final ImageData _self;
  final $Res Function(ImageData) _then;

/// Create a copy of ImageData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? size = freezed,Object? sourcePath = freezed,Object? fit = null,Object? align = null,}) {
  return _then(_self.copyWith(
size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Size2D?,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String?,fit: null == fit ? _self.fit : fit // ignore: cast_nullable_to_non_nullable
as ImageFit,align: null == align ? _self.align : align // ignore: cast_nullable_to_non_nullable
as Vec2,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageData].
extension ImageDataPatterns on ImageData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageData value)  $default,){
final _that = this;
switch (_that) {
case _ImageData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageData value)?  $default,){
final _that = this;
switch (_that) {
case _ImageData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@NullableSize2DConverter()  Size2D? size,  String? sourcePath,  ImageFit fit, @Vec2Converter()  Vec2 align)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageData() when $default != null:
return $default(_that.size,_that.sourcePath,_that.fit,_that.align);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@NullableSize2DConverter()  Size2D? size,  String? sourcePath,  ImageFit fit, @Vec2Converter()  Vec2 align)  $default,) {final _that = this;
switch (_that) {
case _ImageData():
return $default(_that.size,_that.sourcePath,_that.fit,_that.align);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@NullableSize2DConverter()  Size2D? size,  String? sourcePath,  ImageFit fit, @Vec2Converter()  Vec2 align)?  $default,) {final _that = this;
switch (_that) {
case _ImageData() when $default != null:
return $default(_that.size,_that.sourcePath,_that.fit,_that.align);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageData implements ImageData {
  const _ImageData({@NullableSize2DConverter() this.size, this.sourcePath, this.fit = ImageFit.contain, @Vec2Converter() this.align = const Vec2(0.5, 0.5)});
  factory _ImageData.fromJson(Map<String, dynamic> json) => _$ImageDataFromJson(json);

@override@NullableSize2DConverter() final  Size2D? size;
@override final  String? sourcePath;
@override@JsonKey() final  ImageFit fit;
@override@JsonKey()@Vec2Converter() final  Vec2 align;

/// Create a copy of ImageData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageDataCopyWith<_ImageData> get copyWith => __$ImageDataCopyWithImpl<_ImageData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageData&&(identical(other.size, size) || other.size == size)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.fit, fit) || other.fit == fit)&&(identical(other.align, align) || other.align == align));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,size,sourcePath,fit,align);

@override
String toString() {
  return 'ImageData(size: $size, sourcePath: $sourcePath, fit: $fit, align: $align)';
}


}

/// @nodoc
abstract mixin class _$ImageDataCopyWith<$Res> implements $ImageDataCopyWith<$Res> {
  factory _$ImageDataCopyWith(_ImageData value, $Res Function(_ImageData) _then) = __$ImageDataCopyWithImpl;
@override @useResult
$Res call({
@NullableSize2DConverter() Size2D? size, String? sourcePath, ImageFit fit,@Vec2Converter() Vec2 align
});




}
/// @nodoc
class __$ImageDataCopyWithImpl<$Res>
    implements _$ImageDataCopyWith<$Res> {
  __$ImageDataCopyWithImpl(this._self, this._then);

  final _ImageData _self;
  final $Res Function(_ImageData) _then;

/// Create a copy of ImageData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? size = freezed,Object? sourcePath = freezed,Object? fit = null,Object? align = null,}) {
  return _then(_ImageData(
size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Size2D?,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String?,fit: null == fit ? _self.fit : fit // ignore: cast_nullable_to_non_nullable
as ImageFit,align: null == align ? _self.align : align // ignore: cast_nullable_to_non_nullable
as Vec2,
  ));
}


}


/// @nodoc
mixin _$PathData {

@Vec2ListNullableConverter() List<Vec2?> get points;@PathSourceConverter() PathSource? get source;@CanvasFillConverter() CanvasFill get fill; FillRule get fillRule; Color32 get strokeColor; double get strokeWidth; StrokeCap get strokeCap; StrokeJoin get strokeJoin; double get miterLimit; List<double> get dash;
/// Create a copy of PathData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathDataCopyWith<PathData> get copyWith => _$PathDataCopyWithImpl<PathData>(this as PathData, _$identity);

  /// Serializes this PathData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathData&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.source, source) || other.source == source)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.fillRule, fillRule) || other.fillRule == fillRule)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.strokeCap, strokeCap) || other.strokeCap == strokeCap)&&(identical(other.strokeJoin, strokeJoin) || other.strokeJoin == strokeJoin)&&(identical(other.miterLimit, miterLimit) || other.miterLimit == miterLimit)&&const DeepCollectionEquality().equals(other.dash, dash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(points),source,fill,fillRule,strokeColor,strokeWidth,strokeCap,strokeJoin,miterLimit,const DeepCollectionEquality().hash(dash));

@override
String toString() {
  return 'PathData(points: $points, source: $source, fill: $fill, fillRule: $fillRule, strokeColor: $strokeColor, strokeWidth: $strokeWidth, strokeCap: $strokeCap, strokeJoin: $strokeJoin, miterLimit: $miterLimit, dash: $dash)';
}


}

/// @nodoc
abstract mixin class $PathDataCopyWith<$Res>  {
  factory $PathDataCopyWith(PathData value, $Res Function(PathData) _then) = _$PathDataCopyWithImpl;
@useResult
$Res call({
@Vec2ListNullableConverter() List<Vec2?> points,@PathSourceConverter() PathSource? source,@CanvasFillConverter() CanvasFill fill, FillRule fillRule, Color32 strokeColor, double strokeWidth, StrokeCap strokeCap, StrokeJoin strokeJoin, double miterLimit, List<double> dash
});




}
/// @nodoc
class _$PathDataCopyWithImpl<$Res>
    implements $PathDataCopyWith<$Res> {
  _$PathDataCopyWithImpl(this._self, this._then);

  final PathData _self;
  final $Res Function(PathData) _then;

/// Create a copy of PathData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,Object? source = freezed,Object? fill = null,Object? fillRule = null,Object? strokeColor = null,Object? strokeWidth = null,Object? strokeCap = null,Object? strokeJoin = null,Object? miterLimit = null,Object? dash = null,}) {
  return _then(_self.copyWith(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<Vec2?>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PathSource?,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,fillRule: null == fillRule ? _self.fillRule : fillRule // ignore: cast_nullable_to_non_nullable
as FillRule,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as Color32,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,strokeCap: null == strokeCap ? _self.strokeCap : strokeCap // ignore: cast_nullable_to_non_nullable
as StrokeCap,strokeJoin: null == strokeJoin ? _self.strokeJoin : strokeJoin // ignore: cast_nullable_to_non_nullable
as StrokeJoin,miterLimit: null == miterLimit ? _self.miterLimit : miterLimit // ignore: cast_nullable_to_non_nullable
as double,dash: null == dash ? _self.dash : dash // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [PathData].
extension PathDataPatterns on PathData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathData value)  $default,){
final _that = this;
switch (_that) {
case _PathData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathData value)?  $default,){
final _that = this;
switch (_that) {
case _PathData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@Vec2ListNullableConverter()  List<Vec2?> points, @PathSourceConverter()  PathSource? source, @CanvasFillConverter()  CanvasFill fill,  FillRule fillRule,  Color32 strokeColor,  double strokeWidth,  StrokeCap strokeCap,  StrokeJoin strokeJoin,  double miterLimit,  List<double> dash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathData() when $default != null:
return $default(_that.points,_that.source,_that.fill,_that.fillRule,_that.strokeColor,_that.strokeWidth,_that.strokeCap,_that.strokeJoin,_that.miterLimit,_that.dash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@Vec2ListNullableConverter()  List<Vec2?> points, @PathSourceConverter()  PathSource? source, @CanvasFillConverter()  CanvasFill fill,  FillRule fillRule,  Color32 strokeColor,  double strokeWidth,  StrokeCap strokeCap,  StrokeJoin strokeJoin,  double miterLimit,  List<double> dash)  $default,) {final _that = this;
switch (_that) {
case _PathData():
return $default(_that.points,_that.source,_that.fill,_that.fillRule,_that.strokeColor,_that.strokeWidth,_that.strokeCap,_that.strokeJoin,_that.miterLimit,_that.dash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@Vec2ListNullableConverter()  List<Vec2?> points, @PathSourceConverter()  PathSource? source, @CanvasFillConverter()  CanvasFill fill,  FillRule fillRule,  Color32 strokeColor,  double strokeWidth,  StrokeCap strokeCap,  StrokeJoin strokeJoin,  double miterLimit,  List<double> dash)?  $default,) {final _that = this;
switch (_that) {
case _PathData() when $default != null:
return $default(_that.points,_that.source,_that.fill,_that.fillRule,_that.strokeColor,_that.strokeWidth,_that.strokeCap,_that.strokeJoin,_that.miterLimit,_that.dash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathData implements PathData {
  const _PathData({@Vec2ListNullableConverter() final  List<Vec2?> points = const <Vec2?>[], @PathSourceConverter() this.source, @CanvasFillConverter() this.fill = const CanvasFillNone(), this.fillRule = FillRule.nonZero, this.strokeColor = 0x00000000, this.strokeWidth = 4.0, this.strokeCap = StrokeCap.butt, this.strokeJoin = StrokeJoin.miter, this.miterLimit = 4.0, final  List<double> dash = const <double>[]}): _points = points,_dash = dash;
  factory _PathData.fromJson(Map<String, dynamic> json) => _$PathDataFromJson(json);

 final  List<Vec2?> _points;
@override@JsonKey()@Vec2ListNullableConverter() List<Vec2?> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

@override@PathSourceConverter() final  PathSource? source;
@override@JsonKey()@CanvasFillConverter() final  CanvasFill fill;
@override@JsonKey() final  FillRule fillRule;
@override@JsonKey() final  Color32 strokeColor;
@override@JsonKey() final  double strokeWidth;
@override@JsonKey() final  StrokeCap strokeCap;
@override@JsonKey() final  StrokeJoin strokeJoin;
@override@JsonKey() final  double miterLimit;
 final  List<double> _dash;
@override@JsonKey() List<double> get dash {
  if (_dash is EqualUnmodifiableListView) return _dash;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dash);
}


/// Create a copy of PathData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathDataCopyWith<_PathData> get copyWith => __$PathDataCopyWithImpl<_PathData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathData&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.source, source) || other.source == source)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.fillRule, fillRule) || other.fillRule == fillRule)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.strokeCap, strokeCap) || other.strokeCap == strokeCap)&&(identical(other.strokeJoin, strokeJoin) || other.strokeJoin == strokeJoin)&&(identical(other.miterLimit, miterLimit) || other.miterLimit == miterLimit)&&const DeepCollectionEquality().equals(other._dash, _dash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_points),source,fill,fillRule,strokeColor,strokeWidth,strokeCap,strokeJoin,miterLimit,const DeepCollectionEquality().hash(_dash));

@override
String toString() {
  return 'PathData(points: $points, source: $source, fill: $fill, fillRule: $fillRule, strokeColor: $strokeColor, strokeWidth: $strokeWidth, strokeCap: $strokeCap, strokeJoin: $strokeJoin, miterLimit: $miterLimit, dash: $dash)';
}


}

/// @nodoc
abstract mixin class _$PathDataCopyWith<$Res> implements $PathDataCopyWith<$Res> {
  factory _$PathDataCopyWith(_PathData value, $Res Function(_PathData) _then) = __$PathDataCopyWithImpl;
@override @useResult
$Res call({
@Vec2ListNullableConverter() List<Vec2?> points,@PathSourceConverter() PathSource? source,@CanvasFillConverter() CanvasFill fill, FillRule fillRule, Color32 strokeColor, double strokeWidth, StrokeCap strokeCap, StrokeJoin strokeJoin, double miterLimit, List<double> dash
});




}
/// @nodoc
class __$PathDataCopyWithImpl<$Res>
    implements _$PathDataCopyWith<$Res> {
  __$PathDataCopyWithImpl(this._self, this._then);

  final _PathData _self;
  final $Res Function(_PathData) _then;

/// Create a copy of PathData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,Object? source = freezed,Object? fill = null,Object? fillRule = null,Object? strokeColor = null,Object? strokeWidth = null,Object? strokeCap = null,Object? strokeJoin = null,Object? miterLimit = null,Object? dash = null,}) {
  return _then(_PathData(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<Vec2?>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PathSource?,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,fillRule: null == fillRule ? _self.fillRule : fillRule // ignore: cast_nullable_to_non_nullable
as FillRule,strokeColor: null == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as Color32,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,strokeCap: null == strokeCap ? _self.strokeCap : strokeCap // ignore: cast_nullable_to_non_nullable
as StrokeCap,strokeJoin: null == strokeJoin ? _self.strokeJoin : strokeJoin // ignore: cast_nullable_to_non_nullable
as StrokeJoin,miterLimit: null == miterLimit ? _self.miterLimit : miterLimit // ignore: cast_nullable_to_non_nullable
as double,dash: null == dash ? _self._dash : dash // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}


/// @nodoc
mixin _$CanvasIconData {

 String get iconRef; double get sizePx;@CanvasFillConverter() CanvasFill get fill; double get shadowOffset;
/// Create a copy of CanvasIconData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasIconDataCopyWith<CanvasIconData> get copyWith => _$CanvasIconDataCopyWithImpl<CanvasIconData>(this as CanvasIconData, _$identity);

  /// Serializes this CanvasIconData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasIconData&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.sizePx, sizePx) || other.sizePx == sizePx)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.shadowOffset, shadowOffset) || other.shadowOffset == shadowOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconRef,sizePx,fill,shadowOffset);

@override
String toString() {
  return 'CanvasIconData(iconRef: $iconRef, sizePx: $sizePx, fill: $fill, shadowOffset: $shadowOffset)';
}


}

/// @nodoc
abstract mixin class $CanvasIconDataCopyWith<$Res>  {
  factory $CanvasIconDataCopyWith(CanvasIconData value, $Res Function(CanvasIconData) _then) = _$CanvasIconDataCopyWithImpl;
@useResult
$Res call({
 String iconRef, double sizePx,@CanvasFillConverter() CanvasFill fill, double shadowOffset
});




}
/// @nodoc
class _$CanvasIconDataCopyWithImpl<$Res>
    implements $CanvasIconDataCopyWith<$Res> {
  _$CanvasIconDataCopyWithImpl(this._self, this._then);

  final CanvasIconData _self;
  final $Res Function(CanvasIconData) _then;

/// Create a copy of CanvasIconData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? iconRef = null,Object? sizePx = null,Object? fill = null,Object? shadowOffset = null,}) {
  return _then(_self.copyWith(
iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,sizePx: null == sizePx ? _self.sizePx : sizePx // ignore: cast_nullable_to_non_nullable
as double,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,shadowOffset: null == shadowOffset ? _self.shadowOffset : shadowOffset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasIconData].
extension CanvasIconDataPatterns on CanvasIconData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasIconData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasIconData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasIconData value)  $default,){
final _that = this;
switch (_that) {
case _CanvasIconData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasIconData value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasIconData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String iconRef,  double sizePx, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasIconData() when $default != null:
return $default(_that.iconRef,_that.sizePx,_that.fill,_that.shadowOffset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String iconRef,  double sizePx, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)  $default,) {final _that = this;
switch (_that) {
case _CanvasIconData():
return $default(_that.iconRef,_that.sizePx,_that.fill,_that.shadowOffset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String iconRef,  double sizePx, @CanvasFillConverter()  CanvasFill fill,  double shadowOffset)?  $default,) {final _that = this;
switch (_that) {
case _CanvasIconData() when $default != null:
return $default(_that.iconRef,_that.sizePx,_that.fill,_that.shadowOffset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasIconData extends CanvasIconData {
  const _CanvasIconData({required this.iconRef, this.sizePx = 96.0, @CanvasFillConverter() this.fill = const CanvasFill.solid(0xFF111111), this.shadowOffset = 0}): assert(fill is! CanvasFillNone, 'Icon fill cannot be none'),super._();
  factory _CanvasIconData.fromJson(Map<String, dynamic> json) => _$CanvasIconDataFromJson(json);

@override final  String iconRef;
@override@JsonKey() final  double sizePx;
@override@JsonKey()@CanvasFillConverter() final  CanvasFill fill;
@override@JsonKey() final  double shadowOffset;

/// Create a copy of CanvasIconData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasIconDataCopyWith<_CanvasIconData> get copyWith => __$CanvasIconDataCopyWithImpl<_CanvasIconData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasIconDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasIconData&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.sizePx, sizePx) || other.sizePx == sizePx)&&(identical(other.fill, fill) || other.fill == fill)&&(identical(other.shadowOffset, shadowOffset) || other.shadowOffset == shadowOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconRef,sizePx,fill,shadowOffset);

@override
String toString() {
  return 'CanvasIconData(iconRef: $iconRef, sizePx: $sizePx, fill: $fill, shadowOffset: $shadowOffset)';
}


}

/// @nodoc
abstract mixin class _$CanvasIconDataCopyWith<$Res> implements $CanvasIconDataCopyWith<$Res> {
  factory _$CanvasIconDataCopyWith(_CanvasIconData value, $Res Function(_CanvasIconData) _then) = __$CanvasIconDataCopyWithImpl;
@override @useResult
$Res call({
 String iconRef, double sizePx,@CanvasFillConverter() CanvasFill fill, double shadowOffset
});




}
/// @nodoc
class __$CanvasIconDataCopyWithImpl<$Res>
    implements _$CanvasIconDataCopyWith<$Res> {
  __$CanvasIconDataCopyWithImpl(this._self, this._then);

  final _CanvasIconData _self;
  final $Res Function(_CanvasIconData) _then;

/// Create a copy of CanvasIconData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? iconRef = null,Object? sizePx = null,Object? fill = null,Object? shadowOffset = null,}) {
  return _then(_CanvasIconData(
iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,sizePx: null == sizePx ? _self.sizePx : sizePx // ignore: cast_nullable_to_non_nullable
as double,fill: null == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as CanvasFill,shadowOffset: null == shadowOffset ? _self.shadowOffset : shadowOffset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupBehaviorRef&&(identical(other.type, type) || other.type == type)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,version,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'GroupBehaviorRef(type: $type, version: $version, data: $data)';
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
  return _then(_self.copyWith(
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
  const _GroupBehaviorRef({required this.type, this.version = 1, final  Map<String, dynamic> data = const <String, dynamic>{}}): _data = data;
  factory _GroupBehaviorRef.fromJson(Map<String, dynamic> json) => _$GroupBehaviorRefFromJson(json);

@override final  String type;
@override@JsonKey() final  int version;
 final  Map<String, dynamic> _data;
@override@JsonKey() Map<String, dynamic> get data {
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupBehaviorRef&&(identical(other.type, type) || other.type == type)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,version,const DeepCollectionEquality().hash(_data));

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
        switch (json['runtimeType']) {
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
  'runtimeType',
  'Node',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Node {

 NodeId get id; String? get name; bool get hidden; bool get locked; Transform2D get xf;
/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeCopyWith<Node> get copyWith => _$NodeCopyWithImpl<Node>(this as Node, _$identity);

  /// Serializes this Node to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Node&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf);

@override
String toString() {
  return 'Node(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf)';
}


}

/// @nodoc
abstract mixin class $NodeCopyWith<$Res>  {
  factory $NodeCopyWith(Node value, $Res Function(Node) _then) = _$NodeCopyWithImpl;
@useResult
$Res call({
 String id, String? name, bool hidden, bool locked, Transform2D xf
});


$Transform2DCopyWith<$Res> get xf;

}
/// @nodoc
class _$NodeCopyWithImpl<$Res>
    implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._self, this._then);

  final Node _self;
  final $Res Function(Node) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,
  ));
}
/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  TextData data,  String? role)?  text,TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  ImageData data,  String? role)?  image,TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  PathData data,  String? role)?  path,TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  CanvasIconData data,  String? role)?  icon,TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  GroupBehaviorRef? behavior,  List<Node> children)?  group,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case PathNode() when path != null:
return path(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.behavior,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  TextData data,  String? role)  text,required TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  ImageData data,  String? role)  image,required TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  PathData data,  String? role)  path,required TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  CanvasIconData data,  String? role)  icon,required TResult Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  GroupBehaviorRef? behavior,  List<Node> children)  group,}) {final _that = this;
switch (_that) {
case TextNode():
return text(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case ImageNode():
return image(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case PathNode():
return path(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case IconNode():
return icon(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case GroupNode():
return group(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.behavior,_that.children);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  TextData data,  String? role)?  text,TResult? Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  ImageData data,  String? role)?  image,TResult? Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  PathData data,  String? role)?  path,TResult? Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  CanvasIconData data,  String? role)?  icon,TResult? Function( NodeId id,  String? name,  bool hidden,  bool locked,  Transform2D xf,  GroupBehaviorRef? behavior,  List<Node> children)?  group,}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case ImageNode() when image != null:
return image(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case PathNode() when path != null:
return path(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case IconNode() when icon != null:
return icon(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.data,_that.role);case GroupNode() when group != null:
return group(_that.id,_that.name,_that.hidden,_that.locked,_that.xf,_that.behavior,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextNode extends Node {
  const TextNode({required this.id, this.name, this.hidden = false, this.locked = false, this.xf = const Transform2D(), required this.data, this.role, final  String? $type}): $type = $type ?? 'text',super._();
  factory TextNode.fromJson(Map<String, dynamic> json) => _$TextNodeFromJson(json);

@override final  NodeId id;
@override final  String? name;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  bool locked;
@override@JsonKey() final  Transform2D xf;
 final  TextData data;
 final  String? role;

@JsonKey(name: 'runtimeType')
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.data, data) || other.data == data)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf,data,role);

@override
String toString() {
  return 'Node.text(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf, data: $data, role: $role)';
}


}

/// @nodoc
abstract mixin class $TextNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $TextNodeCopyWith(TextNode value, $Res Function(TextNode) _then) = _$TextNodeCopyWithImpl;
@override @useResult
$Res call({
 NodeId id, String? name, bool hidden, bool locked, Transform2D xf, TextData data, String? role
});


@override $Transform2DCopyWith<$Res> get xf;$TextDataCopyWith<$Res> get data;

}
/// @nodoc
class _$TextNodeCopyWithImpl<$Res>
    implements $TextNodeCopyWith<$Res> {
  _$TextNodeCopyWithImpl(this._self, this._then);

  final TextNode _self;
  final $Res Function(TextNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,Object? data = null,Object? role = freezed,}) {
  return _then(TextNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as NodeId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as TextData,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
}/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextDataCopyWith<$Res> get data {
  
  return $TextDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ImageNode extends Node {
  const ImageNode({required this.id, this.name, this.hidden = false, this.locked = false, this.xf = const Transform2D(), required this.data, this.role, final  String? $type}): $type = $type ?? 'image',super._();
  factory ImageNode.fromJson(Map<String, dynamic> json) => _$ImageNodeFromJson(json);

@override final  NodeId id;
@override final  String? name;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  bool locked;
@override@JsonKey() final  Transform2D xf;
 final  ImageData data;
 final  String? role;

@JsonKey(name: 'runtimeType')
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.data, data) || other.data == data)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf,data,role);

@override
String toString() {
  return 'Node.image(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf, data: $data, role: $role)';
}


}

/// @nodoc
abstract mixin class $ImageNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $ImageNodeCopyWith(ImageNode value, $Res Function(ImageNode) _then) = _$ImageNodeCopyWithImpl;
@override @useResult
$Res call({
 NodeId id, String? name, bool hidden, bool locked, Transform2D xf, ImageData data, String? role
});


@override $Transform2DCopyWith<$Res> get xf;$ImageDataCopyWith<$Res> get data;

}
/// @nodoc
class _$ImageNodeCopyWithImpl<$Res>
    implements $ImageNodeCopyWith<$Res> {
  _$ImageNodeCopyWithImpl(this._self, this._then);

  final ImageNode _self;
  final $Res Function(ImageNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,Object? data = null,Object? role = freezed,}) {
  return _then(ImageNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as NodeId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as ImageData,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
}/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageDataCopyWith<$Res> get data {
  
  return $ImageDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PathNode extends Node {
  const PathNode({required this.id, this.name, this.hidden = false, this.locked = false, this.xf = const Transform2D(), required this.data, this.role, final  String? $type}): $type = $type ?? 'path',super._();
  factory PathNode.fromJson(Map<String, dynamic> json) => _$PathNodeFromJson(json);

@override final  NodeId id;
@override final  String? name;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  bool locked;
@override@JsonKey() final  Transform2D xf;
 final  PathData data;
 final  String? role;

@JsonKey(name: 'runtimeType')
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.data, data) || other.data == data)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf,data,role);

@override
String toString() {
  return 'Node.path(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf, data: $data, role: $role)';
}


}

/// @nodoc
abstract mixin class $PathNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $PathNodeCopyWith(PathNode value, $Res Function(PathNode) _then) = _$PathNodeCopyWithImpl;
@override @useResult
$Res call({
 NodeId id, String? name, bool hidden, bool locked, Transform2D xf, PathData data, String? role
});


@override $Transform2DCopyWith<$Res> get xf;$PathDataCopyWith<$Res> get data;

}
/// @nodoc
class _$PathNodeCopyWithImpl<$Res>
    implements $PathNodeCopyWith<$Res> {
  _$PathNodeCopyWithImpl(this._self, this._then);

  final PathNode _self;
  final $Res Function(PathNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,Object? data = null,Object? role = freezed,}) {
  return _then(PathNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as NodeId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as PathData,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
}/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathDataCopyWith<$Res> get data {
  
  return $PathDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class IconNode extends Node {
  const IconNode({required this.id, this.name, this.hidden = false, this.locked = false, this.xf = const Transform2D(), required this.data, this.role, final  String? $type}): $type = $type ?? 'icon',super._();
  factory IconNode.fromJson(Map<String, dynamic> json) => _$IconNodeFromJson(json);

@override final  NodeId id;
@override final  String? name;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  bool locked;
@override@JsonKey() final  Transform2D xf;
 final  CanvasIconData data;
 final  String? role;

@JsonKey(name: 'runtimeType')
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.data, data) || other.data == data)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf,data,role);

@override
String toString() {
  return 'Node.icon(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf, data: $data, role: $role)';
}


}

/// @nodoc
abstract mixin class $IconNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $IconNodeCopyWith(IconNode value, $Res Function(IconNode) _then) = _$IconNodeCopyWithImpl;
@override @useResult
$Res call({
 NodeId id, String? name, bool hidden, bool locked, Transform2D xf, CanvasIconData data, String? role
});


@override $Transform2DCopyWith<$Res> get xf;$CanvasIconDataCopyWith<$Res> get data;

}
/// @nodoc
class _$IconNodeCopyWithImpl<$Res>
    implements $IconNodeCopyWith<$Res> {
  _$IconNodeCopyWithImpl(this._self, this._then);

  final IconNode _self;
  final $Res Function(IconNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,Object? data = null,Object? role = freezed,}) {
  return _then(IconNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as NodeId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CanvasIconData,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
}/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasIconDataCopyWith<$Res> get data {
  
  return $CanvasIconDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class GroupNode extends Node {
  const GroupNode({required this.id, this.name, this.hidden = false, this.locked = false, this.xf = const Transform2D(), this.behavior, final  List<Node> children = const <Node>[], final  String? $type}): _children = children,$type = $type ?? 'group',super._();
  factory GroupNode.fromJson(Map<String, dynamic> json) => _$GroupNodeFromJson(json);

@override final  NodeId id;
@override final  String? name;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  bool locked;
@override@JsonKey() final  Transform2D xf;
 final  GroupBehaviorRef? behavior;
 final  List<Node> _children;
@JsonKey() List<Node> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


@JsonKey(name: 'runtimeType')
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.xf, xf) || other.xf == xf)&&(identical(other.behavior, behavior) || other.behavior == behavior)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hidden,locked,xf,behavior,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'Node.group(id: $id, name: $name, hidden: $hidden, locked: $locked, xf: $xf, behavior: $behavior, children: $children)';
}


}

/// @nodoc
abstract mixin class $GroupNodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory $GroupNodeCopyWith(GroupNode value, $Res Function(GroupNode) _then) = _$GroupNodeCopyWithImpl;
@override @useResult
$Res call({
 NodeId id, String? name, bool hidden, bool locked, Transform2D xf, GroupBehaviorRef? behavior, List<Node> children
});


@override $Transform2DCopyWith<$Res> get xf;$GroupBehaviorRefCopyWith<$Res>? get behavior;

}
/// @nodoc
class _$GroupNodeCopyWithImpl<$Res>
    implements $GroupNodeCopyWith<$Res> {
  _$GroupNodeCopyWithImpl(this._self, this._then);

  final GroupNode _self;
  final $Res Function(GroupNode) _then;

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hidden = null,Object? locked = null,Object? xf = null,Object? behavior = freezed,Object? children = null,}) {
  return _then(GroupNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as NodeId,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,xf: null == xf ? _self.xf : xf // ignore: cast_nullable_to_non_nullable
as Transform2D,behavior: freezed == behavior ? _self.behavior : behavior // ignore: cast_nullable_to_non_nullable
as GroupBehaviorRef?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<Node>,
  ));
}

/// Create a copy of Node
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Transform2DCopyWith<$Res> get xf {
  
  return $Transform2DCopyWith<$Res>(_self.xf, (value) {
    return _then(_self.copyWith(xf: value));
  });
}/// Create a copy of Node
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
