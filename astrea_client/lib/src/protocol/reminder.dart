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
    this.snoozedUntilUtc,
    bool? isCompleted,
    int? priority,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : isCompleted = isCompleted ?? false,
       priority = priority ?? 2,
       revision = revision ?? 1,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Reminder({
    int? id,
    required _i1.UuidValue userId,
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntilUtc,
    bool? isCompleted,
    int? priority,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ReminderImpl;

  factory Reminder.fromJson(Map<String, dynamic> jsonSerialization) {
    return Reminder(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      dueAtUtc: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dueAtUtc'],
      ),
      originalTimezone: jsonSerialization['originalTimezone'] as String,
      repeatRule: jsonSerialization['repeatRule'] as String?,
      snoozedUntilUtc: jsonSerialization['snoozedUntilUtc'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['snoozedUntilUtc'],
            ),
      isCompleted: jsonSerialization['isCompleted'] as bool?,
      priority: jsonSerialization['priority'] as int?,
      revision: jsonSerialization['revision'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  String title;

  String? description;

  DateTime dueAtUtc;

  String originalTimezone;

  String? repeatRule;

  DateTime? snoozedUntilUtc;

  bool isCompleted;

  int priority;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Reminder copyWith({
    int? id,
    _i1.UuidValue? userId,
    String? title,
    String? description,
    DateTime? dueAtUtc,
    String? originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntilUtc,
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
      'userId': userId.toJson(),
      'title': title,
      if (description != null) 'description': description,
      'dueAtUtc': dueAtUtc.toJson(),
      'originalTimezone': originalTimezone,
      if (repeatRule != null) 'repeatRule': repeatRule,
      if (snoozedUntilUtc != null) 'snoozedUntilUtc': snoozedUntilUtc?.toJson(),
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
    required _i1.UuidValue userId,
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String originalTimezone,
    String? repeatRule,
    DateTime? snoozedUntilUtc,
    bool? isCompleted,
    int? priority,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         description: description,
         dueAtUtc: dueAtUtc,
         originalTimezone: originalTimezone,
         repeatRule: repeatRule,
         snoozedUntilUtc: snoozedUntilUtc,
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
    _i1.UuidValue? userId,
    String? title,
    Object? description = _Undefined,
    DateTime? dueAtUtc,
    String? originalTimezone,
    Object? repeatRule = _Undefined,
    Object? snoozedUntilUtc = _Undefined,
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
      snoozedUntilUtc: snoozedUntilUtc is DateTime?
          ? snoozedUntilUtc
          : this.snoozedUntilUtc,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
