import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum NotifType {
  requestReceived,
  requestApproved,
  requestRejected,
  bookCompleted,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotifType type;
  final String? bookId;
  final String? bookTitle;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.bookId,
    this.bookTitle,
    required this.isRead,
    required this.createdAt,
  });

  Color get accentColor => switch (type) {
        NotifType.requestReceived => AppColors.info,
        NotifType.requestApproved => AppColors.success,
        NotifType.requestRejected => AppColors.danger,
        NotifType.bookCompleted => const Color(0xFF7BC67E),
      };

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: NotifType.values.byName(d['type'] ?? 'requestReceived'),
      bookId: d['bookId'],
      bookTitle: d['bookTitle'],
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
