import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TransactionStatus { pending, approved, rejected, completed }

class TransactionModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookImageUrl;
  final String donorId;
  final String receiverId;
  final TransactionStatus status;
  final String requestMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookImageUrl,
    required this.donorId,
    required this.receiverId,
    required this.status,
    required this.requestMessage,
    required this.createdAt,
    this.updatedAt,
  });

  String get statusLabel => switch (status) {
        TransactionStatus.pending => 'Menunggu',
        TransactionStatus.approved => 'Disetujui',
        TransactionStatus.rejected => 'Ditolak',
        TransactionStatus.completed => 'Selesai',
      };

  Color get statusColor => switch (status) {
        TransactionStatus.pending => AppColors.info,
        TransactionStatus.approved => AppColors.success,
        TransactionStatus.rejected => AppColors.danger,
        TransactionStatus.completed => const Color(0xFF7BC67E),
      };

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      bookId: d['bookId'] ?? '',
      bookTitle: d['bookTitle'] ?? '',
      bookImageUrl: d['bookImageUrl'] ?? '',
      donorId: d['donorId'] ?? '',
      receiverId: d['receiverId'] ?? '',
      status: TransactionStatus.values.byName(d['status'] ?? 'pending'),
      requestMessage: d['requestMessage'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
