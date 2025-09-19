import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatRoomPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
    
    ref.read(chatRoomServiceProvider(widget.chatId).notifier).sendMessage(text);
  }

  void _handleSubmitted(String text) {
    if (text.trim().isNotEmpty) {
      sendMessage(text.trim());
    }
  }

  String _formatMessageTime(DateTime timestamp, String languageCode) {
    final localTimestamp = timestamp.toLocal(); // Convert to local time
    final now = DateTime.now();
    final diff = now.difference(localTimestamp);
    
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(localTimestamp);
    } else if (diff.inDays == 1) {
      return '${AppLocalizations.translate('yesterday', languageCode)} ${DateFormat('HH:mm').format(localTimestamp)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(localTimestamp);
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatRoomServiceProvider(widget.chatId));
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Get translations
    final loadingText = AppLocalizations.translate('loading', languageCode);
    final errorLoadingMessages = AppLocalizations.translate('error_loading_messages', languageCode);
    final callFeature = AppLocalizations.translate('call_feature', languageCode);
    final attachFile = AppLocalizations.translate('attach_file', languageCode);
    final typeMessage = AppLocalizations.translate('type_message', languageCode);
    final typing = AppLocalizations.translate('typing', languageCode);
    final online = AppLocalizations.translate('online', languageCode);
    final offline = AppLocalizations.translate('offline', languageCode);
    final chatInfo = AppLocalizations.translate('chat_info', languageCode);
    final blockUser = AppLocalizations.translate('block_user', languageCode);
    final report = AppLocalizations.translate('report', languageCode);
    final reportSent = AppLocalizations.translate('report_sent', languageCode);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17.5,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: (chatState.chatPartnerAvatarUrl != null && chatState.chatPartnerAvatarUrl!.isNotEmpty)
                  ? NetworkImage(chatState.chatPartnerAvatarUrl!)
                  : null,
              child: (chatState.chatPartnerAvatarUrl == null || chatState.chatPartnerAvatarUrl!.isEmpty)
                  ? Center(
                      child: Text(
                        (chatState.chatPartner ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.chatPartner ?? AppLocalizations.translate('loading_partner', languageCode),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    chatState.isTyping ? typing : chatState.isOnline ? online : offline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: chatState.isTyping 
                          ? Theme.of(context).colorScheme.primary
                          : chatState.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Voice call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(callFeature)),
              );
            },
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: () {
              // TODO: More options
              _showMoreOptions(languageCode);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorLoadingMessages,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(chatState.error!),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          return _buildMessageBubble(message, languageCode, chatState.chatPartnerAvatarUrl);
                        },
                      ),
          ),
          
          // Typing indicator
          if (chatState.isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          typing,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // TODO: Attachment functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(attachFile),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.attach_file,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: typeMessage,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (text) {
                                  setState(() {
                                    _isComposing = text.trim().isNotEmpty;
                                  });
                                },
                                onSubmitted: _handleSubmitted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isComposing 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_messageController.text)
                            : null,
                        icon: Icon(
                          Icons.send,
                          color: _isComposing ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String languageCode, String? chatPartnerAvatarUrl) {
    final currentUserId = ref.read(authProvider).user?.uid;
    final isMe = message.senderId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: (chatPartnerAvatarUrl != null && chatPartnerAvatarUrl.isNotEmpty)
                  ? NetworkImage(chatPartnerAvatarUrl)
                  : null,
              child: (chatPartnerAvatarUrl == null || chatPartnerAvatarUrl.isEmpty)
                  ? Center(
                      child: Text(
                        (message.senderName.isNotEmpty ? message.senderName : "U").substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp, languageCode),
                        style: TextStyle(
                          color: isMe 
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe && message.status != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status!),
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  void _showMoreOptions(String languageCode) {
    final chatInfo = AppLocalizations.translate('chat_info', languageCode);
    final blockUser = AppLocalizations.translate('block_user', languageCode);
    final report = AppLocalizations.translate('report', languageCode);
    final reportSent = AppLocalizations.translate('report_sent', languageCode);
    final chatInfoMsg = AppLocalizations.translate('chat_info_message', languageCode);
    final blockUserMsg = AppLocalizations.translate('block_user_message', languageCode);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(chatInfo),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(chatInfoMsg)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(blockUser),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(blockUserMsg)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: Text(report, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reportSent),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}