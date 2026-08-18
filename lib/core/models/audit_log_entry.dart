import 'package:flutter/foundation.dart';

import '../utils/firestore_timestamps.dart';

// One row in the audit log. In production this probably ends up in a
// Firestore collection or Cloud Logging, but mock mode keeps it in memory.
@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.adminUid,
    required this.adminName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.reason,
  });

  final String id;
  final DateTime timestamp;
  final String adminUid;
  final String adminName;
  final String action;
  final String targetType;
  final String targetId;
  final String targetName;
  final String? reason;

  AuditLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? adminUid,
    String? adminName,
    String? action,
    String? targetType,
    String? targetId,
    String? targetName,
    String? reason,
  }) {
    return AuditLogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      adminUid: adminUid ?? this.adminUid,
      adminName: adminName ?? this.adminName,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'adminUid': adminUid,
        'adminName': adminName,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'reason': reason,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      timestamp: parseTimestamp(json['timestamp']) ?? DateTime.now(),
      adminUid: json['adminUid'] as String,
      adminName: json['adminName'] as String,
      action: json['action'] as String,
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as String,
      targetName: json['targetName'] as String,
      reason: json['reason'] as String?,
    );
  }
}
