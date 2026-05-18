import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../books/models/book_model.dart';

/// Stream semua buku available — dipakai bersama oleh Home & Map
final booksProvider = StreamProvider<List<BookModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('books')
      .where('status', isEqualTo: 'available')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(BookModel.fromFirestore).toList());
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Buku terfilter — turunan dari booksProvider
final filteredBooksProvider = Provider<AsyncValue<List<BookModel>>>((ref) {
  final books = ref.watch(booksProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  return books.whenData((list) {
    var result = list;
    if (category != null && category != 'Semua') {
      result = result.where((b) => b.category == category).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  });
});
