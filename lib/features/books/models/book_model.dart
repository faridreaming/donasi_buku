import 'package:cloud_firestore/cloud_firestore.dart';

enum BookCondition { likeNew, good, fair, poor }

enum BookStatus { available, reserved, donated }

class BookModel {
  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String author;
  final String category;
  final BookCondition condition;
  final String description;
  final String contactInfo;
  final String imageUrl;
  final String cloudinaryPublicId;
  final BookStatus status;
  final String donorLocation;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const BookModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.author,
    required this.category,
    required this.condition,
    required this.description,
    required this.contactInfo,
    required this.imageUrl,
    required this.cloudinaryPublicId,
    required this.status,
    required this.donorLocation,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      donorId: d['donorId'] ?? '',
      donorName: d['donorName'] ?? '',
      title: d['title'] ?? '',
      author: d['author'] ?? '',
      category: d['category'] ?? '',
      condition: BookCondition.values.byName(d['condition'] ?? 'good'),
      description: d['description'] ?? '',
      contactInfo: d['contactInfo'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      cloudinaryPublicId: d['cloudinaryPublicId'] ?? '',
      status: BookStatus.values.byName(d['status'] ?? 'available'),
      donorLocation: d['donorLocation'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'donorId': donorId,
        'donorName': donorName,
        'title': title,
        'author': author,
        'category': category,
        'condition': condition.name,
        'description': description,
        'contactInfo': contactInfo,
        'imageUrl': imageUrl,
        'cloudinaryPublicId': cloudinaryPublicId,
        'status': status.name,
        'donorLocation': donorLocation,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
