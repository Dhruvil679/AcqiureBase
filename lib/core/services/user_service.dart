import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'auth_service.dart';

// Thrown when the chosen username is already reserved in the usernames collection.
class UsernameAlreadyTakenException implements Exception {
  const UsernameAlreadyTakenException(this.username);

  final String username;

  @override
  String toString() => 'Username "$username" is already taken.';
}

// Creates the user document in Firestore right after sign-up.
// Also reserves the username atomically in the usernames collection so no two
// users can claim the same username.
class UserService {
  const UserService(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  // Lowercase, trimmed usernames keep the lookup case-insensitive.
  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  // Matches the rule format in firestore.rules.
  static bool isValidUsername(String username) {
    final normalized = normalizeUsername(username);
    if (normalized.length < 3 || normalized.length > 20) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(normalized);
  }

  // Quick advisory check used by the register screen. The real enforcement
  // happens inside the signup transaction.
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = normalizeUsername(username);
    if (!isValidUsername(normalized)) return false;

    final doc = await _usernames.doc(normalized).get();
    return !doc.exists;
  }

  // Creates the user profile doc after sign up. Runs in a transaction so the
  // username reservation and user doc are written atomically.
  Future<void> createUserDocument({
    required User user,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
    required List<String> skills,
    required Profession profession,
  }) async {
    final normalizedUsername = normalizeUsername(username);
    final userDoc = _users.doc(user.uid);
    final usernameDoc = _usernames.doc(normalizedUsername);

    // Make sure the Auth token is fresh before the Firestore transaction,
    // especially on web right after email/password sign-up.
    final token = await _authService.getIdToken(forceRefresh: true);
    if (token == null) {
      throw StateError('User is not authenticated');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final existingUsername = await transaction.get(usernameDoc);
        if (existingUsername.exists) {
          throw UsernameAlreadyTakenException(normalizedUsername);
        }

        final existingUser = await transaction.get(userDoc);
        if (existingUser.exists) return;

        final displayName = '$firstName $lastName'.trim();

        transaction.set(usernameDoc, {'uid': user.uid});
        transaction.set(userDoc, {
          'uid': user.uid,
          'username': normalizedUsername,
          'email': user.email,
          'firstName': firstName,
          'lastName': lastName,
          'displayName': displayName,
          'age': age,
          'skills': skills,
          'profession': profession.name,
          'photoUrl': user.photoURL ?? '',
          'bio': '',
          'socialLinks': {
            'twitter': '',
            'linkedin': '',
            'website': '',
          },
          'role': 'user',
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'profileViews': 0,
          'publishedProjectIds': <String>[],
          'savedProjectIds': <String>[],
        });
      });
    } on UsernameAlreadyTakenException {
      // The Auth account was already created. Roll it back so the user can
      // retry with a different username without hitting "email already in use".
      await _authService.deleteCurrentUser();
      rethrow;
    } on FirebaseException catch (e) {
      // If another user claimed the username in the middle of our transaction,
      // Firestore aborts it. Treat that the same as "username taken" and roll
      // back the Auth account. Network errors are rethrown without deletion so
      // the user can retry.
      final isNetworkError = e.code == 'unavailable' ||
          e.code == 'network-request-failed' ||
          e.code == 'deadline-exceeded';
      if (!isNetworkError) {
        await _authService.deleteCurrentUser();
      }
      if (e.code == 'aborted' || e.code == 'already-exists') {
        throw UsernameAlreadyTakenException(normalizedUsername);
      }
      rethrow;
    }
  }
}
