import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String status; // sent, delivered, read
  final Map<String, String> reactions; // userId: emoji
  final String? replyToId;
  final String? replyToMessage;
  final String? messageType; // text, location, gif
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? gifUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.status = 'sent',
    this.reactions = const {},
    this.replyToId,
    this.replyToMessage,
    this.messageType = 'text',
    this.latitude,
    this.longitude,
    this.locationName,
    this.gifUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'messageType': messageType,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'gifUrl': gifUrl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'sent',
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      replyToId: map['replyToId'],
      replyToMessage: map['replyToMessage'],
      messageType: map['messageType'] ?? 'text',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
      gifUrl: map['gifUrl'],
    );
  }
}