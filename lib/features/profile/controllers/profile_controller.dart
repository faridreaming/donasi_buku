import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/user_model.dart';

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return Stream.value(null);

  // Pure read-only stream — tidak ada side effect signOut di sini.
  // Validasi akun dihapus sudah ditangani oleh:
  // 1. AuthService.login() → cek doc sebelum login berhasil
  // 2. app.dart._validateSession() → cek doc saat app dibuka
  return FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});
