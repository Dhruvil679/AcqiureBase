import 'package:flutter/foundation.dart';

import '../utils/firestore_timestamps.dart';

// Tracks what users do (login, save a project, etc.). Stored in
// activityLogs/{entryId} — separate from the admin-only audit log.
enum ActivityAction {
  login,
  projectPublished,
  projectEdited,
  projectSaved,
  projectUnsaved,
  profileUpdated;

  String get value => name;

  static ActivityAction fromString(String value) {
    return ActivityAction.values.firstWhere(
      (a) => a.name == value,
      orElse: () => ActivityAction.login,
    );
  }
}

@immutable
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.uid,
    required this.action,
    required this.timestamp,
    this.metadata = const {},
  });

  final String id;
  final String uid;
  final ActivityAction action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityLogEntry copyWith({
    String? id,
    String? uid,
    ActivityAction? action,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLogEntry(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'action': action.value,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      action: ActivityAction.fromString(json['action'] as String? ?? 'login'),
      timestamp: parseTimestamp(json['timestamp']) ?? DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

// Tracks changes made to a project, stored under
// projects/{projectId}/history/{historyEntryId}.
@immutable
class ProjectHistoryEntry {
  const ProjectHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.editedBy,
    this.changedFields = const [],
    this.previousValues = const {},
  });

  final String id;
  final DateTime timestamp;
  final String editedBy;
  final List<String> changedFields;
  final Map<String, dynamic> previousValues;

  ProjectHistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? editedBy,
    List<String>? changedFields,
    Map<String, dynamic>? previousValues,
  }) {
    return ProjectHistoryEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      editedBy: editedBy ?? this.editedBy,
      changedFields: changedFields ?? this.changedFields,
      previousValues: previousValues ?? this.previousValues,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'editedBy': editedBy,
    'changedFields': changedFields,
    'previousValues': previousValues,
  };

  factory ProjectHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ProjectHistoryEntry(
      id: json['id'] as String? ?? '',
      timestamp: parseTimestamp(json['timestamp']) ?? DateTime.now(),
      editedBy: json['editedBy'] as String? ?? '',
      changedFields:
          (json['changedFields'] as List<dynamic>?)?.cast<String>() ?? const [],
      previousValues:
          (json['previousValues'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
