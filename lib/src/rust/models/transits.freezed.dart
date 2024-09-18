// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transits.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Transit {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Flight field0) flight,
    required TResult Function(Train field0) train,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Flight field0)? flight,
    TResult? Function(Train field0)? train,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Flight field0)? flight,
    TResult Function(Train field0)? train,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Transit_Flight value) flight,
    required TResult Function(Transit_Train value) train,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Transit_Flight value)? flight,
    TResult? Function(Transit_Train value)? train,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Transit_Flight value)? flight,
    TResult Function(Transit_Train value)? train,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransitCopyWith<$Res> {
  factory $TransitCopyWith(Transit value, $Res Function(Transit) then) =
      _$TransitCopyWithImpl<$Res, Transit>;
}

/// @nodoc
class _$TransitCopyWithImpl<$Res, $Val extends Transit>
    implements $TransitCopyWith<$Res> {
  _$TransitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Transit_FlightImplCopyWith<$Res> {
  factory _$$Transit_FlightImplCopyWith(_$Transit_FlightImpl value,
          $Res Function(_$Transit_FlightImpl) then) =
      __$$Transit_FlightImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Flight field0});
}

/// @nodoc
class __$$Transit_FlightImplCopyWithImpl<$Res>
    extends _$TransitCopyWithImpl<$Res, _$Transit_FlightImpl>
    implements _$$Transit_FlightImplCopyWith<$Res> {
  __$$Transit_FlightImplCopyWithImpl(
      _$Transit_FlightImpl _value, $Res Function(_$Transit_FlightImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Transit_FlightImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Flight,
    ));
  }
}

/// @nodoc

class _$Transit_FlightImpl extends Transit_Flight {
  const _$Transit_FlightImpl(this.field0) : super._();

  @override
  final Flight field0;

  @override
  String toString() {
    return 'Transit.flight(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Transit_FlightImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Transit_FlightImplCopyWith<_$Transit_FlightImpl> get copyWith =>
      __$$Transit_FlightImplCopyWithImpl<_$Transit_FlightImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Flight field0) flight,
    required TResult Function(Train field0) train,
  }) {
    return flight(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Flight field0)? flight,
    TResult? Function(Train field0)? train,
  }) {
    return flight?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Flight field0)? flight,
    TResult Function(Train field0)? train,
    required TResult orElse(),
  }) {
    if (flight != null) {
      return flight(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Transit_Flight value) flight,
    required TResult Function(Transit_Train value) train,
  }) {
    return flight(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Transit_Flight value)? flight,
    TResult? Function(Transit_Train value)? train,
  }) {
    return flight?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Transit_Flight value)? flight,
    TResult Function(Transit_Train value)? train,
    required TResult orElse(),
  }) {
    if (flight != null) {
      return flight(this);
    }
    return orElse();
  }
}

abstract class Transit_Flight extends Transit {
  const factory Transit_Flight(final Flight field0) = _$Transit_FlightImpl;
  const Transit_Flight._() : super._();

  @override
  Flight get field0;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Transit_FlightImplCopyWith<_$Transit_FlightImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Transit_TrainImplCopyWith<$Res> {
  factory _$$Transit_TrainImplCopyWith(
          _$Transit_TrainImpl value, $Res Function(_$Transit_TrainImpl) then) =
      __$$Transit_TrainImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Train field0});
}

/// @nodoc
class __$$Transit_TrainImplCopyWithImpl<$Res>
    extends _$TransitCopyWithImpl<$Res, _$Transit_TrainImpl>
    implements _$$Transit_TrainImplCopyWith<$Res> {
  __$$Transit_TrainImplCopyWithImpl(
      _$Transit_TrainImpl _value, $Res Function(_$Transit_TrainImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Transit_TrainImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Train,
    ));
  }
}

/// @nodoc

class _$Transit_TrainImpl extends Transit_Train {
  const _$Transit_TrainImpl(this.field0) : super._();

  @override
  final Train field0;

  @override
  String toString() {
    return 'Transit.train(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Transit_TrainImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Transit_TrainImplCopyWith<_$Transit_TrainImpl> get copyWith =>
      __$$Transit_TrainImplCopyWithImpl<_$Transit_TrainImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Flight field0) flight,
    required TResult Function(Train field0) train,
  }) {
    return train(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Flight field0)? flight,
    TResult? Function(Train field0)? train,
  }) {
    return train?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Flight field0)? flight,
    TResult Function(Train field0)? train,
    required TResult orElse(),
  }) {
    if (train != null) {
      return train(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Transit_Flight value) flight,
    required TResult Function(Transit_Train value) train,
  }) {
    return train(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Transit_Flight value)? flight,
    TResult? Function(Transit_Train value)? train,
  }) {
    return train?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Transit_Flight value)? flight,
    TResult Function(Transit_Train value)? train,
    required TResult orElse(),
  }) {
    if (train != null) {
      return train(this);
    }
    return orElse();
  }
}

abstract class Transit_Train extends Transit {
  const factory Transit_Train(final Train field0) = _$Transit_TrainImpl;
  const Transit_Train._() : super._();

  @override
  Train get field0;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Transit_TrainImplCopyWith<_$Transit_TrainImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
