import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/cloudinary_config.dart';
import '../services/project_functions_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'asia-southeast1');
});

final cloudinaryProvider = Provider<CloudinaryPublic>((ref) {
  return CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
    cache: false,
  );
});

final projectFunctionsServiceProvider = Provider<ProjectFunctionsService>((ref) {
  return ProjectFunctionsService(ref.watch(firebaseFunctionsProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(cloudinaryProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(
    ref.watch(firestoreProvider),
    ref.watch(authServiceProvider),
  );
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream of the current Firebase user. Screens watch this to redirect after
// sign-in or sign-out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});
