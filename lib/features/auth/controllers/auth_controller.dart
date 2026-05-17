import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'; // ← tambah
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart'; // ← ini yang hilang

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authState;
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  late AuthService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(authServiceProvider);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.register(name: name, email: email, password: password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.signOut);
  }
}
