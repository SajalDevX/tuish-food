import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';
import 'package:tuish_food/features/shared/chat/presentation/providers/chat_provider.dart';
import 'package:tuish_food/features/shared/chat/presentation/widgets/message_bubble.dart';
import 'package:tuish_food/injection_container.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  final String chatId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref.read(markAsReadProvider).call(widget.chatId, currentUser.uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(position);
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() => _isComposing = false);

    await ref.read(sendMessageProvider.notifier).sendMessage(
          widget.chatId,
          text,
        );
  }

  Future<void> _handleSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref('chats/${widget.chatId}/$timestamp.jpg');
      await storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      await ref.read(sendMessageProvider.notifier).sendMessage(
            widget.chatId,
            '',
            imageUrl: downloadUrl,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.uid ?? '';

    // Mark messages as read when new messages arrive
    ref.listen(chatMessagesProvider(widget.chatId), (previous, next) {
      next.whenData((_) => _markMessagesAsRead());
      // Auto-scroll to bottom on new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Start a conversation',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }

                // Scroll to bottom after frame renders
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(animated: false);
                });

                return _buildMessageList(messages, currentUserId);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: AppSizes.iconXL,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      'Failed to load messages',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: widget.otherUserPhotoUrl != null
                ? NetworkImage(widget.otherUserPhotoUrl!)
                : null,
            child: widget.otherUserPhotoUrl == null
                ? Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.s12),
          // Name
          Expanded(
            child: Text(
              widget.otherUserName,
              style: AppTypography.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.divider,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, String currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSizes.s8,
        bottom: AppSizes.s8,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSentByMe = message.senderId == currentUserId;

        // Determine if we should show a date header
        final showDateHeader = index == 0 ||
            !_isSameDay(
              messages[index - 1].createdAt,
              message.createdAt,
            );

        // Determine if this message should show a tail
        // (it's the last message from this sender before a different sender or date)
        final isLastFromSender = index == messages.length - 1 ||
            messages[index + 1].senderId != message.senderId ||
            !_isSameDay(message.createdAt, messages[index + 1].createdAt);

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.createdAt),
            MessageBubble(
              message: message,
              isSentByMe: isSentByMe,
              showTail: isLastFromSender,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.s12,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: AppSizes.s4,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppSizes.borderRadiusPill,
          ),
          child: Text(
            date.smartDate,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s8,
            vertical: AppSizes.s8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              IconButton(
                onPressed: _handleSendImage,
                icon: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textSecondary,
                ),
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTouchTarget,
                  minHeight: AppSizes.minTouchTarget,
                ),
              ),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppSizes.borderRadiusXL,
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    style: AppTypography.bodyMedium,
                    onChanged: (text) {
                      final composing = text.trim().isNotEmpty;
                      if (composing != _isComposing) {
                        setState(() => _isComposing = composing);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.s4),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: _isComposing
                      ? AppColors.primary
                      : AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isComposing ? _handleSendMessage : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: AppSizes.minTouchTarget,
                      height: AppSizes.minTouchTarget,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.send_rounded,
                        color: _isComposing
                            ? AppColors.onPrimary
                            : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
