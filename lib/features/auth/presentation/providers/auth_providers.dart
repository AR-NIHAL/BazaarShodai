import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider exposing [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider exposing [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider exposing the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// StreamProvider emitting Firebase [User] authentication status changes.
/// Use this to reactively determine whether a user is logged in or guest browsing.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// StreamProvider exposing the live [UserModel] profile document from Firestore.
final currentUserProfileStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUserStream;
});

/// FutureProvider that fetches the current user's profile on demand, re-evaluating on auth state changes.
final currentUserDataProvider = FutureProvider<UserModel?>((ref) async {
  // Re-run whenever auth status changes
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getCurrentUserData();
});
