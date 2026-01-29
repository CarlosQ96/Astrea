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
import 'package:serverpod/serverpod.dart' as _i1;
import 'reminder.dart' as _i2;
import 'package:astrea_server/src/generated/protocol.dart' as _i3;

abstract class ReminderSyncEvent
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ReminderSyncEvent._({
    required this.eventType,
    required this.reminderId,
    required this.userId,
    this.reminder,
    required this.timestamp,
  });

  factory ReminderSyncEvent({
    required String eventType,
    required int reminderId,
    required _i1.UuidValue userId,
    _i2.Reminder? reminder,
    required DateTime timestamp,
  }) = _ReminderSyncEventImpl;

  factory ReminderSyncEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReminderSyncEvent(
      eventType: jsonSerialization['eventType'] as String,
      reminderId: jsonSerialization['reminderId'] as int,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      reminder: jsonSerialization['reminder'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Reminder>(
              jsonSerialization['reminder'],
            ),
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  String eventType;

  int reminderId;

  _i1.UuidValue userId;

  _i2.Reminder? reminder;

  DateTime timestamp;

  /// Returns a shallow copy of this [ReminderSyncEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReminderSyncEvent copyWith({
    String? eventType,
    int? reminderId,
    _i1.UuidValue? userId,
    _i2.Reminder? reminder,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReminderSyncEvent',
      'eventType': eventType,
      'reminderId': reminderId,
      'userId': userId.toJson(),
      if (reminder != null) 'reminder': reminder?.toJson(),
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReminderSyncEvent',
      'eventType': eventType,
      'reminderId': reminderId,
      'userId': userId.toJson(),
      if (reminder != null) 'reminder': reminder?.toJsonForProtocol(),
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReminderSyncEventImpl extends ReminderSyncEvent {
  _ReminderSyncEventImpl({
    required String eventType,
    required int reminderId,
    required _i1.UuidValue userId,
    _i2.Reminder? reminder,
    required DateTime timestamp,
  }) : super._(
         eventType: eventType,
         reminderId: reminderId,
         userId: userId,
         reminder: reminder,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [ReminderSyncEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReminderSyncEvent copyWith({
    String? eventType,
    int? reminderId,
    _i1.UuidValue? userId,
    Object? reminder = _Undefined,
    DateTime? timestamp,
  }) {
    return ReminderSyncEvent(
      eventType: eventType ?? this.eventType,
      reminderId: reminderId ?? this.reminderId,
      userId: userId ?? this.userId,
      reminder: reminder is _i2.Reminder?
          ? reminder
          : this.reminder?.copyWith(),
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
