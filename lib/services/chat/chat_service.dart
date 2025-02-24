import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:whispr_chat_app/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define collection names as constants to ensure consistency
  static const String USERS_COLLECTION = 'users';
  static const String CHAT_ROOMS_COLLECTION = 'chat_rooms';
  static const String MESSAGES_COLLECTION = 'messages';
  static const String DELETED_MESSAGES_COLLECTION = 'deleted_messages';

  // Get users stream
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection(USERS_COLLECTION).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> userData = {
          'uid': doc.id,
          'email': doc.data()['email'] ?? '',
          'username': doc.data()['username'] ?? '',
          'isOnline': doc.data()['isOnline'] ?? false,
          if (doc.data().containsKey('profileImageUrl'))
            'profileImageUrl': doc.data()['profileImageUrl'],
        };
        return userData;
      }).toList();
    });
  }

  // Stream to get sorted chats with latest messages
  Stream<List<Map<String, dynamic>>> getSortedChatsStream() {
    final currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection(CHAT_ROOMS_COLLECTION)
        .where('participants', arrayContains: currentUserID)
        .snapshots()
        .asyncMap((chatRooms) async {
      List<Map<String, dynamic>> chatList = [];

      for (var room in chatRooms.docs) {
        List<String> participants = List<String>.from(room.data()['participants']);
        String otherUserID = participants.firstWhere((id) => id != currentUserID);

        DocumentSnapshot userDoc = await _firestore
            .collection(USERS_COLLECTION)
            .doc(otherUserID)
            .get();

        if (!userDoc.exists) continue;

        QuerySnapshot lastMessageQuery = await _firestore
            .collection(CHAT_ROOMS_COLLECTION)
            .doc(room.id)
            .collection(MESSAGES_COLLECTION)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        chatList.add({
          'uid': otherUserID,
          'email': userData['email'] ?? '',
          'username': userData['username'] ?? '',
          'isOnline': userData['isOnline'] ?? false,
          'lastMessage': lastMessageQuery.docs.isNotEmpty
              ? lastMessageQuery.docs.first.data()
              : null,
          'lastMessageTime': lastMessageQuery.docs.isNotEmpty
              ? ((lastMessageQuery.docs.first.data() as Map<String, dynamic>)["timestamp"] as int)
              : 0,
        });
      }

      // Sort the chats by last message timestamp
      chatList.sort((a, b) {
        final aTimestamp = a['lastMessageTimestamp'] ?? 0;
        final bTimestamp = b['lastMessageTimestamp'] ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return chatList;
    });
  }

  // Helper method to safely get user data
  Future<Map<String, dynamic>> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(USERS_COLLECTION).doc(uid).get();

      if (!doc.exists) {
        return {
          'uid': uid,
          'email': '',
          'username': 'Unknown User',
          'isOnline': false,
        };
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'uid': uid,
        'email': data['email'] ?? '',
        'username': data['username'] ?? '',
        'isOnline': data['isOnline'] ?? false,
        if (data.containsKey('profileImageUrl'))
          'profileImageUrl': data['profileImageUrl'],
      };
    } catch (e) {
      print('Error getting user details: $e');
      return {
        'uid': uid,
        'email': '',
        'username': 'Unknown User',
        'isOnline': false,
      };
    }
  }

  // Get messages stream with correct ordering
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
      String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    Stream<Set<String>> deletedMessageIdsStream = _firestore
        .collection(USERS_COLLECTION)
        .doc(userID)
        .collection(DELETED_MESSAGES_COLLECTION)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });

    final messagesRef = _firestore
        .collection(CHAT_ROOMS_COLLECTION)
        .doc(chatRoomID)
        .collection(MESSAGES_COLLECTION);

    return deletedMessageIdsStream.switchMap((deletedIds) {
      if (deletedIds.isNotEmpty) {
        return messagesRef
            .where(FieldPath.documentId, whereNotIn: deletedIds.toList())
            .orderBy("timestamp", descending: true)
            .snapshots();
      }
      return messagesRef.orderBy("timestamp", descending: true).snapshots();
    });
  }

  // Send message
  Future<void> sendMessage(
      String receiverID, Map<String, dynamic> messageData) async {
    try {
      final String currentUserID = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;

      final DateTime now = DateTime.now();
      final Timestamp time = Timestamp.fromDate(now);
      final int timestamp = now.millisecondsSinceEpoch;

      Message newMessage = Message(
        id: messageData['id'],
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: messageData['message'],
        time: time,
        timestamp: timestamp,
        replyTo: messageData['replyTo'] != null
            ? Message.fromMap(Map<String, dynamic>.from(messageData['replyTo']),
                messageData['replyTo']['id'])
            : null,
      );

      List<String> ids = [currentUserID, receiverID];
      ids.sort();
      String chatRoomID = ids.join("_");

      final DocumentReference messageRef = _firestore
          .collection(CHAT_ROOMS_COLLECTION)
          .doc(chatRoomID)
          .collection(MESSAGES_COLLECTION)
          .doc(messageData['id']);

      await messageRef.set(newMessage.toMap());

      await _firestore.collection(CHAT_ROOMS_COLLECTION).doc(chatRoomID).set({
        'lastMessageTime': time,
        'participants': [currentUserID, receiverID],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Delete message
  Future<void> deleteMessage(
      String messageID, String chatRoomID, bool forEveryone) async {
    try {
      if (forEveryone) {
        await _firestore
            .collection(CHAT_ROOMS_COLLECTION)
            .doc(chatRoomID)
            .collection(MESSAGES_COLLECTION)
            .doc(messageID)
            .delete();
      } else {
        await _firestore
            .collection(USERS_COLLECTION)
            .doc(_auth.currentUser!.uid)
            .collection(DELETED_MESSAGES_COLLECTION)
            .doc(messageID)
            .set({
          'deletedAt': FieldValue.serverTimestamp(),
          'messageID': messageID,
          'chatRoomID': chatRoomID,
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomID) async {
    try {
      final String currentUserID = _auth.currentUser!.uid;

      QuerySnapshot unreadMessages = await _firestore
          .collection(CHAT_ROOMS_COLLECTION)
          .doc(chatRoomID)
          .collection(MESSAGES_COLLECTION)
          .where("receiverID", isEqualTo: currentUserID)
          .where("read", isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get last message for a chat
  Stream<Map<String, dynamic>?> getLastMessage(
      String currentUserID, String otherUserID) {
    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    return _firestore
        .collection(CHAT_ROOMS_COLLECTION)
        .doc(chatRoomID)
        .collection(MESSAGES_COLLECTION)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    });
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String currentUserID, String otherUserID) {
    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    return _firestore
        .collection(CHAT_ROOMS_COLLECTION)
        .doc(chatRoomID)
        .collection(MESSAGES_COLLECTION)
        .where('receiverID', isEqualTo: currentUserID)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
