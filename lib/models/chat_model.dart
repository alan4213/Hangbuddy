import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String status; // sent, delivered, read
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, String> reactions; // userId: emoji
  final String? replyToId;
  final String? replyToMessage;
  final String? messageType; // text, location, gif, photo
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? gifUrl;
  final String? photoUrl;
  final String? localPhotoPath;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.reactions = const {},
    this.replyToId,
    this.replyToMessage,
    this.messageType = 'text',
    this.latitude,
    this.longitude,
    this.locationName,
    this.gifUrl,
    this.photoUrl,
    this.localPhotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'messageType': messageType,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'gifUrl': gifUrl,
      'photoUrl': photoUrl,
      'localPhotoPath': localPhotoPath,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(), // Fallback for local cache before server ack
      status: map['status'] ?? 'sent',
      deliveredAt: map['deliveredAt'] != null ? (map['deliveredAt'] as Timestamp).toDate() : null,
      readAt: map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      replyToId: map['replyToId'],
      replyToMessage: map['replyToMessage'],
      messageType: map['messageType'] ?? 'text',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
      gifUrl: map['gifUrl'],
      photoUrl: map['photoUrl'],
      localPhotoPath: map['localPhotoPath'],
    );
  }
}