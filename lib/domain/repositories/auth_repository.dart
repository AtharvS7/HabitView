import '../models/app_user.dart';

/// Authentication boundary. The only place Firebase Auth is allowed to live
/// behind. Implementations translate provider errors into [AuthException].
abstract interface class AuthRepository {
  /// Emits the current [AppUser] or null whenever auth state changes.
  Stream<AppUser?> authStateChanges();

  /// The currently signed-in user, if any (synchronous snapshot).
  AppUser? get currentUser;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<void> updateDisplayName(String displayName);

  Future<void> signOut();

  /// Permanently deletes the Firebase account. Local data removal is handled
  /// separately by the caller so the user can keep an offline copy if desired.
  Future<void> deleteAccount();
}
