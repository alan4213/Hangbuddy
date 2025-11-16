import 'package:cloud_firestore/cloud_firestore.dart';

class HangoutRequest {
  final String id;
  final String creatorId;
  final String title;
  final String category;
  final DateTime dateTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final double maxDistance; // in kilometers
  final String status;
  final DateTime createdAt;
  final List<String> interestedUsers;
  final List<String> viewedByUsers;

  HangoutRequest({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.category,
    required this.dateTime,
    required this.location,
    this.latitude,
    this.longitude,
    this.maxDistance = 30.0,
    required this.status,
    required this.createdAt,
    this.interestedUsers = const [],
    this.viewedByUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'maxDistance': maxDistance,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'interestedUsers': interestedUsers,
      'viewedByUsers': viewedByUsers,
    };
  }

  factory HangoutRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return HangoutRequest(
      id: documentId,
      creatorId: map['creatorId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      maxDistance: (map['maxDistance'] ?? 30.0).toDouble(),
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      interestedUsers: List<String>.from(map['interestedUsers'] ?? []),
      viewedByUsers: List<String>.from(map['viewedByUsers'] ?? []),
    );
  }
}