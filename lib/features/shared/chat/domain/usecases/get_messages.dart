import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';
import 'package:tuish_food/features/shared/chat/domain/repositories/chat_repository.dart';

class GetMessages {
  final ChatRepository _repository;

  const GetMessages(this._repository);

  Stream<List<Message>> call(String chatId) {
    return _repository.getMessages(chatId);
  }
}
