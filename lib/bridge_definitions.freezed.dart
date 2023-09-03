// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bridge_definitions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

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
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MinTripDurationCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MinTripDurationCopyWith(
          _$PackingListEntryCondition_MinTripDuration value,
          $Res Function(_$PackingListEntryCondition_MinTripDuration) then) =
      __$$PackingListEntryCondition_MinTripDurationCopyWithImpl<$Res>;
  @useResult
  $Res call({int length});
}

/// @nodoc
class __$$PackingListEntryCondition_MinTripDurationCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MinTripDuration>
    implements _$$PackingListEntryCondition_MinTripDurationCopyWith<$Res> {
  __$$PackingListEntryCondition_MinTripDurationCopyWithImpl(
      _$PackingListEntryCondition_MinTripDuration _value,
      $Res Function(_$PackingListEntryCondition_MinTripDuration) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
  }) {
    return _then(_$PackingListEntryCondition_MinTripDuration(
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MinTripDuration
    implements PackingListEntryCondition_MinTripDuration {
  const _$PackingListEntryCondition_MinTripDuration({required this.length});

  @override
  final int length;

  @override
  String toString() {
    return 'PackingListEntryCondition.minTripDuration(length: $length)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MinTripDuration &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(runtimeType, length);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MinTripDurationCopyWith<
          _$PackingListEntryCondition_MinTripDuration>
      get copyWith => __$$PackingListEntryCondition_MinTripDurationCopyWithImpl<
          _$PackingListEntryCondition_MinTripDuration>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
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
    required TResult orElse(),
  }) {
    if (minTripDuration != null) {
      return minTripDuration(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MinTripDuration
    implements PackingListEntryCondition {
  const factory PackingListEntryCondition_MinTripDuration(
          {required final int length}) =
      _$PackingListEntryCondition_MinTripDuration;

  int get length;
  @JsonKey(ignore: true)
  _$$PackingListEntryCondition_MinTripDurationCopyWith<
          _$PackingListEntryCondition_MinTripDuration>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MaxTripDurationCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MaxTripDurationCopyWith(
          _$PackingListEntryCondition_MaxTripDuration value,
          $Res Function(_$PackingListEntryCondition_MaxTripDuration) then) =
      __$$PackingListEntryCondition_MaxTripDurationCopyWithImpl<$Res>;
  @useResult
  $Res call({int length});
}

/// @nodoc
class __$$PackingListEntryCondition_MaxTripDurationCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MaxTripDuration>
    implements _$$PackingListEntryCondition_MaxTripDurationCopyWith<$Res> {
  __$$PackingListEntryCondition_MaxTripDurationCopyWithImpl(
      _$PackingListEntryCondition_MaxTripDuration _value,
      $Res Function(_$PackingListEntryCondition_MaxTripDuration) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
  }) {
    return _then(_$PackingListEntryCondition_MaxTripDuration(
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MaxTripDuration
    implements PackingListEntryCondition_MaxTripDuration {
  const _$PackingListEntryCondition_MaxTripDuration({required this.length});

  @override
  final int length;

  @override
  String toString() {
    return 'PackingListEntryCondition.maxTripDuration(length: $length)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MaxTripDuration &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(runtimeType, length);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MaxTripDurationCopyWith<
          _$PackingListEntryCondition_MaxTripDuration>
      get copyWith => __$$PackingListEntryCondition_MaxTripDurationCopyWithImpl<
          _$PackingListEntryCondition_MaxTripDuration>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
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
    required TResult orElse(),
  }) {
    if (maxTripDuration != null) {
      return maxTripDuration(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MaxTripDuration
    implements PackingListEntryCondition {
  const factory PackingListEntryCondition_MaxTripDuration(
          {required final int length}) =
      _$PackingListEntryCondition_MaxTripDuration;

  int get length;
  @JsonKey(ignore: true)
  _$$PackingListEntryCondition_MaxTripDurationCopyWith<
          _$PackingListEntryCondition_MaxTripDuration>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MinTemperatureCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MinTemperatureCopyWith(
          _$PackingListEntryCondition_MinTemperature value,
          $Res Function(_$PackingListEntryCondition_MinTemperature) then) =
      __$$PackingListEntryCondition_MinTemperatureCopyWithImpl<$Res>;
  @useResult
  $Res call({double temperature});
}

/// @nodoc
class __$$PackingListEntryCondition_MinTemperatureCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MinTemperature>
    implements _$$PackingListEntryCondition_MinTemperatureCopyWith<$Res> {
  __$$PackingListEntryCondition_MinTemperatureCopyWithImpl(
      _$PackingListEntryCondition_MinTemperature _value,
      $Res Function(_$PackingListEntryCondition_MinTemperature) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
  }) {
    return _then(_$PackingListEntryCondition_MinTemperature(
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MinTemperature
    implements PackingListEntryCondition_MinTemperature {
  const _$PackingListEntryCondition_MinTemperature({required this.temperature});

  @override
  final double temperature;

  @override
  String toString() {
    return 'PackingListEntryCondition.minTemperature(temperature: $temperature)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MinTemperature &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @override
  int get hashCode => Object.hash(runtimeType, temperature);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MinTemperatureCopyWith<
          _$PackingListEntryCondition_MinTemperature>
      get copyWith => __$$PackingListEntryCondition_MinTemperatureCopyWithImpl<
          _$PackingListEntryCondition_MinTemperature>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
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
    required TResult orElse(),
  }) {
    if (minTemperature != null) {
      return minTemperature(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MinTemperature
    implements PackingListEntryCondition {
  const factory PackingListEntryCondition_MinTemperature(
          {required final double temperature}) =
      _$PackingListEntryCondition_MinTemperature;

  double get temperature;
  @JsonKey(ignore: true)
  _$$PackingListEntryCondition_MinTemperatureCopyWith<
          _$PackingListEntryCondition_MinTemperature>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_MaxTemperatureCopyWith<$Res> {
  factory _$$PackingListEntryCondition_MaxTemperatureCopyWith(
          _$PackingListEntryCondition_MaxTemperature value,
          $Res Function(_$PackingListEntryCondition_MaxTemperature) then) =
      __$$PackingListEntryCondition_MaxTemperatureCopyWithImpl<$Res>;
  @useResult
  $Res call({double temperature});
}

/// @nodoc
class __$$PackingListEntryCondition_MaxTemperatureCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_MaxTemperature>
    implements _$$PackingListEntryCondition_MaxTemperatureCopyWith<$Res> {
  __$$PackingListEntryCondition_MaxTemperatureCopyWithImpl(
      _$PackingListEntryCondition_MaxTemperature _value,
      $Res Function(_$PackingListEntryCondition_MaxTemperature) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
  }) {
    return _then(_$PackingListEntryCondition_MaxTemperature(
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PackingListEntryCondition_MaxTemperature
    implements PackingListEntryCondition_MaxTemperature {
  const _$PackingListEntryCondition_MaxTemperature({required this.temperature});

  @override
  final double temperature;

  @override
  String toString() {
    return 'PackingListEntryCondition.maxTemperature(temperature: $temperature)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_MaxTemperature &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @override
  int get hashCode => Object.hash(runtimeType, temperature);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_MaxTemperatureCopyWith<
          _$PackingListEntryCondition_MaxTemperature>
      get copyWith => __$$PackingListEntryCondition_MaxTemperatureCopyWithImpl<
          _$PackingListEntryCondition_MaxTemperature>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
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
    required TResult orElse(),
  }) {
    if (maxTemperature != null) {
      return maxTemperature(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_MaxTemperature
    implements PackingListEntryCondition {
  const factory PackingListEntryCondition_MaxTemperature(
          {required final double temperature}) =
      _$PackingListEntryCondition_MaxTemperature;

  double get temperature;
  @JsonKey(ignore: true)
  _$$PackingListEntryCondition_MaxTemperatureCopyWith<
          _$PackingListEntryCondition_MaxTemperature>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PackingListEntryCondition_WeatherCopyWith<$Res> {
  factory _$$PackingListEntryCondition_WeatherCopyWith(
          _$PackingListEntryCondition_Weather value,
          $Res Function(_$PackingListEntryCondition_Weather) then) =
      __$$PackingListEntryCondition_WeatherCopyWithImpl<$Res>;
  @useResult
  $Res call({WeatherCondition condition, double minProbability});
}

/// @nodoc
class __$$PackingListEntryCondition_WeatherCopyWithImpl<$Res>
    extends _$PackingListEntryConditionCopyWithImpl<$Res,
        _$PackingListEntryCondition_Weather>
    implements _$$PackingListEntryCondition_WeatherCopyWith<$Res> {
  __$$PackingListEntryCondition_WeatherCopyWithImpl(
      _$PackingListEntryCondition_Weather _value,
      $Res Function(_$PackingListEntryCondition_Weather) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? condition = null,
    Object? minProbability = null,
  }) {
    return _then(_$PackingListEntryCondition_Weather(
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

class _$PackingListEntryCondition_Weather
    implements PackingListEntryCondition_Weather {
  const _$PackingListEntryCondition_Weather(
      {required this.condition, required this.minProbability});

  @override
  final WeatherCondition condition;
  @override
  final double minProbability;

  @override
  String toString() {
    return 'PackingListEntryCondition.weather(condition: $condition, minProbability: $minProbability)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingListEntryCondition_Weather &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.minProbability, minProbability) ||
                other.minProbability == minProbability));
  }

  @override
  int get hashCode => Object.hash(runtimeType, condition, minProbability);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingListEntryCondition_WeatherCopyWith<
          _$PackingListEntryCondition_Weather>
      get copyWith => __$$PackingListEntryCondition_WeatherCopyWithImpl<
          _$PackingListEntryCondition_Weather>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int length) minTripDuration,
    required TResult Function(int length) maxTripDuration,
    required TResult Function(double temperature) minTemperature,
    required TResult Function(double temperature) maxTemperature,
    required TResult Function(WeatherCondition condition, double minProbability)
        weather,
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
    required TResult orElse(),
  }) {
    if (weather != null) {
      return weather(this);
    }
    return orElse();
  }
}

abstract class PackingListEntryCondition_Weather
    implements PackingListEntryCondition {
  const factory PackingListEntryCondition_Weather(
          {required final WeatherCondition condition,
          required final double minProbability}) =
      _$PackingListEntryCondition_Weather;

  WeatherCondition get condition;
  double get minProbability;
  @JsonKey(ignore: true)
  _$$PackingListEntryCondition_WeatherCopyWith<
          _$PackingListEntryCondition_Weather>
      get copyWith => throw _privateConstructorUsedError;
}
