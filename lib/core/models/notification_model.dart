import 'package:cloud_firestore/cloud_firestore.dart';

// Notification sent to a user when an admin changes their project's status.
class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String notificationId;
  final String userId;
  final String projectId;
  final String projectName;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final timestamp = json['createdAt'] as Timestamp?;
    return NotificationModel(
      notificationId: json['notificationId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? ''),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: timestamp?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'projectId': projectId,
      'projectName': projectName,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      projectId: projectId,
      projectName: projectName,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

enum NotificationType {
  projectApproved,
  projectRejected,
  projectRemoved,
}

NotificationType _parseType(String value) {
  switch (value) {
    case 'projectApproved':
      return NotificationType.projectApproved;
    case 'projectRejected':
      return NotificationType.projectRejected;
    case 'projectRemoved':
      return NotificationType.projectRemoved;
    default:
      return NotificationType.projectApproved;
  }
}
