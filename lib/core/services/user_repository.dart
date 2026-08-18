import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/paginated_result.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

// Talks to Firestore for user profiles. If Firebase isn't set up (e.g.
// desktop), falls back to mock data so the UI still works.
class UserRepository {
  const UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  bool get _useMock => Firebase.apps.isEmpty;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<UserModel?> watchUser(String uid) {
    if (_useMock) {
      return Stream.value(MockDataService.currentUser);
    }
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null,
        );
  }

  Future<UserModel?> getUserById(String uid) async {
    if (_useMock) {
      return MockDataService.getUserById(uid);
    }
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserModel.fromJson(doc.data()!) : null;
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String firstName,
    required String lastName,
    required int age,
    required Profession profession,
    required List<String> skills,
    required String bio,
    required String photoUrl,
    required Map<String, String> socialLinks,
  }) async {
    if (_useMock) {
      final user = MockDataService.currentUser.copyWith(
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        age: age,
        profession: profession,
        skills: skills,
        bio: bio,
        photoUrl: photoUrl,
        socialLinks: SocialLinks(
          twitter: socialLinks['twitter'] ?? '',
          linkedin: socialLinks['linkedin'] ?? '',
          website: socialLinks['website'] ?? '',
        ),
      );
      MockDataService.currentUser = user;
      return;
    }
    await _users.doc(uid).update({
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'profession': profession.name,
      'skills': skills,
      'bio': bio,
      'photoUrl': photoUrl,
      'socialLinks': socialLinks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementProfileViews(String uid) async {
    if (_useMock) {
      final user = MockDataService.getUserById(uid);
      if (user != null) {
        await MockDataService.updateUser(
          user.copyWith(profileViews: user.profileViews + 1),
        );
      }
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_users.doc(uid));
      if (!doc.exists) return;
      final current = (doc.data()?['profileViews'] as int?) ?? 0;
      transaction.update(_users.doc(uid), {'profileViews': current + 1});
    });
  }

  Future<void> updateRole({required String uid, required String role}) async {
    if (_useMock) {
      final user = MockDataService.getUserById(uid);
      if (user != null) {
        await MockDataService.updateUser(user.copyWith(role: role));
      }
      return;
    }
    await _users.doc(uid).update({'role': role});
  }

  Future<void> updateSuspension({
    required String uid,
    required bool isSuspended,
  }) async {
    if (_useMock) {
      final user = MockDataService.getUserById(uid);
      if (user != null) {
        await MockDataService.updateUser(user.copyWith(isSuspended: isSuspended));
      }
      return;
    }
    await _users.doc(uid).update({'isSuspended': isSuspended});
  }

  // Removes the user doc and, if known, the matching username reservation.
  Future<void> deleteUserWithCleanup(String uid) async {
    if (_useMock) {
      await MockDataService.deleteUser(uid);
      return;
    }

    final user = await getUserById(uid);
    final username = user?.username ?? '';

    await _users.doc(uid).delete();

    if (username.isNotEmpty) {
      try {
        await _firestore.collection('usernames').doc(username).delete();
      } catch (_) {
        // If the username doc is already gone or we can't reach it, the user
        // doc is gone which is the important part.
      }
    }
  }

  Stream<List<UserModel>> watchAllUsers() {
    if (_useMock) {
      return Stream.value(MockDataService.getAllUsers());
    }
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<PaginatedResult<UserModel>> fetchAllUsers({
    DocumentSnapshot? startAfter,
    int limit = 25,
  }) async {
    if (_useMock) {
      final all = MockDataService.getAllUsers();
      return PaginatedResult(
        items: all.take(limit).toList(),
        hasMore: all.length > limit,
      );
    }

    var query = _users
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<void> deleteUser(String uid) async {
    if (_useMock) {
      await MockDataService.deleteUser(uid);
      return;
    }
    await _users.doc(uid).delete();
  }
}
