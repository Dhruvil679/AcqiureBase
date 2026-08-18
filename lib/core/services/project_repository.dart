import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/activity_log_entry.dart';
import '../models/paginated_result.dart';
import '../models/project_model.dart';
import 'mock_data_service.dart';

// Talks to Firestore for project data. If Firebase isn't set up (e.g.
// desktop), falls back to mock data so the UI still works.
class ProjectRepository {
  const ProjectRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection('projects');

  Stream<List<ProjectModel>> watchApprovedProjects() {
    if (_useMock) {
      return Stream.value(MockDataService.getApprovedProjects());
    }
    return _projects
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<ProjectModel>> watchFeaturedProjects() {
    if (_useMock) {
      return Stream.value(MockDataService.getFeaturedProjects());
    }
    return _projects
        .where('status', isEqualTo: 'approved')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<ProjectModel>> watchProjectsByCategory(ProjectCategory category) {
    if (_useMock) {
      return Stream.value(MockDataService.getProjectsByCategory(category));
    }
    return _projects
        .where('status', isEqualTo: 'approved')
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<ProjectModel>> watchProjectsByOwner(String ownerId) {
    if (_useMock) {
      return Stream.value(MockDataService.getCurrentUserProjects());
    }
    return _projects
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<ProjectModel?> getProjectById(String projectId) async {
    if (_useMock) {
      return MockDataService.getProjectById(projectId);
    }
    final doc = await _projects.doc(projectId).get();
    return doc.exists ? ProjectModel.fromJson(doc.data()!) : null;
  }

  Stream<ProjectModel?> watchProjectById(String projectId) {
    if (_useMock) {
      return Stream.value(MockDataService.getProjectById(projectId));
    }
    return _projects.doc(projectId).snapshots().map(
          (doc) => doc.exists ? ProjectModel.fromJson(doc.data()!) : null,
        );
  }

  Future<List<ProjectModel>> searchApprovedProjects(String query) async {
    final lowered = query.toLowerCase();
    if (_useMock) {
      return MockDataService.searchApprovedProjects(query);
    }
    // Firestore has no native full-text search, so for this demo we just
    // fetch approved projects and filter locally. In production we'd swap this
    // for Algolia or a search Cloud Function.
    final snapshot = await _projects
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => ProjectModel.fromJson(doc.data()))
        .where((p) =>
            p.name.toLowerCase().contains(lowered) ||
            p.tagline.toLowerCase().contains(lowered))
        .toList();
  }

  Future<PaginatedResult<ProjectModel>> fetchApprovedProjects({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (_useMock) {
      final all = MockDataService.getApprovedProjects();
      return PaginatedResult(
        items: all.take(limit).toList(),
        hasMore: all.length > limit,
      );
    }

    var query = _projects
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => ProjectModel.fromJson(doc.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<PaginatedResult<ProjectModel>> fetchFeaturedProjects({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (_useMock) {
      final all = MockDataService.getFeaturedProjects();
      return PaginatedResult(
        items: all.take(limit).toList(),
        hasMore: all.length > limit,
      );
    }

    var query = _projects
        .where('status', isEqualTo: 'approved')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => ProjectModel.fromJson(doc.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<PaginatedResult<ProjectModel>> fetchProjectsByCategory(
    ProjectCategory category, {
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (_useMock) {
      final all = MockDataService.getProjectsByCategory(category);
      return PaginatedResult(
        items: all.take(limit).toList(),
        hasMore: all.length > limit,
      );
    }

    var query = _projects
        .where('status', isEqualTo: 'approved')
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => ProjectModel.fromJson(doc.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<PaginatedResult<ProjectModel>> fetchProjectsByStatus(
    String status, {
    DocumentSnapshot? startAfter,
    int limit = 25,
  }) async {
    if (_useMock) {
      final all = MockDataService.getAllProjects()
          .where((p) => p.status == status)
          .toList();
      return PaginatedResult(
        items: all.take(limit).toList(),
        hasMore: all.length > limit,
      );
    }

    var query = status == 'all'
        ? _projects.orderBy('createdAt', descending: true).limit(limit)
        : _projects
            .where('status', isEqualTo: status)
            .orderBy('createdAt', descending: true)
            .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => ProjectModel.fromJson(doc.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<void> createProject(ProjectModel project) async {
    if (_useMock) {
      await MockDataService.addProject(project);
      return;
    }
    final json = project.toJson()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _projects.doc(project.projectId).set(json);
  }

  Future<void> updateProject(
    ProjectModel project, {
    String? editedBy,
  }) async {
    if (_useMock) {
      await MockDataService.updateProject(project);
      return;
    }

    final oldDoc = await _projects.doc(project.projectId).get();
    final oldProject =
        oldDoc.exists ? ProjectModel.fromJson(oldDoc.data()!) : null;
    final diff = _computeDiff(oldProject, project);

    final json = project.toJson()
      ..remove('projectId')
      ..remove('ownerId')
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _projects.doc(project.projectId).update(json);

    if (diff.changedFields.isNotEmpty) {
      await _projects
          .doc(project.projectId)
          .collection('history')
          .add(diff.toJson(editedBy: editedBy ?? ''));
    }
  }

  _ProjectDiff _computeDiff(ProjectModel? oldProject, ProjectModel newProject) {
    if (oldProject == null) {
      return const _ProjectDiff(changedFields: [], previousValues: {});
    }

    final changedFields = <String>[];
    final previousValues = <String, dynamic>{};

    void checkField(String name, dynamic oldValue, dynamic newValue) {
      if (oldValue != newValue) {
        changedFields.add(name);
        previousValues[name] = oldValue;
      }
    }

    checkField('name', oldProject.name, newProject.name);
    checkField('tagline', oldProject.tagline, newProject.tagline);
    checkField('description', oldProject.description, newProject.description);
    checkField('category', oldProject.category.name, newProject.category.name);
    checkField('websiteUrl', oldProject.websiteUrl, newProject.websiteUrl);
    checkField('businessAge', oldProject.businessAge, newProject.businessAge);
    checkField(
      'monthlyVisitors',
      oldProject.monthlyVisitors,
      newProject.monthlyVisitors,
    );
    checkField('founderName', oldProject.founderName, newProject.founderName);
    checkField('founderBio', oldProject.founderBio, newProject.founderBio);
    checkField('logoUrl', oldProject.logoUrl, newProject.logoUrl);
    checkField(
      'screenshotUrls',
      oldProject.screenshotUrls,
      newProject.screenshotUrls,
    );
    checkField(
      'documentUrls',
      oldProject.documentUrls,
      newProject.documentUrls,
    );

    return _ProjectDiff(
      changedFields: changedFields,
      previousValues: previousValues,
    );
  }

  Stream<List<ProjectHistoryEntry>> watchProjectHistory(String projectId) {
    if (_useMock) {
      return Stream.value([]);
    }
    return _projects
        .doc(projectId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectHistoryEntry.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }

  Future<void> deleteProject(String projectId) async {
    if (_useMock) {
      await MockDataService.deleteProject(projectId);
      return;
    }
    await _projects.doc(projectId).delete();
  }

  Future<void> adjustSaveCount(String projectId, {required int delta}) async {
    if (_useMock) {
      final project = MockDataService.getProjectById(projectId);
      if (project == null) return;
      final updated = project.saveCount + delta < 0 ? 0 : project.saveCount + delta;
      await MockDataService.updateProject(project.copyWith(saveCount: updated));
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_projects.doc(projectId));
      if (!doc.exists) return;
      final current = (doc.data()?['saveCount'] as int?) ?? 0;
      final updated = current + delta < 0 ? 0 : current + delta;
      transaction.update(_projects.doc(projectId), {'saveCount': updated});
    });
  }

  Future<void> incrementViewCount(String projectId) async {
    if (_useMock) {
      final project = MockDataService.getProjectById(projectId);
      if (project == null) return;
      await MockDataService.updateProject(
        project.copyWith(viewCount: project.viewCount + 1),
      );
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_projects.doc(projectId));
      if (!doc.exists) return;
      final current = (doc.data()?['viewCount'] as int?) ?? 0;
      transaction.update(_projects.doc(projectId), {'viewCount': current + 1});
    });
  }

  Stream<List<ProjectModel>> watchAllProjects() {
    if (_useMock) {
      return Stream.value(MockDataService.getAllProjects());
    }
    return _projects
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<ProjectModel>> watchProjectsByStatus(String status) {
    if (_useMock) {
      return Stream.value(
        MockDataService.getAllProjects().where((p) => p.status == status).toList(),
      );
    }
    return _projects
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> updateProjectStatus({
    required String projectId,
    required String status,
  }) async {
    if (_useMock) {
      final project = MockDataService.getProjectById(projectId);
      if (project == null) return;
      await MockDataService.updateProject(project.copyWith(status: status));
      return;
    }
    await _projects.doc(projectId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setFeatured({
    required String projectId,
    required bool isFeatured,
  }) async {
    if (_useMock) {
      final project = MockDataService.getProjectById(projectId);
      if (project == null) return;
      await MockDataService.updateProject(project.copyWith(isFeatured: isFeatured));
      return;
    }
    await _projects.doc(projectId).update({
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _ProjectDiff {
  const _ProjectDiff({
    required this.changedFields,
    required this.previousValues,
  });

  final List<String> changedFields;
  final Map<String, dynamic> previousValues;

  Map<String, dynamic> toJson({required String editedBy}) => {
    'timestamp': FieldValue.serverTimestamp(),
    'editedBy': editedBy,
    'changedFields': changedFields,
    'previousValues': previousValues,
  };
}
