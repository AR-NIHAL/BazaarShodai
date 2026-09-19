import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// User-friendly exception representing authentication failures.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Firebase implementation of [AuthRepository].
/// Handles customer authentication, seller onboarding with `/users/{uid}` Firestore document creation, and role validation.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Stream<UserModel?> get currentUserStream {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _usersCollection.doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, documentId: doc.id);
        }
        return null;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Registration failed: No user account created.');
      }

      // Update Firebase Auth display name
      await user.updateDisplayName(name.trim());

      // Create Firestore User Document with default 'customer' role
      final newUser = UserModel(
        uid: user.uid,
        email: email.trim(),
        name: name.trim(),
        role: UserRole.customer,
        isApproved: true,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(user.uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpSellerWithEmail({
    required String email,
    required String password,
    required String name,
    required ShopDetails shopDetails,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Seller registration failed: No user account created.');
      }

      await user.updateDisplayName(name.trim());

      final newSeller = UserModel(
        uid: user.uid,
        email: email.trim(),
        name: name.trim(),
        role: UserRole.seller,
        isApproved: false, // Default pending review for vendors
        shopDetails: shopDetails,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(user.uid).set(newSeller.toMap());

      return newSeller;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register seller: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> upgradeToSeller({
    required String uid,
    required ShopDetails shopDetails,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': UserRole.seller.name,
        'shopDetails': shopDetails.toMap(),
        'isApproved': false,
      });

      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw const AuthException('Failed to retrieve updated seller profile.');
      }

      return UserModel.fromMap(doc.data()!, documentId: doc.id);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register shop: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in failed: No user returned.');
      }

      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, documentId: doc.id);
      } else {
        // Fallback profile creation if user document was missing
        final fallbackUser = UserModel(
          uid: user.uid,
          email: user.email ?? email.trim(),
          name: user.displayName ?? '',
          role: UserRole.customer,
          isApproved: true,
          createdAt: DateTime.now(),
        );
        await _usersCollection.doc(user.uid).set(fallbackUser.toMap());
        return fallbackUser;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInSellerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Seller sign in failed: No user returned.');
      }

      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        throw const AuthException('Vendor account not found. Please register your shop.');
      }

      final userModel = UserModel.fromMap(doc.data()!, documentId: doc.id);
      if (userModel.role != UserRole.seller) {
        // Registered as customer, not seller
        throw const AuthException(
          'This account is registered as a Customer. Please use a Vendor account or register your shop to access the Seller Portal.',
        );
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Seller sign in error: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, documentId: doc.id);
      }
      return null;
    } catch (e) {
      throw AuthException('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error: Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
