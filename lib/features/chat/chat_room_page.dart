import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatRoomPage({super.key, required this.chatId, required this.otherUserId});

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

  void _handleSubmitted(String text) {
    if (text.trim().isNotEmpty) {
      ref.read(chatRoomServiceProvider((widget.chatId, widget.otherUserId)).notifier).sendMessage(text.trim());
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  String _formatMessageTime(DateTime timestamp, String languageCode) {
    final localTimestamp = timestamp.toLocal();
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
    final providerTuple = (widget.chatId, widget.otherUserId);
    final chatState = ref.watch(chatRoomServiceProvider(providerTuple));
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    final currentUser = ref.watch(authProvider).user;

    final t = (String key) => AppLocalizations.translate(key, languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: CircleAvatar(
                radius: 17.5,
                backgroundColor: Colors.white,
                backgroundImage: (chatState.chatPartnerAvatarUrl != null && chatState.chatPartnerAvatarUrl!.isNotEmpty)
                    ? NetworkImage(chatState.chatPartnerAvatarUrl!)
                    : null,
                child: (chatState.chatPartnerAvatarUrl == null || chatState.chatPartnerAvatarUrl!.isEmpty)
                    ? Center(
                        child: Text(
                          (chatState.chatPartnerName ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.chatPartnerName ?? t('loading_partner'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Text(
                  //   chatState.isTyping ? t('typing') : chatState.isOnline ? t('online') : t('offline'),
                  //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //     color: chatState.isTyping
                  //         ? Theme.of(context).colorScheme.primary
                  //         : chatState.isOnline ? Colors.green : Colors.grey,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (currentUser?.role == 'employer' && chatState.chatPartnerRole == 'seeker')
            IconButton(
              onPressed: _requestVerification,
              icon: const Icon(Icons.verified_user_outlined),
              tooltip: t('view_verification'),
            ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('call_feature'))),
            ),
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(languageCode),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            Text(t('error_loading_messages'), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(chatState.error!),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          return _buildMessageBubble(message, languageCode, chatState.chatPartnerAvatarUrl);
                        },
                      ),
          ),
          // if (chatState.isTyping) ...
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('attach_file'))),
                              ),
                              icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: t('type_message'),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (text) => setState(() => _isComposing = text.trim().isNotEmpty),
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
                        color: _isComposing ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isComposing ? () => _handleSubmitted(_messageController.text) : null,
                        icon: Icon(Icons.send, color: _isComposing ? Colors.white : Colors.grey.shade600),
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
    final currentUserRole = ref.read(authProvider).user?.role;
    final isMe = message.senderId == currentUserId;

    if (message.type == MessageType.verification_request) {
      return _buildVerificationRequestBubble(message, isMe, currentUserRole, languageCode);
    } else if (message.type == MessageType.verification_response) {
      return _buildVerificationResponseBubble(message, isMe, currentUserRole, languageCode);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15.5,
              backgroundColor: Colors.grey.shade300,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                backgroundImage: (chatPartnerAvatarUrl != null && chatPartnerAvatarUrl.isNotEmpty)
                    ? NetworkImage(chatPartnerAvatarUrl)
                    : null,
                child: (chatPartnerAvatarUrl == null || chatPartnerAvatarUrl.isEmpty)
                    ? Center(
                        child: Text(
                          (message.senderName.isNotEmpty ? message.senderName : "U").substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp, languageCode),
                        style: TextStyle(color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600, fontSize: 11),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(_getStatusIcon(message.status), size: 12, color: Colors.white.withOpacity(0.8)),
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
    final t = (String key) => AppLocalizations.translate(key, languageCode);
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
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t('chat_info')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('chat_info_message'))));
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(t('block_user')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('block_user_message'))));
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: Text(t('report'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('report_sent')), backgroundColor: Colors.red),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRequestBubble(ChatMessage message, bool isMe, String? currentUserRole, String languageCode) {
    final t = (String key) => AppLocalizations.translate(key, languageCode);
    final chatState = ref.watch(chatRoomServiceProvider((widget.chatId, widget.otherUserId)));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.8) : Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            if (!isMe && currentUserRole == 'seeker')
              ElevatedButton(
                onPressed: () => _showPinInputDialog(),
                child: Text(t('respond_to_request')),
              ),
            if (isMe && currentUserRole == 'employer')
              Text(
                t('waiting_for_jober_response'),
                style: TextStyle(color: isMe ? Colors.white70 : Colors.black54),
              ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp, languageCode),
              style: TextStyle(color: isMe ? Colors.white.withOpacity(0.7) : Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationResponseBubble(ChatMessage message, bool isMe, String? currentUserRole, String languageCode) {
    final t = (String key) => AppLocalizations.translate(key, languageCode);
    Map<String, dynamic>? docUrls;
    try {
      docUrls = jsonDecode(message.text);
    } catch (e) {
      print('Error decoding verification response message: $e');
    }

    final idCardUrl = docUrls?['idCardUrl'] as String?;
    final selfieWithIdUrl = docUrls?['selfieWithIdUrl'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.8) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? t('you_shared_documents') : t('jober_shared_documents'),
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            if (!isMe && currentUserRole == 'employer' && idCardUrl != null && selfieWithIdUrl != null)
              ElevatedButton(
                onPressed: () => _showVerificationDocumentsDialog(idCardUrl, selfieWithIdUrl),
                child: Text(t('view_documents')),
              ),
            if (isMe && currentUserRole == 'seeker')
              Text(
                t('documents_sent_to_employer'),
                style: TextStyle(color: isMe ? Colors.white70 : Colors.black54),
              ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp, languageCode),
              style: TextStyle(color: isMe ? Colors.white.withOpacity(0.7) : Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestVerification() async {
    final providerTuple = (widget.chatId, widget.otherUserId);
    final chatRoomService = ref.read(chatRoomServiceProvider(providerTuple).notifier);
    final chatState = ref.read(chatRoomServiceProvider(providerTuple));
    final t = (String key) => AppLocalizations.translate(key, ref.read(languageProvider).languageCode);

    try {
      await chatRoomService.sendVerificationRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('verification_request_sent_to')} ${chatState.chatPartnerName ?? 'Jober'}.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('failed_to_send_verification_request')}: $e')),
      );
    }
  }

  Future<void> _showPinInputDialog() async {
    final pinController = TextEditingController();
    final languageState = ref.read(languageProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
    final chatState = ref.read(chatRoomServiceProvider((widget.chatId, widget.otherUserId)));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t('verification_request_from')} ${chatState.chatPartnerName ?? 'Employer'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('enter_pin_to_share_documents')),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: t('pin'),
                hintText: t('enter_your_pin'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: Text(t('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, pinController.text), child: Text(t('submit'))),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final chatRoomService = ref.read(chatRoomServiceProvider((widget.chatId, widget.otherUserId)).notifier);
        await chatRoomService.sendVerificationResponse(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('documents_shared_successfully'))),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('failed_to_share_documents')}: $e')),
        );
      }
    }
  }

  void _showVerificationDocumentsDialog(String idCardUrl, String selfieWithIdUrl) {
    final t = (String key) => AppLocalizations.translate(key, ref.read(languageProvider).languageCode);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('verification_documents')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('id_card_passport')),
              const SizedBox(height: 8),
              Image.network(idCardUrl),
              const SizedBox(height: 16),
              Text(t('selfie_with_id')),
              const SizedBox(height: 8),
              Image.network(selfieWithIdUrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('close'))),
        ],
      ),
    );
  }
}