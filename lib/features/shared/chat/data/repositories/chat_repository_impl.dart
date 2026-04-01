import 'package:dartz/dartz.dart';

import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/shared/chat/data/datasources/chat_remote_datasource.dart';
import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';
import 'package:tuish_food/features/shared/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final String _currentUserId;

  const ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required String currentUserId,
  })  : _remoteDataSource = remoteDataSource,
        _currentUserId = currentUserId;

  @override
  Stream<List<Message>> getMessages(String chatId) {
    return _remoteDataSource.getMessages(chatId);
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
  }) async {
    try {
      await _remoteDataSource.sendMessage(
        chatId,
        _currentUserId,
        text,
        imageUrl: imageUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getOrCreateChat(
    String orderId,
    String customerId,
    String deliveryPartnerId,
  ) async {
    try {
      final chatId = await _remoteDataSource.getOrCreateChat(
        orderId,
        customerId,
        deliveryPartnerId,
      );
      return Right(chatId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String chatId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.markAsRead(chatId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
