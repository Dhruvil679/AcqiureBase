import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/notification_model.dart';

// Talks to Firestore for notifications. Falls back to mock data when Firebase
// isn't initialized.
class NotificationRepository {
  const NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    if (_useMock) return Stream.value([]);

    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromJson({'notificationId': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  Stream<int> watchUnreadCount(String userId) {
    if (_useMock) return Stream.value(0);

    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    if (_useMock) return;
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> notifyProjectStatus({
    required String userId,
    required String projectId,
    required String projectName,
    required String status,
  }) async {
    final NotificationType type;
    final String title;
    final String body;

    switch (status) {
      case 'approved':
        type = NotificationType.projectApproved;
        title = 'Project approved';
        body = '"$projectName" is now live on AcquireBase.';
      case 'rejected':
        type = NotificationType.projectRejected;
        title = 'Project rejected';
        body = '"$projectName" did not meet our guidelines. You can edit and resubmit.';
      case 'removed':
        type = NotificationType.projectRemoved;
        title = 'Project removed';
        body = '"$projectName" has been removed from public view.';
      default:
        return;
    }

    await createNotification(
      NotificationModel(
        notificationId: '',
        userId: userId,
        projectId: projectId,
        projectName: projectName,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> createNotification(NotificationModel notification) async {
    if (_useMock) return;

    final docRef = _notifications.doc();
    final json = notification.toJson()
      ..['notificationId'] = docRef.id
      ..['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(json);
  }
}
