import 'package:cloud_functions/cloud_functions.dart';

import 'user_repository.dart';

// Calls admin-only Firebase Cloud Functions when they are deployed. On the
// Spark plan the functions are not available, so the service falls back to
// direct Firestore writes through the admin's own user repository.
class AdminFunctionsService {
  const AdminFunctionsService(this._functions, this._userRepository);

  final FirebaseFunctions _functions;
  final UserRepository _userRepository;

  HttpsCallable get _setAdminClaim => _functions.httpsCallable('setAdminClaim');
  HttpsCallable get _setUserSuspension =>
      _functions.httpsCallable('setUserSuspension');
  HttpsCallable get _deleteUserAccount =>
      _functions.httpsCallable('deleteUserAccount');

  Future<void> setAdminClaim({
    required String uid,
    required String role,
  }) async {
    try {
      await _setAdminClaim.call({'uid': uid, 'role': role});
    } on FirebaseFunctionsException catch (_) {
      await _userRepository.updateRole(uid: uid, role: role);
    }
  }

  Future<void> setUserSuspension({
    required String uid,
    required bool isSuspended,
  }) async {
    try {
      await _setUserSuspension.call({'uid': uid, 'isSuspended': isSuspended});
    } on FirebaseFunctionsException catch (_) {
      await _userRepository.updateSuspension(uid: uid, isSuspended: isSuspended);
    }
  }

  Future<void> deleteUserAccount({required String uid}) async {
    try {
      await _deleteUserAccount.call({'uid': uid});
    } on FirebaseFunctionsException catch (_) {
      await _userRepository.deleteUserWithCleanup(uid);
    }
  }
}
