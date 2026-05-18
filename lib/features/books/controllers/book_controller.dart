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
    required File imageFile,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = FirebaseAuth.instance.currentUser!;

      // Ambil nama donatur dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final donorName = (userDoc.data()?['name'] as String?)?.trim() ??
          user.displayName?.trim() ??
          'Anonim';

      // Upload foto ke Cloudinary
      final upload = await CloudinaryService.uploadImage(imageFile);
      if (upload == null) throw Exception('Gagal mengupload foto buku.');

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection('books').add({
        'donorId': user.uid,
        'donorName': donorName, // ← simpan nama
        'title': title.trim(),
        'author': author.trim(),
        'category': category,
        'condition': condition,
        'description': description.trim(),
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
}
