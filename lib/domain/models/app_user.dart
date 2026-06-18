/// The authenticated user, as surfaced by [AuthRepository].
///
/// Deliberately a thin, immutable plain-Dart model (no codegen) so the auth
/// layer can map a `firebase_auth` `User` into it without leaking the Firebase
/// type into the domain/presentation layers.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.providers = const <String>[],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  /// Provider ids backing this account (e.g. 'password', 'google.com').
  final List<String> providers;

  bool get isGoogleLinked => providers.contains('google.com');
  bool get isPasswordLinked => providers.contains('password');

  String get displayLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return email ?? 'HabitView user';
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    List<String>? providers,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      providers: providers ?? this.providers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.isEmailVerified == isEmailVerified;

  @override
  int get hashCode =>
      Object.hash(uid, email, displayName, photoUrl, isEmailVerified);
}
