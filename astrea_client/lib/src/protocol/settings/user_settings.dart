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
    required this.defaultSnoozeMinutes,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.voiceEnabled,
    required this.timezone,
  });

  factory UserSettings({
    int? id,
    required String userId,
    required int defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    required bool voiceEnabled,
    required String timezone,
  }) = _UserSettingsImpl;

  factory UserSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSettings(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      defaultSnoozeMinutes: jsonSerialization['defaultSnoozeMinutes'] as int,
      quietHoursStart: jsonSerialization['quietHoursStart'] as String?,
      quietHoursEnd: jsonSerialization['quietHoursEnd'] as String?,
      voiceEnabled: jsonSerialization['voiceEnabled'] as bool,
      timezone: jsonSerialization['timezone'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The user ID (UUID string) - unique per user
  String userId;

  /// Default snooze duration in minutes
  int defaultSnoozeMinutes;

  /// Quiet hours start time (e.g., "22:00")
  String? quietHoursStart;

  /// Quiet hours end time (e.g., "07:00")
  String? quietHoursEnd;

  /// Whether voice input is enabled
  bool voiceEnabled;

  /// User's timezone (e.g., "America/New_York")
  String timezone;

  /// Returns a shallow copy of this [UserSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSettings copyWith({
    int? id,
    String? userId,
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
      'userId': userId,
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
    required String userId,
    required int defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    required bool voiceEnabled,
    required String timezone,
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
    String? userId,
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
