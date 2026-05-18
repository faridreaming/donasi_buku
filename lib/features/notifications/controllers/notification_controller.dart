import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
});

final unreadCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

Future<void> markNotificationRead(String notifId) async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notifId)
      .update({'isRead': true});
}

Future<void> markAllRead(String uid) async {
  final batch = FirebaseFirestore.instance.batch();
  final snap = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .get();
  for (final doc in snap.docs) {
    batch.update(doc.reference, {'isRead': true});
  }
  await batch.commit();
}

/// Helper — dipanggil dari TransactionController
Future<void> createNotification({
  required String userId,
  required String title,
  required String body,
  required NotifType type,
  String? bookId,
  String? bookTitle,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'bookId': bookId,
    'bookTitle': bookTitle,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
