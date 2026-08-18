import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/audit_log_entry.dart';
import 'mock_data_service.dart';

// Writes audit log entries to Firestore. Falls back to mock data when Firebase
// isn't initialized.
class AuditLogRepository {
  const AuditLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('auditLogs');

  Stream<List<AuditLogEntry>> watchAuditLog() {
    if (_useMock) {
      return Stream.value(MockDataService.getAuditLog());
    }
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogEntry.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<AuditLogEntry>> watchAuditLogForTarget({
    required String targetType,
    required String targetId,
  }) {
    if (_useMock) {
      return Stream.value([]);
    }
    return _auditLogs
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogEntry.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> log({
    required String adminUid,
    required String adminName,
    required String action,
    required String targetType,
    required String targetId,
    required String targetName,
    String? reason,
  }) async {
    if (_useMock) {
      await MockDataService.logAdminAction(
        adminUid: adminUid,
        adminName: adminName,
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        reason: reason,
      );
      return;
    }
    await _auditLogs.add({
      'adminUid': adminUid,
      'adminName': adminName,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
