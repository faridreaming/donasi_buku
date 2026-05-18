import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String location;
  final int donatedCount;
  final int receivedCount;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.location,
    required this.donatedCount,
    required this.receivedCount,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
      location: d['location'] ?? '',
      donatedCount: (d['donatedCount'] as num?)?.toInt() ?? 0,
      receivedCount: (d['receivedCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
