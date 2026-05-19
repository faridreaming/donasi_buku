import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloudinary_service.dart';

final bookControllerProvider =
    AsyncNotifierProvider<BookController, void>(BookController.new);

class BookController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> donateBook({
    required String title,
    required String author,
    required String category,
    required String condition,
    required String description,
    required String contactInfo,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final donorName = (userDoc.data()?['name'] as String?)?.trim() ??
          user.displayName?.trim() ??
          'Anonim';

      final upload = await CloudinaryService.uploadImage(imageFile);
      if (upload == null) throw Exception('Gagal mengupload foto buku.');

      await FirebaseFirestore.instance.collection('books').add({
        'donorId': user.uid,
        'donorName': donorName,
        'title': title.trim(),
        'author': author.trim(),
        'category': category,
        'condition': condition,
        'description': description.trim(),
        'contactInfo': contactInfo.trim(),
        'imageUrl': upload.url,
        'cloudinaryPublicId': upload.publicId,
        'status': 'available',
        'donorLocation': address,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String category,
    required String condition,
    required String description,
    required String contactInfo,
    required String currentImageUrl,
    required String cloudinaryPublicId,
    File? newImageFile,
    required double? latitude,
    required double? longitude,
    required String address,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String imageUrl = currentImageUrl;
      String pubId = cloudinaryPublicId;

      if (newImageFile != null) {
        final upload = await CloudinaryService.uploadImage(newImageFile);
        if (upload == null) throw Exception('Gagal mengupload foto baru.');
        imageUrl = upload.url;
        pubId = upload.publicId;
      }

      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'title': title.trim(),
        'author': author.trim(),
        'category': category,
        'condition': condition,
        'description': description.trim(),
        'contactInfo': contactInfo.trim(),
        'imageUrl': imageUrl,
        'cloudinaryPublicId': pubId,
        'donorLocation': address,
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteBook(String bookId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // ── Ambil semua transaksi buku ini (single field query = tidak butuh index) ──
      final txSnap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('bookId', isEqualTo: bookId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      // Update transaksi pending/approved → rejected (jangan delete, biar receiver tahu)
      for (final doc in txSnap.docs) {
        final status = doc.data()['status'] as String? ?? '';
        if (status == 'pending' || status == 'approved') {
          batch.update(doc.reference, {
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Hapus buku
      batch.delete(
        FirebaseFirestore.instance.collection('books').doc(bookId),
      );

      await batch.commit();
    });
  }
}
