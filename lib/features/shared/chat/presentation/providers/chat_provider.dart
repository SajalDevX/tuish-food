import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/shared/chat/data/datasources/chat_remote_datasource.dart';
import 'package:tuish_food/features/shared/chat/data/repositories/chat_repository_impl.dart';
import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';
import 'package:tuish_food/features/shared/chat/domain/repositories/chat_repository.dart';
import 'package:tuish_food/injection_container.dart';

// Data source
final chatRemoteDataSourceProvider =
    Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return ChatRepositoryImpl(
    remoteDataSource: ref.watch(chatRemoteDataSourceProvider),
    currentUserId: currentUser?.uid ?? '',
  );
});

// Stream of messages for a given chat
final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(chatId);
});

// Send message notifier
final sendMessageProvider =
    NotifierProvider<SendMessageNotifier, AsyncValue<void>>(
        SendMessageNotifier.new);

class SendMessageNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ChatRepository get _repository => ref.watch(chatRepositoryProvider);

  Future<bool> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.sendMessage(
      chatId,
      text,
      imageUrl: imageUrl,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

// Get or create chat
final getOrCreateChatProvider =
    NotifierProvider<GetOrCreateChatNotifier, AsyncValue<String?>>(
        GetOrCreateChatNotifier.new);

class GetOrCreateChatNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  ChatRepository get _repository => ref.watch(chatRepositoryProvider);

  Future<String?> getOrCreateChat(
    String orderId,
    String customerId,
    String deliveryPartnerId,
  ) async {
    state = const AsyncLoading();
    final result = await _repository.getOrCreateChat(
      orderId,
      customerId,
      deliveryPartnerId,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return null;
      },
      (chatId) {
        state = AsyncData(chatId);
        return chatId;
      },
    );
  }
}

// Mark messages as read
final markAsReadProvider = Provider<MarkAsReadAction>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return MarkAsReadAction(repository);
});

class MarkAsReadAction {
  final ChatRepository _repository;

  const MarkAsReadAction(this._repository);

  Future<void> call(String chatId, String userId) async {
    await _repository.markAsRead(chatId, userId);
  }
}
