import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/activity_log_entry.dart';

// Writes general user activity to Firestore. Falls back to mock data when
// Firebase isn't initialized.
class ActivityLogRepository {
  const ActivityLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection('activityLogs');

  Future<void> log({
    required String uid,
    required ActivityAction action,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (_useMock) return;

    await _activityLogs.add({
      'uid': uid,
      'action': action.value,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }

  Stream<List<ActivityLogEntry>> watchUserActivity(String uid) {
    if (_useMock) {
      return Stream.value([]);
    }
    return _activityLogs
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLogEntry.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }

  Stream<List<ActivityLogEntry>> watchAllActivity() {
    if (_useMock) {
      return Stream.value([]);
    }
    return _activityLogs
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLogEntry.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }
}
