import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart'; // ← import authStateProvider
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/models/notification_model.dart';
import '../models/transaction_model.dart';

// ── Semua provider pakai ref.watch(authStateProvider) ──────────────────────
// Otomatis invalidate & rebuild saat ganti akun (fix issue 1)

final myDonatedBooksProvider = StreamProvider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid; // ← watch
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('books')
      .where('donorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

final incomingRequestsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, bookId) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid; // ← watch
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('donorId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .map(TransactionModel.fromFirestore)
          .where((t) =>
              t.bookId == bookId && t.status == TransactionStatus.pending)
          .toList());
});

final myRequestsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid; // ← watch
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('receiverId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
});

final activeRequestProvider =
    FutureProvider.family<TransactionModel?, String>((ref, bookId) async {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid; // ← watch
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

// ── Controller ──────────────────────────────────────────────────────────────

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(
        TransactionController.new);

class TransactionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createRequest({
    required String bookId,
    required String bookTitle,
    required String bookImageUrl,
    required String donorId,
    required String message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Tidak terautentikasi.');

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

      await createNotification(
        userId: donorId,
        title: 'Permintaan Buku Baru',
        body: 'Seseorang meminta bukumu: "$bookTitle"',
        type: NotifType.requestReceived,
        bookId: bookId,
        bookTitle: bookTitle,
      );
    });
  }

  Future<void> updateStatus(
    TransactionModel tx,
    TransactionStatus newStatus,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('transactions').doc(tx.id),
        {'status': newStatus.name, 'updatedAt': FieldValue.serverTimestamp()},
      );

      if (newStatus == TransactionStatus.approved) {
        batch.update(
          FirebaseFirestore.instance.collection('books').doc(tx.bookId),
          {'status': 'reserved', 'updatedAt': FieldValue.serverTimestamp()},
        );
      }
      if (newStatus == TransactionStatus.rejected) {
        batch.update(
          FirebaseFirestore.instance.collection('books').doc(tx.bookId),
          {'status': 'available', 'updatedAt': FieldValue.serverTimestamp()},
        );
      }

      await batch.commit();

      await createNotification(
        userId: tx.receiverId,
        title: newStatus == TransactionStatus.approved
            ? 'Permintaan Disetujui!'
            : 'Permintaan Ditolak',
        body: newStatus == TransactionStatus.approved
            ? 'Selamat! Permintaanmu untuk "${tx.bookTitle}" disetujui.'
            : 'Maaf, permintaanmu untuk "${tx.bookTitle}" ditolak.',
        type: newStatus == TransactionStatus.approved
            ? NotifType.requestApproved
            : NotifType.requestRejected,
        bookId: tx.bookId,
        bookTitle: tx.bookTitle,
      );
    });
  }

  // Fix issue 3: batch split — transaksi dulu, buku terpisah
  Future<void> markCompleted(TransactionModel tx) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Step 1: Update transaksi + user counters (receiver bisa update transaksi)
      final batch1 = FirebaseFirestore.instance.batch();
      batch1.update(
        FirebaseFirestore.instance.collection('transactions').doc(tx.id),
        {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()},
      );
      batch1.update(
        FirebaseFirestore.instance.collection('users').doc(tx.donorId),
        {'donatedCount': FieldValue.increment(1)},
      );
      batch1.update(
        FirebaseFirestore.instance.collection('users').doc(tx.receiverId),
        {'receivedCount': FieldValue.increment(1)},
      );
      await batch1.commit();

      // Step 2: Update status buku (rules sudah diupdate — allow status='donated')
      await FirebaseFirestore.instance
          .collection('books')
          .doc(tx.bookId)
          .update({
        'status': 'donated',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await createNotification(
        userId: tx.donorId,
        title: 'Buku Sudah Diterima',
        body: '"${tx.bookTitle}" telah diterima. Terima kasih telah berdonasi!',
        type: NotifType.bookCompleted,
        bookId: tx.bookId,
        bookTitle: tx.bookTitle,
      );
    });
  }
}
