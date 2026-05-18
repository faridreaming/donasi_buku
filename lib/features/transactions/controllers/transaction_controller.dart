import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Buku yang saya donasikan
final myDonatedBooksProvider = StreamProvider((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('books')
      .where('donorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// Semua permintaan yang masuk ke buku saya
// Ganti incomingRequestsProvider:
final incomingRequestsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, bookId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('donorId', isEqualTo: uid) // ← filter by uid agar rules terpenuhi
      .where('bookId', isEqualTo: bookId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map(TransactionModel.fromFirestore)
          .where((t) =>
              t.status == TransactionStatus.pending) // filter client-side
          .toList());
});

/// Permintaan yang saya buat (sebagai penerima)
final myRequestsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('receiverId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
});

/// Cek apakah user punya request aktif untuk buku tertentu
final activeRequestProvider =
    FutureProvider.family<TransactionModel?, String>((ref, bookId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('transactions')
      .where('bookId', isEqualTo: bookId)
      .where('receiverId', isEqualTo: uid)
      .get();

  return snap.docs
      .map(TransactionModel.fromFirestore)
      .where((t) =>
          t.status == TransactionStatus.pending ||
          t.status == TransactionStatus.approved)
      .firstOrNull;
});

// ── Controller ─────────────────────────────────────────────────────────────

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(
        TransactionController.new);

class TransactionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Buat permintaan buku
  Future<void> createRequest({
    required String bookId,
    required String bookTitle,
    required String bookImageUrl,
    required String donorId,
    required String message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('transactions').add({
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookImageUrl': bookImageUrl,
        'donorId': donorId,
        'receiverId': uid,
        'status': 'pending',
        'requestMessage': message.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Approve / Reject permintaan (oleh donor)
  Future<void> updateStatus(
    String transactionId,
    TransactionStatus newStatus, {
    String? bookId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseFirestore.instance.batch();

      // Update transaction
      final txRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId);
      batch.update(txRef, {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Kalau disetujui, ubah status buku jadi reserved
      if (newStatus == TransactionStatus.approved && bookId != null) {
        final bookRef =
            FirebaseFirestore.instance.collection('books').doc(bookId);
        batch.update(bookRef,
            {'status': 'reserved', 'updatedAt': FieldValue.serverTimestamp()});
      }

      // Kalau ditolak dan buku reserved, kembalikan ke available
      if (newStatus == TransactionStatus.rejected && bookId != null) {
        final bookRef =
            FirebaseFirestore.instance.collection('books').doc(bookId);
        batch.update(bookRef,
            {'status': 'available', 'updatedAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
    });
  }

  /// Tandai selesai (buku sudah diterima)
  Future<void> markCompleted(
    String transactionId,
    String bookId,
    String donorId,
    String receiverId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId),
        {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()},
      );

      batch.update(
        FirebaseFirestore.instance.collection('books').doc(bookId),
        {'status': 'donated', 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Increment counter donor & receiver
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(donorId),
        {'donatedCount': FieldValue.increment(1)},
      );
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(receiverId),
        {'receivedCount': FieldValue.increment(1)},
      );

      await batch.commit();
    });
  }
}
