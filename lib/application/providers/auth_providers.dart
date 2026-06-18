import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_user.dart';
import 'app_providers.dart';

/// Reactive auth state — the single source of truth for "who is signed in".
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).valueOrNull,
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.uid,
);

/// Drives auth actions and exposes loading/error state to the UI.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password));

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _run(() => ref.read(authRepositoryProvider).registerWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          ));

  Future<bool> signInWithGoogle() =>
      _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<bool> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordResetEmail(email));

  Future<bool> updateDisplayName(String name) =>
      _run(() => ref.read(authRepositoryProvider).updateDisplayName(name));

  Future<bool> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<bool> deleteAccount() =>
      _run(() => ref.read(authRepositoryProvider).deleteAccount());

  /// Runs [action], surfacing loading/error via [state]. Returns true on
  /// success so callers can navigate only when the action succeeded.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
