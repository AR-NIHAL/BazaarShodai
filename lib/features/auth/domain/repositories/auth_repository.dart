import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Contract defining authentication and user identity operations for buyers and vendors.
abstract class AuthRepository {
  /// Stream emitting changes to the current Firebase Auth user state.
  Stream<User?> get authStateChanges;

  /// Registers a new customer with email and password.
  /// Newly registered customers are assigned the default role [UserRole.customer].
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Registers a new seller/vendor with email, password, owner name, and shop details.
  /// Newly registered sellers are assigned the role [UserRole.seller].
  Future<UserModel> signUpSellerWithEmail({
    required String email,
    required String password,
    required String name,
    required ShopDetails shopDetails,
  });

  /// Upgrades an existing authenticated customer account to a seller role with shop details.
  Future<UserModel> upgradeToSeller({
    required String uid,
    required ShopDetails shopDetails,
  });

  /// Authenticates an existing customer and fetches their Firestore profile.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Authenticates an existing seller and verifies that they have a [UserRole.seller] role.
  Future<UserModel> signInSellerWithEmail({
    required String email,
    required String password,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Retrieves the current user's profile from Firestore `/users/{uid}`.
  /// Returns `null` if no user is signed in or the profile document does not exist.
  Future<UserModel?> getCurrentUserData();

  /// Stream emitting real-time updates for the current user's profile from Firestore.
  Stream<UserModel?> get currentUserStream;
}
