import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/language_service.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  String _formatMessageTime(String? timestamp, String languageCode) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (diff.inDays == 1) {
        return AppLocalizations.translate('yesterday', languageCode);
      } else if (diff.inDays < 7) {
        return DateFormat('EEE').format(date);
      } else {
        return DateFormat('dd/MM').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  Color _getOnlineStatusColor() {
    // Mock online status - in real app would be from real-time data
    return Colors.green;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatServiceProvider);
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Get translations
    final chatTitle = AppLocalizations.translate('chat', languageCode);
    final searchTooltip = AppLocalizations.translate('search', languageCode);
    final loadError = AppLocalizations.translate('error_loading_chats', languageCode);
    final tryAgain = AppLocalizations.translate('try_again', languageCode);
    final noChats = AppLocalizations.translate('no_chats', languageCode);
    final noChatsDesc = AppLocalizations.translate('no_chats_desc', languageCode);
    final findJobs = AppLocalizations.translate('find_jobs', languageCode);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(chatTitle),
            if (chatState.totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${chatState.totalUnreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Search chats functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.translate('search_chats_feature', languageCode))),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: searchTooltip,
          ),
        ],
      ),
      body: chatState.isLoading
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
                        loadError,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chatState.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(chatServiceProvider.notifier).refresh(),
                        child: Text(tryAgain),
                      ),
                    ],
                  ),
                )
              : chatState.conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            noChats,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            noChatsDesc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to job search
                              DefaultTabController.of(context)?.animateTo(0);
                            },
                            icon: const Icon(Icons.work_outline),
                            label: Text(findJobs),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.read(chatServiceProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatState.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = chatState.conversations[index];
                          return _buildChatItem(context, ref, conversation, languageCode);
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, ChatConversation conversation, String languageCode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Mark as read when tapping
            if (conversation.unreadCount > 0) {
              ref.read(chatServiceProvider.notifier).markAsRead(conversation.chatId);
            }
            context.push('/chats/${conversation.chatId}?otherUserId=${conversation.withUserId}');
          },
          onLongPress: () => _showChatOptions(context, ref, conversation, languageCode),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: conversation.unreadCount > 0 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: conversation.unreadCount > 0
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: (conversation.withAvatar != null && conversation.withAvatar!.isNotEmpty)
                          ? NetworkImage(conversation.withAvatar!)
                          : null,
                      child: (conversation.withAvatar == null || conversation.withAvatar!.isEmpty)
                          ? Center(
                              child: Text(
                                (conversation.withName.isNotEmpty ? conversation.withName : "U").substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Online status indicator
                    if (conversation.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.withName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: conversation.unreadCount > 0 
                                    ? FontWeight.bold 
                                    : FontWeight.w500,
                                color: conversation.unreadCount > 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation.lastMessage != null
                                ? _formatMessageTime(conversation.lastMessage!.timestamp.toIso8601String(), languageCode)
                                : '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: conversation.unreadCount > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: conversation.unreadCount > 0 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Last message and unread count
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage?.text ?? AppLocalizations.translate('start_conversation', languageCode),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: conversation.unreadCount > 0
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: conversation.unreadCount > 0 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          
                          // Unread count badge
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99 
                                    ? '99+' 
                                    : conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context, WidgetRef ref, ChatConversation conversation, String languageCode) {
    final markAsRead = AppLocalizations.translate('mark_as_read', languageCode);
    final markAsUnread = AppLocalizations.translate('mark_as_unread', languageCode);
    final deleteChat = AppLocalizations.translate('delete_chat', languageCode);
    
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
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                conversation.unreadCount > 0 ? Icons.mark_chat_read : Icons.mark_chat_unread,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                conversation.unreadCount > 0 ? markAsRead : markAsUnread,
              ),
              onTap: () {
                Navigator.pop(context);
                if (conversation.unreadCount > 0) {
                  ref.read(chatServiceProvider.notifier).markAsRead(conversation.chatId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(markAsUnread)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: Text(
                deleteChat,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, conversation, languageCode);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ChatConversation conversation, String languageCode) {
    final deleteChat = AppLocalizations.translate('delete_chat', languageCode);
    final deleteChatConfirm = AppLocalizations.translate('delete_chat_confirm', languageCode);
    final cancel = AppLocalizations.translate('cancel', languageCode);
    final delete = AppLocalizations.translate('delete', languageCode);
    final chatDeleted = AppLocalizations.translate('chat_deleted', languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteChat),
        content: Text('$deleteChatConfirm ${conversation.withName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatServiceProvider.notifier).deleteConversation(conversation.chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$chatDeleted ${conversation.withName}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(delete),
          ),
        ],
      ),
    );
  }
}