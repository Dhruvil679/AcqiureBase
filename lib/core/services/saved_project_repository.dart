import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/project_model.dart';
import 'mock_data_service.dart';

// Handles saved projects. Each saved record uses a composite doc ID like
// {uid}_{projectId}. Falls back to mock data when Firebase isn't initialized.
class SavedProjectRepository {
  const SavedProjectRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _saved =>
      _firestore.collection('saved_projects');

  String _docId(String uid, String projectId) => '${uid}_$projectId';

  Stream<List<ProjectModel>> watchSavedProjects(String uid) {
    if (_useMock) {
      return Stream.value(MockDataService.getSavedProjects());
    }
    return _saved
        .where('uid', isEqualTo: uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap(
          (snapshot) async {
            final projectIds = snapshot.docs
                .map((doc) => doc.data()['projectId'] as String)
                .toList();
            if (projectIds.isEmpty) return <ProjectModel>[];
            final projects = await _fetchProjectsByIds(projectIds);
            // Keep the saved order instead of the order Firestore returns.
            final byId = {for (final p in projects) p.projectId: p};
            return projectIds
                .where((id) => byId.containsKey(id))
                .map((id) => byId[id]!)
                .toList();
          },
        );
  }

  Future<List<ProjectModel>> _fetchProjectsByIds(List<String> ids) async {
    const chunkSize = 30; // Read in chunks so we don't hit Firestore query limits.
    final projects = <ProjectModel>[];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      final snapshot = await _firestore
          .collection('projects')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      projects.addAll(
        snapshot.docs.map((doc) => ProjectModel.fromJson(doc.data())),
      );
    }

    return projects;
  }

  Stream<Set<String>> watchSavedProjectIds(String uid) {
    if (_useMock) {
      return Stream.value(MockDataService.currentUser.savedProjectIds.toSet());
    }
    return _saved.where('uid', isEqualTo: uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['projectId'] as String)
              .toSet(),
        );
  }

  Future<bool> isSaved(String uid, String projectId) async {
    if (_useMock) {
      return MockDataService.currentUser.savedProjectIds.contains(projectId);
    }
    final doc = await _saved.doc(_docId(uid, projectId)).get();
    return doc.exists;
  }

  Future<void> toggleSave(String uid, String projectId) async {
    if (_useMock) {
      await MockDataService.toggleSavedProject(projectId);
      return;
    }
    final docId = _docId(uid, projectId);
    final docRef = _saved.doc(docId);
    final projectRef = _firestore.collection('projects').doc(projectId);

    await _firestore.runTransaction((transaction) async {
      final savedDoc = await transaction.get(docRef);
      final projectDoc = await transaction.get(projectRef);
      final currentSaveCount = (projectDoc.data()?['saveCount'] as int?) ?? 0;

      if (savedDoc.exists) {
        transaction.delete(docRef);
        if (currentSaveCount > 0) {
          transaction.update(projectRef, {'saveCount': currentSaveCount - 1});
        }
      } else {
        transaction.set(docRef, {
          'uid': uid,
          'projectId': projectId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(projectRef, {'saveCount': currentSaveCount + 1});
      }
    });
  }

  Future<void> removeSave(String uid, String projectId) async {
    if (_useMock) {
      await MockDataService.toggleSavedProject(projectId);
      return;
    }
    await _saved.doc(_docId(uid, projectId)).delete();
  }
}
