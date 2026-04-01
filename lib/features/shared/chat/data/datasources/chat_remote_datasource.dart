import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/shared/chat/data/models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessages(String chatId);

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String? imageUrl,
  });

  Future<String> getOrCreateChat(
    String orderId,
    String customerId,
    String deliveryPartnerId,
  );

  Future<void> markAsRead(String chatId, String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  const ChatRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _chatsRef =>
      _firestore.collection(FirebaseConstants.chatsCollection);

  CollectionReference _messagesRef(String chatId) => _chatsRef
      .doc(chatId)
      .collection(FirebaseConstants.messagesSubcollection);

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String? imageUrl,
  }) async {
    try {
      final now = DateTime.now();
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      };

      // Add the message to the messages subcollection
      await _messagesRef(chatId).add(messageData);

      // Update the chat document with last message info
      await _chatsRef.doc(chatId).update({
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to send message');
    }
  }

  @override
  Future<String> getOrCreateChat(
    String orderId,
    String customerId,
    String deliveryPartnerId,
  ) async {
    try {
      // Create a composite ID based on the orderId to ensure uniqueness
      final chatId = 'chat_$orderId';

      final chatDoc = await _chatsRef.doc(chatId).get();

      if (chatDoc.exists) {
        return chatId;
      }

      // Create a new chat document
      await _chatsRef.doc(chatId).set({
        'orderId': orderId,
        'customerId': customerId,
        'deliveryPartnerId': deliveryPartnerId,
        'participants': [customerId, deliveryPartnerId],
        'lastMessage': '',
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': '',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return chatId;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to create chat');
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      // Get all unread messages that were NOT sent by this user
      final unreadMessages = await _messagesRef(chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Batch update all unread messages
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to mark messages as read');
    }
  }
}
