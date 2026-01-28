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

abstract class ChatResponse implements _i1.SerializableModel {
  ChatResponse._({
    required this.intent,
    required this.response,
    bool? actionParsed,
    this.actionTitle,
    this.actionDueAtUtc,
    this.actionPriority,
    this.actionDescription,
    this.actionReminderId,
    this.actionSnoozeMinutes,
  }) : actionParsed = actionParsed ?? false;

  factory ChatResponse({
    required String intent,
    required String response,
    bool? actionParsed,
    String? actionTitle,
    DateTime? actionDueAtUtc,
    int? actionPriority,
    String? actionDescription,
    int? actionReminderId,
    int? actionSnoozeMinutes,
  }) = _ChatResponseImpl;

  factory ChatResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatResponse(
      intent: jsonSerialization['intent'] as String,
      response: jsonSerialization['response'] as String,
      actionParsed: jsonSerialization['actionParsed'] as bool?,
      actionTitle: jsonSerialization['actionTitle'] as String?,
      actionDueAtUtc: jsonSerialization['actionDueAtUtc'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['actionDueAtUtc'],
            ),
      actionPriority: jsonSerialization['actionPriority'] as int?,
      actionDescription: jsonSerialization['actionDescription'] as String?,
      actionReminderId: jsonSerialization['actionReminderId'] as int?,
      actionSnoozeMinutes: jsonSerialization['actionSnoozeMinutes'] as int?,
    );
  }

  String intent;

  String response;

  bool actionParsed;

  String? actionTitle;

  DateTime? actionDueAtUtc;

  int? actionPriority;

  String? actionDescription;

  int? actionReminderId;

  int? actionSnoozeMinutes;

  /// Returns a shallow copy of this [ChatResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatResponse copyWith({
    String? intent,
    String? response,
    bool? actionParsed,
    String? actionTitle,
    DateTime? actionDueAtUtc,
    int? actionPriority,
    String? actionDescription,
    int? actionReminderId,
    int? actionSnoozeMinutes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatResponse',
      'intent': intent,
      'response': response,
      'actionParsed': actionParsed,
      if (actionTitle != null) 'actionTitle': actionTitle,
      if (actionDueAtUtc != null) 'actionDueAtUtc': actionDueAtUtc?.toJson(),
      if (actionPriority != null) 'actionPriority': actionPriority,
      if (actionDescription != null) 'actionDescription': actionDescription,
      if (actionReminderId != null) 'actionReminderId': actionReminderId,
      if (actionSnoozeMinutes != null)
        'actionSnoozeMinutes': actionSnoozeMinutes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChatResponseImpl extends ChatResponse {
  _ChatResponseImpl({
    required String intent,
    required String response,
    bool? actionParsed,
    String? actionTitle,
    DateTime? actionDueAtUtc,
    int? actionPriority,
    String? actionDescription,
    int? actionReminderId,
    int? actionSnoozeMinutes,
  }) : super._(
         intent: intent,
         response: response,
         actionParsed: actionParsed,
         actionTitle: actionTitle,
         actionDueAtUtc: actionDueAtUtc,
         actionPriority: actionPriority,
         actionDescription: actionDescription,
         actionReminderId: actionReminderId,
         actionSnoozeMinutes: actionSnoozeMinutes,
       );

  /// Returns a shallow copy of this [ChatResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatResponse copyWith({
    String? intent,
    String? response,
    bool? actionParsed,
    Object? actionTitle = _Undefined,
    Object? actionDueAtUtc = _Undefined,
    Object? actionPriority = _Undefined,
    Object? actionDescription = _Undefined,
    Object? actionReminderId = _Undefined,
    Object? actionSnoozeMinutes = _Undefined,
  }) {
    return ChatResponse(
      intent: intent ?? this.intent,
      response: response ?? this.response,
      actionParsed: actionParsed ?? this.actionParsed,
      actionTitle: actionTitle is String? ? actionTitle : this.actionTitle,
      actionDueAtUtc: actionDueAtUtc is DateTime?
          ? actionDueAtUtc
          : this.actionDueAtUtc,
      actionPriority: actionPriority is int?
          ? actionPriority
          : this.actionPriority,
      actionDescription: actionDescription is String?
          ? actionDescription
          : this.actionDescription,
      actionReminderId: actionReminderId is int?
          ? actionReminderId
          : this.actionReminderId,
      actionSnoozeMinutes: actionSnoozeMinutes is int?
          ? actionSnoozeMinutes
          : this.actionSnoozeMinutes,
    );
  }
}
