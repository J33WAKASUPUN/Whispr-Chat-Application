import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp time;
  final int timestamp;
  final Message? replyTo;
  final bool read; // Add read status

  Message({
    required this.id,
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.time,
    required this.timestamp,
    this.replyTo,
    this.read = false, // Default to unread
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'time': time,
      'timestamp': timestamp,
      'replyTo': replyTo?.toMap(),
      'read': read, // Include read status
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      return Message(
        id: documentId,
        senderID: map['senderID'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverID: map['receiverID'] ?? '',
        message: map['message'] ?? '',
        time: map['time'] as Timestamp? ?? Timestamp.now(),
        timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        replyTo: map['replyTo'] != null
            ? Message.fromMap(Map<String, dynamic>.from(map['replyTo']),
                map['replyTo']['id'] ?? '')
            : null,
        read: map['read'] ?? false,
      );
    } catch (e) {
      print('Error creating Message from map: $e');
      rethrow;
    }
  }

  // Add a copy with method for easy updates
  Message copyWith({
    String? id,
    String? senderID,
    String? senderEmail,
    String? receiverID,
    String? message,
    Timestamp? time,
    int? timestamp,
    Message? replyTo,
    bool? read,
  }) {
    return Message(
      id: id ?? this.id,
      senderID: senderID ?? this.senderID,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverID: receiverID ?? this.receiverID,
      message: message ?? this.message,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      read: read ?? this.read,
    );
  }
}
