// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PackingListEntryCondition {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PackingListEntryConditionCopyWith<$Res> {
  factory $PackingListEntryConditionCopyWith(PackingListEntryCondition value,
          $Res Function(PackingListEntryCondition) then) =
      _$PackingListEntryConditionCopyWithImpl<$Res, PackingListEntryCondition>;
}

/// @nodoc
class _$PackingListEntryConditionCopyWithImpl<$Res,
        $Val extends PackingListEntryCondition>
    implements $PackingListEntryConditionCopyWith<$Res> {
  _$PackingListEntryConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MinTripDurationImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MinTripDurationImplCopyWith(
          _$PackingListEntryCondition_MinTripDurationImpl value,
          $Res Function(_$PackingListEntryCondition_MinTripDurationImpl) then) =
      __$$PackingListEntryCondition_MinTripDurationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int length});
}

/// @nodoc
class __$$PackingListEntryCondition_MinTripDurationImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MinTripDurationImpl>
    implements _$$PackingListEntryCondition_MinTripDurationImplCopyWith<$Res> {
  __$$PackingListEntryCondition_MinTripDurationImplCopyWithImpl(
      _$PackingListEntryCondition_MinTripDurationImpl _value,
      $Res Function(_$PackingListEntryCondition_MinTripDurationImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
  }) {
    return _then(_$PackingListEntryCondition_MinTripDurationImpl(
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MinTripDurationImpl
    extends PackingListEntryCondition_MinTripDuration {
  const _$PackingListEntryCondition_MinTripDurationImpl({required this.length})
      : super._();

  @override
  final int length;

  @override
  String toString() {
    return 'PackingListEntryCondition.minTripDuration(length: $length)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MinTripDurationImpl &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(runtimeType, length);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MinTripDurationImplCopyWith<
          _$PackingListEntryCondition_MinTripDurationImpl>
      get copyWith =>
          __$$PackingListEntryCondition_MinTripDurationImplCopyWithImpl<
                  _$PackingListEntryCondition_MinTripDurationImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return minTripDuration(length);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return minTripDuration?.call(length);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (minTripDuration != null) {
      return minTripDuration(length);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return minTripDuration(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return minTripDuration?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (minTripDuration != null) {
      return minTripDuration(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MinTripDuration
    extends PackingListEntryCondition {
  const factory PackingListEntryCondition_MinTripDuration(
          {required final int length}) =
      _$PackingListEntryCondition_MinTripDurationImpl;
  const PackingListEntryCondition_MinTripDuration._() : super._();

  int get length;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_MinTripDurationImplCopyWith<
          _$PackingListEntryCondition_MinTripDurationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MaxTripDurationImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MaxTripDurationImplCopyWith(
          _$PackingListEntryCondition_MaxTripDurationImpl value,
          $Res Function(_$PackingListEntryCondition_MaxTripDurationImpl) then) =
      __$$PackingListEntryCondition_MaxTripDurationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int length});
}

/// @nodoc
class __$$PackingListEntryCondition_MaxTripDurationImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MaxTripDurationImpl>
    implements _$$PackingListEntryCondition_MaxTripDurationImplCopyWith<$Res> {
  __$$PackingListEntryCondition_MaxTripDurationImplCopyWithImpl(
      _$PackingListEntryCondition_MaxTripDurationImpl _value,
      $Res Function(_$PackingListEntryCondition_MaxTripDurationImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
  }) {
    return _then(_$PackingListEntryCondition_MaxTripDurationImpl(
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MaxTripDurationImpl
    extends PackingListEntryCondition_MaxTripDuration {
  const _$PackingListEntryCondition_MaxTripDurationImpl({required this.length})
      : super._();

  @override
  final int length;

  @override
  String toString() {
    return 'PackingListEntryCondition.maxTripDuration(length: $length)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MaxTripDurationImpl &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(runtimeType, length);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MaxTripDurationImplCopyWith<
          _$PackingListEntryCondition_MaxTripDurationImpl>
      get copyWith =>
          __$$PackingListEntryCondition_MaxTripDurationImplCopyWithImpl<
                  _$PackingListEntryCondition_MaxTripDurationImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return maxTripDuration(length);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return maxTripDuration?.call(length);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (maxTripDuration != null) {
      return maxTripDuration(length);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return maxTripDuration(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return maxTripDuration?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (maxTripDuration != null) {
      return maxTripDuration(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MaxTripDuration
    extends PackingListEntryCondition {
  const factory PackingListEntryCondition_MaxTripDuration(
          {required final int length}) =
      _$PackingListEntryCondition_MaxTripDurationImpl;
  const PackingListEntryCondition_MaxTripDuration._() : super._();

  int get length;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_MaxTripDurationImplCopyWith<
          _$PackingListEntryCondition_MaxTripDurationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MinTemperatureImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MinTemperatureImplCopyWith(
          _$PackingListEntryCondition_MinTemperatureImpl value,
          $Res Function(_$PackingListEntryCondition_MinTemperatureImpl) then) =
      __$$PackingListEntryCondition_MinTemperatureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double temperature});
}

/// @nodoc
class __$$PackingListEntryCondition_MinTemperatureImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MinTemperatureImpl>
    implements _$$PackingListEntryCondition_MinTemperatureImplCopyWith<$Res> {
  __$$PackingListEntryCondition_MinTemperatureImplCopyWithImpl(
      _$PackingListEntryCondition_MinTemperatureImpl _value,
      $Res Function(_$PackingListEntryCondition_MinTemperatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
  }) {
    return _then(_$PackingListEntryCondition_MinTemperatureImpl(
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MinTemperatureImpl
    extends PackingListEntryCondition_MinTemperature {
  const _$PackingListEntryCondition_MinTemperatureImpl(
      {required this.temperature})
      : super._();

  @override
  final double temperature;

  @override
  String toString() {
    return 'PackingListEntryCondition.minTemperature(temperature: $temperature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MinTemperatureImpl &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @override
  int get hashCode => Object.hash(runtimeType, temperature);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MinTemperatureImplCopyWith<
          _$PackingListEntryCondition_MinTemperatureImpl>
      get copyWith =>
          __$$PackingListEntryCondition_MinTemperatureImplCopyWithImpl<
              _$PackingListEntryCondition_MinTemperatureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return minTemperature(temperature);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return minTemperature?.call(temperature);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (minTemperature != null) {
      return minTemperature(temperature);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return minTemperature(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return minTemperature?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (minTemperature != null) {
      return minTemperature(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MinTemperature
    extends PackingListEntryCondition {
  const factory PackingListEntryCondition_MinTemperature(
          {required final double temperature}) =
      _$PackingListEntryCondition_MinTemperatureImpl;
  const PackingListEntryCondition_MinTemperature._() : super._();

  double get temperature;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_MinTemperatureImplCopyWith<
          _$PackingListEntryCondition_MinTemperatureImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MaxTemperatureImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MaxTemperatureImplCopyWith(
          _$PackingListEntryCondition_MaxTemperatureImpl value,
          $Res Function(_$PackingListEntryCondition_MaxTemperatureImpl) then) =
      __$$PackingListEntryCondition_MaxTemperatureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double temperature});
}

/// @nodoc
class __$$PackingListEntryCondition_MaxTemperatureImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MaxTemperatureImpl>
    implements _$$PackingListEntryCondition_MaxTemperatureImplCopyWith<$Res> {
  __$$PackingListEntryCondition_MaxTemperatureImplCopyWithImpl(
      _$PackingListEntryCondition_MaxTemperatureImpl _value,
      $Res Function(_$PackingListEntryCondition_MaxTemperatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
  }) {
    return _then(_$PackingListEntryCondition_MaxTemperatureImpl(
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MaxTemperatureImpl
    extends PackingListEntryCondition_MaxTemperature {
  const _$PackingListEntryCondition_MaxTemperatureImpl(
      {required this.temperature})
      : super._();

  @override
  final double temperature;

  @override
  String toString() {
    return 'PackingListEntryCondition.maxTemperature(temperature: $temperature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MaxTemperatureImpl &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @override
  int get hashCode => Object.hash(runtimeType, temperature);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MaxTemperatureImplCopyWith<
          _$PackingListEntryCondition_MaxTemperatureImpl>
      get copyWith =>
          __$$PackingListEntryCondition_MaxTemperatureImplCopyWithImpl<
              _$PackingListEntryCondition_MaxTemperatureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return maxTemperature(temperature);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return maxTemperature?.call(temperature);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (maxTemperature != null) {
      return maxTemperature(temperature);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return maxTemperature(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return maxTemperature?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (maxTemperature != null) {
      return maxTemperature(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MaxTemperature
    extends PackingListEntryCondition {
  const factory PackingListEntryCondition_MaxTemperature(
          {required final double temperature}) =
      _$PackingListEntryCondition_MaxTemperatureImpl;
  const PackingListEntryCondition_MaxTemperature._() : super._();

  double get temperature;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_MaxTemperatureImplCopyWith<
          _$PackingListEntryCondition_MaxTemperatureImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_WeatherImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_WeatherImplCopyWith(
          _$PackingListEntryCondition_WeatherImpl value,
          $Res Function(_$PackingListEntryCondition_WeatherImpl) then) =
      __$$PackingListEntryCondition_WeatherImplCopyWithImpl<$Res>;
  @useResult
  $Res call({WeatherCondition condition, double minProbability});
}

/// @nodoc
class __$$PackingListEntryCondition_WeatherImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_WeatherImpl>
    implements _$$PackingListEntryCondition_WeatherImplCopyWith<$Res> {
  __$$PackingListEntryCondition_WeatherImplCopyWithImpl(
      _$PackingListEntryCondition_WeatherImpl _value,
      $Res Function(_$PackingListEntryCondition_WeatherImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? condition = null,
    Object? minProbability = null,
  }) {
    return _then(_$PackingListEntryCondition_WeatherImpl(
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as WeatherCondition,
      minProbability: null == minProbability
          ? _value.minProbability
          : minProbability // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_WeatherImpl
    extends PackingListEntryCondition_Weather {
  const _$PackingListEntryCondition_WeatherImpl(
      {required this.condition, required this.minProbability})
      : super._();

  @override
  final WeatherCondition condition;
  @override
  final double minProbability;

  @override
  String toString() {
    return 'PackingListEntryCondition.weather(condition: $condition, minProbability: $minProbability)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_WeatherImpl &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.minProbability, minProbability) ||
                other.minProbability == minProbability));
  }

  @override
  int get hashCode => Object.hash(runtimeType, condition, minProbability);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_WeatherImplCopyWith<
          _$PackingListEntryCondition_WeatherImpl>
      get copyWith => __$$PackingListEntryCondition_WeatherImplCopyWithImpl<
          _$PackingListEntryCondition_WeatherImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return weather(condition, minProbability);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return weather?.call(condition, minProbability);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (weather != null) {
      return weather(condition, minProbability);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return weather(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return weather?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (weather != null) {
      return weather(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_Weather
    extends PackingListEntryCondition {
  const factory PackingListEntryCondition_Weather(
          {required final WeatherCondition condition,
          required final double minProbability}) =
      _$PackingListEntryCondition_WeatherImpl;
  const PackingListEntryCondition_Weather._() : super._();

  WeatherCondition get condition;
  double get minProbability;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_WeatherImplCopyWith<
          _$PackingListEntryCondition_WeatherImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_TagImplCopyWith<$Res> {
  factory _$$PackingListEntryCondition_TagImplCopyWith(
          _$PackingListEntryCondition_TagImpl value,
          $Res Function(_$PackingListEntryCondition_TagImpl) then) =
      __$$PackingListEntryCondition_TagImplCopyWithImpl<$Res>;
  @useResult
  $Res call({UuidValue tagId});
}

/// @nodoc
class __$$PackingListEntryCondition_TagImplCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_TagImpl>
    implements _$$PackingListEntryCondition_TagImplCopyWith<$Res> {
  __$$PackingListEntryCondition_TagImplCopyWithImpl(
      _$PackingListEntryCondition_TagImpl _value,
      $Res Function(_$PackingListEntryCondition_TagImpl) _then)
      : super(_value, _then);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagId = null,
  }) {
    return _then(_$PackingListEntryCondition_TagImpl(
      tagId: null == tagId
          ? _value.tagId
          : tagId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_TagImpl
    extends PackingListEntryCondition_Tag {
  const _$PackingListEntryCondition_TagImpl({required this.tagId}) : super._();

  @override
  final UuidValue tagId;

  @override
  String toString() {
    return 'PackingListEntryCondition.tag(tagId: $tagId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_TagImpl &&
            (identical(other.tagId, tagId) || other.tagId == tagId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tagId);

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_TagImplCopyWith<
          _$PackingListEntryCondition_TagImpl>
      get copyWith => __$$PackingListEntryCondition_TagImplCopyWithImpl<
          _$PackingListEntryCondition_TagImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
    required TResult Function(UuidValue tagId) tag,
  }) {
    return tag(tagId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int length)? minTripDuration,
    TResult? Function(int length)? maxTripDuration,
    TResult? Function(double temperature)? minTemperature,
    TResult? Function(double temperature)? maxTemperature,
    TResult? Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult? Function(UuidValue tagId)? tag,
  }) {
    return tag?.call(tagId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int length)? minTripDuration,
    TResult Function(int length)? maxTripDuration,
    TResult Function(double temperature)? minTemperature,
    TResult Function(double temperature)? maxTemperature,
    TResult Function(WeatherCondition condition, double minProbability)?
        weather,
    TResult Function(UuidValue tagId)? tag,
    required TResult orElse(),
  }) {
    if (tag != null) {
      return tag(tagId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PackingListEntryCondition_MinTripDuration value)
        minTripDuration,
    required TResult Function(PackingListEntryCondition_MaxTripDuration value)
        maxTripDuration,
    required TResult Function(PackingListEntryCondition_MinTemperature value)
        minTemperature,
    required TResult Function(PackingListEntryCondition_MaxTemperature value)
        maxTemperature,
    required TResult Function(PackingListEntryCondition_Weather value) weather,
    required TResult Function(PackingListEntryCondition_Tag value) tag,
  }) {
    return tag(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult? Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult? Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult? Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult? Function(PackingListEntryCondition_Weather value)? weather,
    TResult? Function(PackingListEntryCondition_Tag value)? tag,
  }) {
    return tag?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PackingListEntryCondition_MinTripDuration value)?
        minTripDuration,
    TResult Function(PackingListEntryCondition_MaxTripDuration value)?
        maxTripDuration,
    TResult Function(PackingListEntryCondition_MinTemperature value)?
        minTemperature,
    TResult Function(PackingListEntryCondition_MaxTemperature value)?
        maxTemperature,
    TResult Function(PackingListEntryCondition_Weather value)? weather,
    TResult Function(PackingListEntryCondition_Tag value)? tag,
    required TResult orElse(),
  }) {
    if (tag != null) {
      return tag(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_Tag extends PackingListEntryCondition {
  const factory PackingListEntryCondition_Tag(
      {required final UuidValue tagId}) = _$PackingListEntryCondition_TagImpl;
  const PackingListEntryCondition_Tag._() : super._();

  UuidValue get tagId;

  /// Create a copy of PackingListEntryCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PackingListEntryCondition_TagImplCopyWith<
          _$PackingListEntryCondition_TagImpl>
      get copyWith => throw _privateConstructorUsedError;
}
