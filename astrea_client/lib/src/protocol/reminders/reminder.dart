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

abstract class Reminder implements _i1.SerializableModel {
  Reminder._({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueAtUtc,
    required this.originalTimezone,
    this.repeatRule,
    this.snoozedUntil,
    required this.isCompleted,
    required this.priority,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder({
    int? id,
    required String userId,
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntil,
    required bool isCompleted,
    required int priority,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReminderImpl;

  factory Reminder.fromJson(Map<String, dynamic> jsonSerialization) {
    return Reminder(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      dueAtUtc: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dueAtUtc'],
      ),
      originalTimezone: jsonSerialization['originalTimezone'] as String,
      repeatRule: jsonSerialization['repeatRule'] as String?,
      snoozedUntil: jsonSerialization['snoozedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['snoozedUntil'],
            ),
      isCompleted: jsonSerialization['isCompleted'] as bool,
      priority: jsonSerialization['priority'] as int,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The user who owns this reminder (UUID string)
  String userId;

  /// The reminder title/summary
  String title;

  /// Optional detailed description
  String? description;

  /// Due date/time stored in UTC
  DateTime dueAtUtc;

  /// Original timezone when reminder was created (for DST handling)
  String originalTimezone;

  /// RRULE format for recurring reminders (optional)
  String? repeatRule;

  /// If snoozed, when to remind again
  DateTime? snoozedUntil;

  /// Whether the reminder has been completed
  bool isCompleted;

  /// Priority level: 1=low, 2=medium, 3=high
  int priority;

  /// Revision number for sync conflict resolution (last-write-wins)
  int revision;

  /// When the reminder was created
  DateTime createdAt;

  /// When the reminder was last updated
  DateTime updatedAt;

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Reminder copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueAtUtc,
    String? originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntil,
    bool? isCompleted,
    int? priority,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Reminder',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      'dueAtUtc': dueAtUtc.toJson(),
      'originalTimezone': originalTimezone,
      if (repeatRule != null) 'repeatRule': repeatRule,
      if (snoozedUntil != null) 'snoozedUntil': snoozedUntil?.toJson(),
      'isCompleted': isCompleted,
      'priority': priority,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReminderImpl extends Reminder {
  _ReminderImpl({
    int? id,
    required String userId,
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntil,
    required bool isCompleted,
    required int priority,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         description: description,
         dueAtUtc: dueAtUtc,
         originalTimezone: originalTimezone,
         repeatRule: repeatRule,
         snoozedUntil: snoozedUntil,
         isCompleted: isCompleted,
         priority: priority,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Reminder copyWith({
    Object? id = _Undefined,
    String? userId,
    String? title,
    Object? description = _Undefined,
    DateTime? dueAtUtc,
    String? originalTimezone,
    Object? repeatRule = _Undefined,
    Object? snoozedUntil = _Undefined,
    bool? isCompleted,
    int? priority,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      dueAtUtc: dueAtUtc ?? this.dueAtUtc,
      originalTimezone: originalTimezone ?? this.originalTimezone,
      repeatRule: repeatRule is String? ? repeatRule : this.repeatRule,
      snoozedUntil: snoozedUntil is DateTime?
          ? snoozedUntil
          : this.snoozedUntil,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
