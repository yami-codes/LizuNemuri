// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'th_th.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ThTh _$ThThFromJson(Map<String, dynamic> json) {
  return _ThTh.fromJson(json);
}

/// @nodoc
mixin _$ThTh {
  String? get name => throw _privateConstructorUsedError;
  List<dynamic>? get history => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ThThCopyWith<ThTh> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThThCopyWith<$Res> {
  factory $ThThCopyWith(ThTh value, $Res Function(ThTh) then) =
      _$ThThCopyWithImpl<$Res, ThTh>;
  @useResult
  $Res call({String? name, List<dynamic>? history});
}

/// @nodoc
class _$ThThCopyWithImpl<$Res, $Val extends ThTh>
    implements $ThThCopyWith<$Res> {
  _$ThThCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? history = freezed,
  }) {
    return _then(_value.copyWith(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      history: freezed == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThThImplCopyWith<$Res> implements $ThThCopyWith<$Res> {
  factory _$$ThThImplCopyWith(
          _$ThThImpl value, $Res Function(_$ThThImpl) then) =
      __$$ThThImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? name, List<dynamic>? history});
}

/// @nodoc
class __$$ThThImplCopyWithImpl<$Res>
    extends _$ThThCopyWithImpl<$Res, _$ThThImpl>
    implements _$$ThThImplCopyWith<$Res> {
  __$$ThThImplCopyWithImpl(_$ThThImpl _value, $Res Function(_$ThThImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? history = freezed,
  }) {
    return _then(_$ThThImpl(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      history: freezed == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThThImpl implements _ThTh {
  _$ThThImpl({this.name, final List<dynamic>? history}) : _history = history;

  factory _$ThThImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThThImplFromJson(json);

  @override
  final String? name;
  final List<dynamic>? _history;
  @override
  List<dynamic>? get history {
    final value = _history;
    if (value == null) return null;
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ThTh(name: $name, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThThImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_history));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ThThImplCopyWith<_$ThThImpl> get copyWith =>
      __$$ThThImplCopyWithImpl<_$ThThImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThThImplToJson(
      this,
    );
  }
}

abstract class _ThTh implements ThTh {
  factory _ThTh({final String? name, final List<dynamic>? history}) =
      _$ThThImpl;

  factory _ThTh.fromJson(Map<String, dynamic> json) = _$ThThImpl.fromJson;

  @override
  String? get name;
  @override
  List<dynamic>? get history;
  @override
  @JsonKey(ignore: true)
  _$$ThThImplCopyWith<_$ThThImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
