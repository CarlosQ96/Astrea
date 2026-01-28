/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class UserSettings implements _i1.SerializableModel {
  UserSettings._({
    this.id,
    required this.userId,
    int? defaultSnoozeMinutes,
    this.quietHoursStart,
    this.quietHoursEnd,
    bool? voiceEnabled,
    String? timezone,
  }) : defaultSnoozeMinutes = defaultSnoozeMinutes ?? 15,
       voiceEnabled = voiceEnabled ?? true,
       timezone = timezone ?? 'UTC';

  factory UserSettings({
    int? id,
    required _i1.UuidValue userId,
    int? defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? voiceEnabled,
    String? timezone,
  }) = _UserSettingsImpl;

  factory UserSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSettings(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      defaultSnoozeMinutes: jsonSerialization['defaultSnoozeMinutes'] as int?,
      quietHoursStart: jsonSerialization['quietHoursStart'] as String?,
      quietHoursEnd: jsonSerialization['quietHoursEnd'] as String?,
      voiceEnabled: jsonSerialization['voiceEnabled'] as bool?,
      timezone: jsonSerialization['timezone'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  int defaultSnoozeMinutes;

  String? quietHoursStart;

  String? quietHoursEnd;

  bool voiceEnabled;

  String timezone;

  /// Returns a shallow copy of this [UserSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSettings copyWith({
    int? id,
    _i1.UuidValue? userId,
    int? defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? voiceEnabled,
    String? timezone,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserSettings',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'defaultSnoozeMinutes': defaultSnoozeMinutes,
      if (quietHoursStart != null) 'quietHoursStart': quietHoursStart,
      if (quietHoursEnd != null) 'quietHoursEnd': quietHoursEnd,
      'voiceEnabled': voiceEnabled,
      'timezone': timezone,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserSettingsImpl extends UserSettings {
  _UserSettingsImpl({
    int? id,
    required _i1.UuidValue userId,
    int? defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? voiceEnabled,
    String? timezone,
  }) : super._(
         id: id,
         userId: userId,
         defaultSnoozeMinutes: defaultSnoozeMinutes,
         quietHoursStart: quietHoursStart,
         quietHoursEnd: quietHoursEnd,
         voiceEnabled: voiceEnabled,
         timezone: timezone,
       );

  /// Returns a shallow copy of this [UserSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserSettings copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    int? defaultSnoozeMinutes,
    Object? quietHoursStart = _Undefined,
    Object? quietHoursEnd = _Undefined,
    bool? voiceEnabled,
    String? timezone,
  }) {
    return UserSettings(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      quietHoursStart: quietHoursStart is String?
          ? quietHoursStart
          : this.quietHoursStart,
      quietHoursEnd: quietHoursEnd is String?
          ? quietHoursEnd
          : this.quietHoursEnd,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      timezone: timezone ?? this.timezone,
    );
  }
}
