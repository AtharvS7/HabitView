/// Domain-level exceptions used across the data and application layers.
///
/// Repositories translate low-level failures (FirebaseAuthException, Isar
/// errors, IO errors) into these typed exceptions so the presentation layer
/// can render friendly messages without depending on Firebase/Isar types.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// A user-facing, already-friendly message.
  final String message;

  /// The underlying error, kept for logging.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Authentication-related failures (wrong password, email in use, etc.).
class AuthException extends AppException {
  const AuthException(super.message, {this.code, super.cause});

  /// The original provider error code (e.g. 'wrong-password'), if any.
  final String? code;
}

/// Local persistence failures (Isar read/write problems).
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Backup / import / export failures.
class BackupException extends AppException {
  const BackupException(super.message, {super.cause});
}

/// A premium-gated action was attempted on the free tier.
class PremiumRequiredException extends AppException {
  const PremiumRequiredException([
    super.message = 'This feature requires HabitView Premium.',
  ]);
}

/// Validation failure for user-supplied input.
class ValidationException extends AppException {
  const ValidationException(super.message);
}
