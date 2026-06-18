// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStatusCopyWith<$Res> {
  factory $SyncStatusCopyWith(
          SyncStatus value, $Res Function(SyncStatus) then) =
      _$SyncStatusCopyWithImpl<$Res, SyncStatus>;
}

/// @nodoc
class _$SyncStatusCopyWithImpl<$Res, $Val extends SyncStatus>
    implements $SyncStatusCopyWith<$Res> {
  _$SyncStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SyncStatus_SignedOutImplCopyWith<$Res> {
  factory _$$SyncStatus_SignedOutImplCopyWith(_$SyncStatus_SignedOutImpl value,
          $Res Function(_$SyncStatus_SignedOutImpl) then) =
      __$$SyncStatus_SignedOutImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_SignedOutImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_SignedOutImpl>
    implements _$$SyncStatus_SignedOutImplCopyWith<$Res> {
  __$$SyncStatus_SignedOutImplCopyWithImpl(_$SyncStatus_SignedOutImpl _value,
      $Res Function(_$SyncStatus_SignedOutImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_SignedOutImpl extends SyncStatus_SignedOut {
  const _$SyncStatus_SignedOutImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.signedOut()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStatus_SignedOutImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return signedOut();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return signedOut?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (signedOut != null) {
      return signedOut();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return signedOut(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return signedOut?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (signedOut != null) {
      return signedOut(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_SignedOut extends SyncStatus {
  const factory SyncStatus_SignedOut() = _$SyncStatus_SignedOutImpl;
  const SyncStatus_SignedOut._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_IdleImplCopyWith<$Res> {
  factory _$$SyncStatus_IdleImplCopyWith(_$SyncStatus_IdleImpl value,
          $Res Function(_$SyncStatus_IdleImpl) then) =
      __$$SyncStatus_IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_IdleImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_IdleImpl>
    implements _$$SyncStatus_IdleImplCopyWith<$Res> {
  __$$SyncStatus_IdleImplCopyWithImpl(
      _$SyncStatus_IdleImpl _value, $Res Function(_$SyncStatus_IdleImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_IdleImpl extends SyncStatus_Idle {
  const _$SyncStatus_IdleImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncStatus_IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Idle extends SyncStatus {
  const factory SyncStatus_Idle() = _$SyncStatus_IdleImpl;
  const SyncStatus_Idle._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_ConnectingImplCopyWith<$Res> {
  factory _$$SyncStatus_ConnectingImplCopyWith(
          _$SyncStatus_ConnectingImpl value,
          $Res Function(_$SyncStatus_ConnectingImpl) then) =
      __$$SyncStatus_ConnectingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_ConnectingImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_ConnectingImpl>
    implements _$$SyncStatus_ConnectingImplCopyWith<$Res> {
  __$$SyncStatus_ConnectingImplCopyWithImpl(_$SyncStatus_ConnectingImpl _value,
      $Res Function(_$SyncStatus_ConnectingImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_ConnectingImpl extends SyncStatus_Connecting {
  const _$SyncStatus_ConnectingImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.connecting()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStatus_ConnectingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return connecting();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return connecting?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (connecting != null) {
      return connecting();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return connecting(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return connecting?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (connecting != null) {
      return connecting(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Connecting extends SyncStatus {
  const factory SyncStatus_Connecting() = _$SyncStatus_ConnectingImpl;
  const SyncStatus_Connecting._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_LiveImplCopyWith<$Res> {
  factory _$$SyncStatus_LiveImplCopyWith(_$SyncStatus_LiveImpl value,
          $Res Function(_$SyncStatus_LiveImpl) then) =
      __$$SyncStatus_LiveImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_LiveImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_LiveImpl>
    implements _$$SyncStatus_LiveImplCopyWith<$Res> {
  __$$SyncStatus_LiveImplCopyWithImpl(
      _$SyncStatus_LiveImpl _value, $Res Function(_$SyncStatus_LiveImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_LiveImpl extends SyncStatus_Live {
  const _$SyncStatus_LiveImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.live()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncStatus_LiveImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return live();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return live?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (live != null) {
      return live();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return live(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return live?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (live != null) {
      return live(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Live extends SyncStatus {
  const factory SyncStatus_Live() = _$SyncStatus_LiveImpl;
  const SyncStatus_Live._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_SyncingImplCopyWith<$Res> {
  factory _$$SyncStatus_SyncingImplCopyWith(_$SyncStatus_SyncingImpl value,
          $Res Function(_$SyncStatus_SyncingImpl) then) =
      __$$SyncStatus_SyncingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_SyncingImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_SyncingImpl>
    implements _$$SyncStatus_SyncingImplCopyWith<$Res> {
  __$$SyncStatus_SyncingImplCopyWithImpl(_$SyncStatus_SyncingImpl _value,
      $Res Function(_$SyncStatus_SyncingImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_SyncingImpl extends SyncStatus_Syncing {
  const _$SyncStatus_SyncingImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.syncing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncStatus_SyncingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return syncing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return syncing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return syncing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return syncing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Syncing extends SyncStatus {
  const factory SyncStatus_Syncing() = _$SyncStatus_SyncingImpl;
  const SyncStatus_Syncing._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_OfflineImplCopyWith<$Res> {
  factory _$$SyncStatus_OfflineImplCopyWith(_$SyncStatus_OfflineImpl value,
          $Res Function(_$SyncStatus_OfflineImpl) then) =
      __$$SyncStatus_OfflineImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStatus_OfflineImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_OfflineImpl>
    implements _$$SyncStatus_OfflineImplCopyWith<$Res> {
  __$$SyncStatus_OfflineImplCopyWithImpl(_$SyncStatus_OfflineImpl _value,
      $Res Function(_$SyncStatus_OfflineImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncStatus_OfflineImpl extends SyncStatus_Offline {
  const _$SyncStatus_OfflineImpl() : super._();

  @override
  String toString() {
    return 'SyncStatus.offline()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncStatus_OfflineImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return offline();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return offline?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return offline(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return offline?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Offline extends SyncStatus {
  const factory SyncStatus_Offline() = _$SyncStatus_OfflineImpl;
  const SyncStatus_Offline._() : super._();
}

/// @nodoc
abstract class _$$SyncStatus_ErrorImplCopyWith<$Res> {
  factory _$$SyncStatus_ErrorImplCopyWith(_$SyncStatus_ErrorImpl value,
          $Res Function(_$SyncStatus_ErrorImpl) then) =
      __$$SyncStatus_ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SyncStatus_ErrorImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatus_ErrorImpl>
    implements _$$SyncStatus_ErrorImplCopyWith<$Res> {
  __$$SyncStatus_ErrorImplCopyWithImpl(_$SyncStatus_ErrorImpl _value,
      $Res Function(_$SyncStatus_ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$SyncStatus_ErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SyncStatus_ErrorImpl extends SyncStatus_Error {
  const _$SyncStatus_ErrorImpl({required this.message}) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'SyncStatus.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStatus_ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncStatus_ErrorImplCopyWith<_$SyncStatus_ErrorImpl> get copyWith =>
      __$$SyncStatus_ErrorImplCopyWithImpl<_$SyncStatus_ErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() signedOut,
    required TResult Function() idle,
    required TResult Function() connecting,
    required TResult Function() live,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? signedOut,
    TResult? Function()? idle,
    TResult? Function()? connecting,
    TResult? Function()? live,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? signedOut,
    TResult Function()? idle,
    TResult Function()? connecting,
    TResult Function()? live,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_SignedOut value) signedOut,
    required TResult Function(SyncStatus_Idle value) idle,
    required TResult Function(SyncStatus_Connecting value) connecting,
    required TResult Function(SyncStatus_Live value) live,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Offline value) offline,
    required TResult Function(SyncStatus_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStatus_SignedOut value)? signedOut,
    TResult? Function(SyncStatus_Idle value)? idle,
    TResult? Function(SyncStatus_Connecting value)? connecting,
    TResult? Function(SyncStatus_Live value)? live,
    TResult? Function(SyncStatus_Syncing value)? syncing,
    TResult? Function(SyncStatus_Offline value)? offline,
    TResult? Function(SyncStatus_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_SignedOut value)? signedOut,
    TResult Function(SyncStatus_Idle value)? idle,
    TResult Function(SyncStatus_Connecting value)? connecting,
    TResult Function(SyncStatus_Live value)? live,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Offline value)? offline,
    TResult Function(SyncStatus_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SyncStatus_Error extends SyncStatus {
  const factory SyncStatus_Error({required final String message}) =
      _$SyncStatus_ErrorImpl;
  const SyncStatus_Error._() : super._();

  String get message;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncStatus_ErrorImplCopyWith<_$SyncStatus_ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
