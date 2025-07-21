// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Booking {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reservation field0) reservation,
    required TResult Function(CarRental field0) carRental,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reservation field0)? reservation,
    TResult? Function(CarRental field0)? carRental,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reservation field0)? reservation,
    TResult Function(CarRental field0)? carRental,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Booking_Reservation value) reservation,
    required TResult Function(Booking_CarRental value) carRental,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Booking_Reservation value)? reservation,
    TResult? Function(Booking_CarRental value)? carRental,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Booking_Reservation value)? reservation,
    TResult Function(Booking_CarRental value)? carRental,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingCopyWith<$Res> {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) then) =
      _$BookingCopyWithImpl<$Res, Booking>;
}

/// @nodoc
class _$BookingCopyWithImpl<$Res, $Val extends Booking>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Booking_ReservationImplCopyWith<$Res> {
  factory _$$Booking_ReservationImplCopyWith(_$Booking_ReservationImpl value,
          $Res Function(_$Booking_ReservationImpl) then) =
      __$$Booking_ReservationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Reservation field0});
}

/// @nodoc
class __$$Booking_ReservationImplCopyWithImpl<$Res>
    extends _$BookingCopyWithImpl<$Res, _$Booking_ReservationImpl>
    implements _$$Booking_ReservationImplCopyWith<$Res> {
  __$$Booking_ReservationImplCopyWithImpl(_$Booking_ReservationImpl _value,
      $Res Function(_$Booking_ReservationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Booking_ReservationImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Reservation,
    ));
  }
}

/// @nodoc

class _$Booking_ReservationImpl extends Booking_Reservation {
  const _$Booking_ReservationImpl(this.field0) : super._();

  @override
  final Reservation field0;

  @override
  String toString() {
    return 'Booking.reservation(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Booking_ReservationImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Booking_ReservationImplCopyWith<_$Booking_ReservationImpl> get copyWith =>
      __$$Booking_ReservationImplCopyWithImpl<_$Booking_ReservationImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reservation field0) reservation,
    required TResult Function(CarRental field0) carRental,
  }) {
    return reservation(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reservation field0)? reservation,
    TResult? Function(CarRental field0)? carRental,
  }) {
    return reservation?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reservation field0)? reservation,
    TResult Function(CarRental field0)? carRental,
    required TResult orElse(),
  }) {
    if (reservation != null) {
      return reservation(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Booking_Reservation value) reservation,
    required TResult Function(Booking_CarRental value) carRental,
  }) {
    return reservation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Booking_Reservation value)? reservation,
    TResult? Function(Booking_CarRental value)? carRental,
  }) {
    return reservation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Booking_Reservation value)? reservation,
    TResult Function(Booking_CarRental value)? carRental,
    required TResult orElse(),
  }) {
    if (reservation != null) {
      return reservation(this);
    }
    return orElse();
  }
}

abstract class Booking_Reservation extends Booking {
  const factory Booking_Reservation(final Reservation field0) =
      _$Booking_ReservationImpl;
  const Booking_Reservation._() : super._();

  @override
  Reservation get field0;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Booking_ReservationImplCopyWith<_$Booking_ReservationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Booking_CarRentalImplCopyWith<$Res> {
  factory _$$Booking_CarRentalImplCopyWith(_$Booking_CarRentalImpl value,
          $Res Function(_$Booking_CarRentalImpl) then) =
      __$$Booking_CarRentalImplCopyWithImpl<$Res>;
  @useResult
  $Res call({CarRental field0});
}

/// @nodoc
class __$$Booking_CarRentalImplCopyWithImpl<$Res>
    extends _$BookingCopyWithImpl<$Res, _$Booking_CarRentalImpl>
    implements _$$Booking_CarRentalImplCopyWith<$Res> {
  __$$Booking_CarRentalImplCopyWithImpl(_$Booking_CarRentalImpl _value,
      $Res Function(_$Booking_CarRentalImpl) _then)
      : super(_value, _then);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Booking_CarRentalImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as CarRental,
    ));
  }
}

/// @nodoc

class _$Booking_CarRentalImpl extends Booking_CarRental {
  const _$Booking_CarRentalImpl(this.field0) : super._();

  @override
  final CarRental field0;

  @override
  String toString() {
    return 'Booking.carRental(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Booking_CarRentalImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Booking_CarRentalImplCopyWith<_$Booking_CarRentalImpl> get copyWith =>
      __$$Booking_CarRentalImplCopyWithImpl<_$Booking_CarRentalImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reservation field0) reservation,
    required TResult Function(CarRental field0) carRental,
  }) {
    return carRental(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reservation field0)? reservation,
    TResult? Function(CarRental field0)? carRental,
  }) {
    return carRental?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reservation field0)? reservation,
    TResult Function(CarRental field0)? carRental,
    required TResult orElse(),
  }) {
    if (carRental != null) {
      return carRental(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Booking_Reservation value) reservation,
    required TResult Function(Booking_CarRental value) carRental,
  }) {
    return carRental(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Booking_Reservation value)? reservation,
    TResult? Function(Booking_CarRental value)? carRental,
  }) {
    return carRental?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Booking_Reservation value)? reservation,
    TResult Function(Booking_CarRental value)? carRental,
    required TResult orElse(),
  }) {
    if (carRental != null) {
      return carRental(this);
    }
    return orElse();
  }
}

abstract class Booking_CarRental extends Booking {
  const factory Booking_CarRental(final CarRental field0) =
      _$Booking_CarRentalImpl;
  const Booking_CarRental._() : super._();

  @override
  CarRental get field0;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Booking_CarRentalImplCopyWith<_$Booking_CarRentalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
