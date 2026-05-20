import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser       => _auth.currentUser;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Step 1: Login ke Firebase Auth
    final cred = await _auth.signInWithEmailAndPassword(
      email:    email.trim(),
      password: password,
    );

    // Step 2: Verifikasi dokumen Firestore ada
    final doc = await _db
        .collection('users')
        .doc(cred.user!.uid)
        .get();

    if (!doc.exists) {
      // Dokumen tidak ada → akun sudah dihapus dari sistem
      // Langsung signOut sebelum router sempat redirect ke home
      await _auth.signOut();
      throw FirebaseAuthException(
        code:    'user-data-missing',
        message: 'Data akun tidak ditemukan.',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email:    email.trim(),
      password: password,
    );

    await cred.user?.updateDisplayName(name.trim());

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid':          cred.user!.uid,
      'name':         name.trim(),
      'email':        email.trim(),
      'photoUrl':     '',
      'location':     '',
      'donatedCount': 0,
      'receivedCount':0,
      'createdAt':    FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();

  static String parseError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-data-missing':
          return 'Akun ini tidak ditemukan di sistem. '
              'Kemungkinan telah dihapus, silakan daftar ulang.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'wrong-password':
          return 'Password salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan masuk.';
        case 'weak-password':
          return 'Password terlalu lemah. Gunakan minimal 8 karakter.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        default:
          return 'Terjadi kesalahan. Coba lagi.';
      }
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}