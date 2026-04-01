import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/shared/chat/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository _repository;

  const SendMessage(this._repository);

  Future<Either<Failure, void>> call(
    String chatId,
    String text, {
    String? imageUrl,
  }) {
    return _repository.sendMessage(chatId, text, imageUrl: imageUrl);
  }
}
