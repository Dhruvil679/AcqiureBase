import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log_entry.dart';
import '../models/audit_log_entry.dart';
import '../models/notification_model.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/activity_log_repository.dart';
import '../services/admin_functions_service.dart';
import '../services/audit_log_repository.dart';
import '../services/notification_repository.dart';
import '../services/project_repository.dart';
import '../services/saved_project_repository.dart';
import '../services/user_repository.dart';
import 'auth_provider.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(firestoreProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

final adminFunctionsServiceProvider = Provider<AdminFunctionsService>((ref) {
  return AdminFunctionsService(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(userRepositoryProvider),
  );
});

final savedProjectRepositoryProvider = Provider<SavedProjectRepository>((ref) {
  return SavedProjectRepository(ref.watch(firestoreProvider));
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(firestoreProvider));
});

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ActivityLogRepository(ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

// Riverpod providers that wrap the repositories. Most screens watch these
// instead of calling the repositories directly.
final approvedProjectsProvider = StreamProvider.autoDispose
    .family<List<ProjectModel>, ProjectCategory?>((ref, category) {
  final repository = ref.watch(projectRepositoryProvider);
  if (category == null) return repository.watchApprovedProjects();
  return repository.watchProjectsByCategory(category);
});

final featuredProjectsProvider = StreamProvider.autoDispose
    <List<ProjectModel>>((ref) {
  return ref.watch(projectRepositoryProvider).watchFeaturedProjects();
});

final currentUserProjectsProvider = StreamProvider.autoDispose
    <List<ProjectModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).watchProjectsByOwner(uid);
});

final savedProjectsProvider = StreamProvider.autoDispose
    <List<ProjectModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(savedProjectRepositoryProvider).watchSavedProjects(uid);
});

final savedProjectIdsProvider = StreamProvider.autoDispose
    <Set<String>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value({});
  return ref.watch(savedProjectRepositoryProvider).watchSavedProjectIds(uid);
});

final currentUserProfileProvider = StreamProvider.autoDispose
    <UserModel?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllUsers();
});

final projectByIdProvider = StreamProvider.autoDispose
    .family<ProjectModel?, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).watchProjectById(projectId);
});

final userByIdProvider = StreamProvider.autoDispose
    .family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final projectsByOwnerProvider = StreamProvider.autoDispose
    .family<List<ProjectModel>, String>((ref, ownerId) {
  return ref.watch(projectRepositoryProvider).watchProjectsByOwner(ownerId);
});

final projectsByStatusProvider = StreamProvider.autoDispose
    .family<List<ProjectModel>, String>((ref, status) {
  if (status == 'all') {
    return ref.watch(projectRepositoryProvider).watchAllProjects();
  }
  return ref.watch(projectRepositoryProvider).watchProjectsByStatus(status);
});

final userActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityLogEntry>, String>((ref, uid) {
  return ref.watch(activityLogRepositoryProvider).watchUserActivity(uid);
});

final projectHistoryProvider = StreamProvider.autoDispose
    .family<List<ProjectHistoryEntry>, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).watchProjectHistory(projectId);
});

final auditLogProvider = StreamProvider.autoDispose
    <List<AuditLogEntry>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchAuditLog();
});

final auditLogForTargetProvider = StreamProvider.autoDispose
    .family<List<AuditLogEntry>, ({String targetType, String targetId})>((
  ref,
  args,
) {
  return ref
      .watch(auditLogRepositoryProvider)
      .watchAuditLogForTarget(targetType: args.targetType, targetId: args.targetId);
});

final notificationsProvider = StreamProvider.autoDispose
    <List<NotificationModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

final unreadNotificationsCountProvider = StreamProvider.autoDispose
    <int>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});
