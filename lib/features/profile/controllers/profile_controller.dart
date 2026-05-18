import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/user_model.dart';

/// Provider global yang otomatis refresh saat auth state berubah.
/// Pakai ini di semua screen yang butuh data user saat ini.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  // Watch authStateProvider → provider ini ikut invalidate saat logout/login
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;

  if (uid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});
