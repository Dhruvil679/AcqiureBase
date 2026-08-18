import '../models/audit_log_entry.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';

// Fake backend for the demo / college project. The method names mirror
// Firestore operations so we can drop in a real backend later without
// rewriting every screen.
class MockDataService {
  const MockDataService._();

  // Demo user — set as admin so the admin panel is reachable without
  // faking a login flow every time.
  static UserModel currentUser = UserModel(
    uid: 'mock_user_001',
    username: 'alexbuilder',
    email: 'demo@gmail.com',
    firstName: 'Krishh',
    lastName: 'Builder',
    displayName: 'Alex Builder',
    age: 28,
    skills: const ['Flutter', 'Product Management', 'UI/UX Design'],
    profession: Profession.founder,
    photoUrl: '',
    bio: 'Indie maker building tools for other makers.',
    socialLinks: const SocialLinks(
      twitter: 'https://twitter.com/alexbuilder',
      linkedin: 'https://linkedin.com/in/alexbuilder',
      website: 'https://alexbuilder.dev',
    ),
    role: 'admin',
    isSuspended: false,
    createdAt: DateTime(2025, 6, 15),
    profileViews: 128,
    publishedProjectIds: const ['proj_001', 'proj_002'],
    savedProjectIds: const ['proj_003', 'proj_005'],
  );

  // Extra fake accounts so admin screens and stats have something to show.
  static final List<UserModel> _users = [
    currentUser,
    UserModel(
      uid: 'mock_user_002',
      username: 'jordanlee',
      email: 'jordan@acquirebase.app',
      firstName: 'Jordan',
      lastName: 'Lee',
      displayName: 'Jordan Lee',
      age: 34,
      skills: const ['Next.js', 'SaaS', 'Marketing'],
      profession: Profession.founder,
      role: 'user',
      isSuspended: false,
      createdAt: DateTime(2025, 5, 10),
      profileViews: 412,
      publishedProjectIds: const ['proj_003'],
    ),

    UserModel(
      uid: 'mock_user_003',
      username: 'samrivera',
      email: 'sam@acquirebase.app',
      firstName: 'Sam',
      lastName: 'Rivera',
      displayName: 'Sam Rivera',
      age: 41,
      skills: const ['Healthcare', 'Privacy', 'Product'],
      profession: Profession.employee,
      role: 'user',
      isSuspended: false,
      createdAt: DateTime(2025, 7, 22),
      profileViews: 89,
      publishedProjectIds: const ['proj_004'],
    ),
    UserModel(
      uid: 'mock_user_004',
      username: 'taylorkim',
      email: 'taylor@acquirebase.app',
      firstName: 'Taylor',
      lastName: 'Kim',
      displayName: 'Taylor Kim',
      age: 29,
      skills: const ['Marketing', 'Copywriting', 'AI'],
      profession: Profession.founder,
      role: 'user',
      isSuspended: true,
      createdAt: DateTime(2025, 4, 5),
      profileViews: 256,
      publishedProjectIds: const ['proj_005'],
    ),
    UserModel(
      uid: 'mock_user_005',
      username: 'morgannchen',
      email: 'morgan@acquirebase.app',
      firstName: 'Morgan',
      lastName: 'Chen',
      displayName: 'Morgan Chen',
      age: 31,
      skills: const ['Education', 'Design', 'Flutter'],
      profession: Profession.employee,
      role: 'user',
      isSuspended: false,
      createdAt: DateTime(2025, 8, 12),
      profileViews: 64,
      publishedProjectIds: const ['proj_006'],
    ),
    UserModel(
      uid: 'mock_user_006',
      username: 'caseydev',
      email: 'casey@acquirebase.app',
      firstName: 'Casey',
      lastName: 'Dev',
      displayName: 'Casey Dev',
      age: 24,
      skills: const ['Python', 'AI Tools'],
      profession: Profession.student,
      role: 'user',
      isSuspended: false,
      createdAt: DateTime(2025, 10, 28),
      profileViews: 12,
      publishedProjectIds: const ['proj_007'],
    ),
  ];

  static final List<ProjectModel> _projects = [
    ProjectModel(
      projectId: 'proj_001',
      ownerId: 'mock_user_001',
      name: 'TaskFlow',
      tagline: 'AI-powered project management for remote teams.',
      description: 'TaskFlow uses LLMs to summarize standups, prioritize tasks, and surface blockers automatically.',
      category: ProjectCategory.productivity,
      websiteUrl: 'https://taskflow.example',
      businessAge: '2 years',
      monthlyVisitors: '12K',
      founderName: 'Alex Builder',
      founderBio: 'Previously PM at a productivity startup.',
      status: 'approved',
      isFeatured: true,
      createdAt: DateTime(2025, 8, 1),
      saveCount: 47,
      viewCount: 1203,
    ),
    ProjectModel(
      projectId: 'proj_002',
      ownerId: 'mock_user_001',
      name: 'CodeBuddy',
      tagline: 'Pair-program with an AI that understands your codebase.',
      description: 'CodeBuddy indexes your repo and offers contextual suggestions, reviews, and refactoring.',
      category: ProjectCategory.developerTools,
      websiteUrl: 'https://codebuddy.example',
      businessAge: '1 year',
      monthlyVisitors: '8K',
      founderName: 'Alex Builder',
      founderBio: 'Indie maker building tools for other makers.',
      status: 'approved',
      isFeatured: false,
      createdAt: DateTime(2025, 9, 10),
      saveCount: 23,
      viewCount: 654,
    ),
    ProjectModel(
      projectId: 'proj_003',
      ownerId: 'mock_user_002',
      name: 'SaaS Starter Kit',
      tagline: 'Launch your SaaS in days, not months.',
      description: 'A production-ready Next.js template with auth, billing, and admin dashboards.',
      category: ProjectCategory.saas,
      websiteUrl: 'https://saasstarter.example',
      businessAge: '3 years',
      monthlyVisitors: '45K',
      founderName: 'Jordan Lee',
      founderBio: 'Full-stack dev and serial SaaS founder.',
      status: 'approved',
      isFeatured: true,
      createdAt: DateTime(2025, 5, 20),
      saveCount: 312,
      viewCount: 8900,
    ),
    ProjectModel(
      projectId: 'proj_004',
      ownerId: 'mock_user_003',
      name: 'HealthTrack',
      tagline: 'Privacy-first health metrics dashboard.',
      description: 'Track vitals, lab results, and trends without sending data to the cloud.',
      category: ProjectCategory.healthcare,
      websiteUrl: 'https://healthtrack.example',
      businessAge: '6 months',
      monthlyVisitors: '3K',
      founderName: 'Sam Rivera',
      founderBio: 'Physician and privacy advocate.',
      status: 'approved',
      isFeatured: false,
      createdAt: DateTime(2025, 10, 5),
      saveCount: 18,
      viewCount: 430,
    ),
    ProjectModel(
      projectId: 'proj_005',
      ownerId: 'mock_user_004',
      name: 'MarketMind',
      tagline: 'AI marketing copy that converts.',
      description: 'Generate ad copy, emails, and landing pages trained on your brand voice.',
      category: ProjectCategory.marketing,
      websiteUrl: 'https://marketmind.example',
      businessAge: '1.5 years',
      monthlyVisitors: '22K',
      founderName: 'Taylor Kim',
      founderBio: 'Marketing lead turned indie hacker.',
      status: 'approved',
      isFeatured: true,
      createdAt: DateTime(2025, 7, 12),
      saveCount: 89,
      viewCount: 2100,
    ),
    ProjectModel(
      projectId: 'proj_006',
      ownerId: 'mock_user_005',
      name: 'EduSpark',
      tagline: 'Micro-learning for busy professionals.',
      description: 'Five-minute interactive lessons delivered daily.',
      category: ProjectCategory.education,
      websiteUrl: 'https://eduspark.example',
      businessAge: '8 months',
      monthlyVisitors: '5K',
      founderName: 'Morgan Chen',
      founderBio: 'Educator and product designer.',
      status: 'approved',
      isFeatured: false,
      createdAt: DateTime(2025, 9, 1),
      saveCount: 12,
      viewCount: 320,
    ),
    // Left pending on purpose — it should NOT show up in public feeds.
    ProjectModel(
      projectId: 'proj_007',
      ownerId: 'mock_user_006',
      name: 'Pending Project',
      tagline: 'This project is awaiting moderation.',
      category: ProjectCategory.aiTools,
      status: 'pending',
      createdAt: DateTime(2025, 11, 1),
    ),
  ];

  // In-memory audit log. In production this would live in Firestore or Cloud
  // Logging so admins can't tamper with it locally.
  static final List<AuditLogEntry> _auditLog = [
    AuditLogEntry(
      id: 'log_001',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'approved project',
      targetType: 'project',
      targetId: 'proj_003',
      targetName: 'SaaS Starter Kit',
    ),
    AuditLogEntry(
      id: 'log_002',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'suspended user',
      targetType: 'user',
      targetId: 'mock_user_004',
      targetName: 'Taylor Kim',
    ),
    AuditLogEntry(
      id: 'log_003',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'rejected project',
      targetType: 'project',
      targetId: 'proj_008',
      targetName: 'Spam Launcher',
      reason: 'Violates submission guidelines',
    ),
  ];

  // Audit log helpers

  static List<AuditLogEntry> getAuditLog() {
    final sorted = List<AuditLogEntry>.from(_auditLog);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  static Future<void> logAdminAction({
    required String adminUid,
    required String adminName,
    required String action,
    required String targetType,
    required String targetId,
    required String targetName,
    String? reason,
  }) async {
    _auditLog.add(
      AuditLogEntry(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        adminUid: adminUid,
        adminName: adminName,
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        reason: reason,
      ),
    );
  }

  // User helpers

  // Mirrors a users collection query.
  static List<UserModel> getAllUsers() {
    return List.from(_users);
  }

  // Mirrors users/{uid} get.
  static UserModel? getUserById(String uid) {
    try {
      return _users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // Mirrors users/{uid} update. role/isSuspended shouldn't be editable from
  // the client — those are admin-only fields.
  static Future<void> updateUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.uid == user.uid);
    if (index == -1) return;
    _users[index] = user;
  }

  // Mirrors setting isSuspended=true.
  static Future<void> suspendUser(String uid) async {
    final user = getUserById(uid);
    if (user == null) return;
    await updateUser(user.copyWith(isSuspended: true));
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'suspended user',
      targetType: 'user',
      targetId: user.uid,
      targetName: user.displayName,
    );
  }

  // Mirrors setting isSuspended=false.
  static Future<void> activateUser(String uid) async {
    final user = getUserById(uid);
    if (user == null) return;
    await updateUser(user.copyWith(isSuspended: false));
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'activated user',
      targetType: 'user',
      targetId: user.uid,
      targetName: user.displayName,
    );
  }

  // Mirrors a Cloud Function that adds an admin custom claim.
  static Future<void> promoteUser(String uid) async {
    final user = getUserById(uid);
    if (user == null) return;
    await updateUser(user.copyWith(role: 'admin'));
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'promoted user to admin',
      targetType: 'user',
      targetId: user.uid,
      targetName: user.displayName,
    );
  }

  // Mirrors a Cloud Function that clears the admin custom claim.
  static Future<void> demoteUser(String uid) async {
    final user = getUserById(uid);
    if (user == null) return;
    await updateUser(user.copyWith(role: 'user'));
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'demoted user to user',
      targetType: 'user',
      targetId: user.uid,
      targetName: user.displayName,
    );
  }

  // Mirrors deleting a user through the Admin SDK or a callable function.
  static Future<void> deleteUser(String uid) async {
    final user = getUserById(uid);
    if (user == null) return;
    _users.removeWhere((u) => u.uid == uid);
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'deleted user',
      targetType: 'user',
      targetId: user.uid,
      targetName: user.displayName,
    );
  }

  // Stats helpers

  static int get totalUsers => _users.length;

  static int get suspendedUsers => _users.where((u) => u.isSuspended).length;

  // Rough "active" count — in a real app we'd use lastSignInTime.
  static int get activeUsers {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _users.where((u) => u.createdAt?.isAfter(cutoff) ?? false).length;
  }

  static int get totalProjects => _projects.length;

  static int countProjectsByStatus(String status) =>
      _projects.where((p) => p.status == status).length;

  static int get featuredProjects =>
      _projects.where((p) => p.status == 'approved' && p.isFeatured).length;

  static Map<ProjectCategory, int> get projectCountsByCategory {
    final counts = <ProjectCategory, int>{};
    for (final category in ProjectCategory.values) {
      counts[category] = 0;
    }
    for (final project in _projects) {
      counts[project.category] = (counts[project.category] ?? 0) + 1;
    }
    return counts;
  }

  // Project helpers

  // Mirrors projects/{projectId} get.
  static ProjectModel? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.projectId == projectId);
    } catch (_) {
      return null;
    }
  }

  // Mirrors creating projects/{projectId}.
  static Future<void> addProject(ProjectModel project) async {
    _projects.add(project);
  }

  // Mirrors updating projects/{projectId}.
  static Future<void> updateProject(ProjectModel project) async {
    final index = _projects.indexWhere((p) => p.projectId == project.projectId);
    if (index == -1) return;
    _projects[index] = project;
  }

  // Mirrors deleting projects/{projectId}.
  static Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.projectId == projectId);
  }

  // Mirrors a projects collection query.
  static List<ProjectModel> getAllProjects() {
    return List.from(_projects);
  }

  // Mirrors a query where status == pending.
  static List<ProjectModel> getPendingProjects() {
    return _projects.where((p) => p.status == 'pending').toList();
  }

  // Mirrors setting status=approved.
  static Future<void> approveProject(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(status: 'approved');
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'approved project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
    );
  }

  // Mirrors setting status=rejected.
  static Future<void> rejectProject(String projectId, {String? reason}) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(status: 'rejected');
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'rejected project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
      reason: reason,
    );
  }

  // Mirrors setting status=approved again (re-approve).
  static Future<void> reapproveProject(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(status: 'approved');
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 're-approved project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
    );
  }

  // Mirrors setting isFeatured=true.
  static Future<void> featureProject(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(isFeatured: true);
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'featured project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
    );
  }

  // Mirrors setting isFeatured=false.
  static Future<void> unfeatureProject(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(isFeatured: false);
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'unfeatured project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
    );
  }

  // Mirrors setting status=removed.
  static Future<void> removeProject(String projectId, {String? reason}) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(status: 'removed');
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'removed project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
      reason: reason,
    );
  }

  // Mirrors setting status=approved again (restore).
  static Future<void> restoreProject(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;
    final project = _projects[index];
    _projects[index] = project.copyWith(status: 'approved');
    await logAdminAction(
      adminUid: currentUser.uid,
      adminName: currentUser.displayName,
      action: 'restored project',
      targetType: 'project',
      targetId: project.projectId,
      targetName: project.name,
    );
  }

  // Mirrors a query where status == approved.
  static List<ProjectModel> getApprovedProjects() {
    return _projects.where((p) => p.status == 'approved').toList();
  }

  // Mirrors full-text search. A real app would use Algolia or a backend
  // Cloud Function instead of fetching everything.
  static List<ProjectModel> searchApprovedProjects(String query) {
    final lowered = query.toLowerCase();
    return _projects.where((p) {
      if (p.status != 'approved') return false;
      return p.name.toLowerCase().contains(lowered) ||
          p.tagline.toLowerCase().contains(lowered);
    }).toList();
  }

  // Mirrors a query filtering by category and status == approved.
  static List<ProjectModel> getProjectsByCategory(ProjectCategory category) {
    return _projects.where((p) {
      return p.status == 'approved' && p.category == category;
    }).toList();
  }

  // Mirrors a query where isFeatured == true and status == approved.
  static List<ProjectModel> getFeaturedProjects() {
    return _projects.where((p) => p.status == 'approved' && p.isFeatured).toList();
  }

  // Mirrors a query where ownerId == currentUser.uid.
  static List<ProjectModel> getCurrentUserProjects() {
    return _projects.where((p) => p.ownerId == currentUser.uid).toList();
  }

  // Mirrors reading saved_projects/{uid}_{projectId} and resolving the actual
  // project documents.
  static List<ProjectModel> getSavedProjects() {
    final savedIds = currentUser.savedProjectIds.toSet();
    return _projects.where((p) => savedIds.contains(p.projectId)).toList();
  }

  // Mirrors writing/deleting saved_projects/{uid}_{projectId}.
  static Future<void> toggleSavedProject(String projectId) async {
    final savedIds = List<String>.from(currentUser.savedProjectIds);
    if (savedIds.contains(projectId)) {
      savedIds.remove(projectId);
    } else {
      savedIds.add(projectId);
    }
    currentUser = currentUser.copyWith(savedProjectIds: savedIds);
  }

  // Mirrors updating users/{uid}. role/isSuspension are admin-only, so a real
  // update call would reject them on the server.
  static Future<UserModel> updateCurrentUser({
    String? displayName,
    String? bio,
    SocialLinks? socialLinks,
    String? photoUrl,
  }) async {
    // Just returns a fresh copy; the real implementation will write to Firestore.
    return currentUser.copyWith(
      displayName: displayName,
      bio: bio,
      socialLinks: socialLinks,
      photoUrl: photoUrl,
    );
  }
}
