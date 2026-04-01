import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';

abstract class ChatRepository {
  Stream<List<Message>> getMessages(String chatId);

  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
  });

  Future<Either<Failure, String>> getOrCreateChat(
    String orderId,
    String customerId,
    String deliveryPartnerId,
  );

  Future<Either<Failure, void>> markAsRead(String chatId, String userId);
}
