import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/models/notification_model.dart';
import '../models/transaction_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final myDonatedBooksProvider = StreamProvider((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('books')
      .where('donorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

final incomingRequestsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, bookId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
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
  final uid = FirebaseAuth.instance.currentUser?.uid;
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

      // Notifikasi ke donor
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

  /// Approve / reject — terima TransactionModel lengkap
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

      // Notifikasi ke receiver
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

  Future<void> markCompleted(TransactionModel tx) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('transactions').doc(tx.id),
        {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()},
      );
      batch.update(
        FirebaseFirestore.instance.collection('books').doc(tx.bookId),
        {'status': 'donated', 'updatedAt': FieldValue.serverTimestamp()},
      );
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(tx.donorId),
        {'donatedCount': FieldValue.increment(1)},
      );
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(tx.receiverId),
        {'receivedCount': FieldValue.increment(1)},
      );

      await batch.commit();

      // Notifikasi ke donor
      await createNotification(
        userId: tx.donorId,
        title: 'Buku Sudah Diterima',
        body: '"${tx.bookTitle}" telah diterima oleh pemohon. Terima kasih!',
        type: NotifType.bookCompleted,
        bookId: tx.bookId,
        bookTitle: tx.bookTitle,
      );
    });
  }
}
