import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_api.dart';

// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? attachmentUrl;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      attachmentUrl: json['attachmentUrl'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'attachmentUrl': attachmentUrl,
      'status': status.name,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? attachmentUrl,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
    );
  }
}

enum MessageType { text, image, file, voice }
enum MessageStatus { sending, sent, delivered, read, failed }

// Chat conversation model
class ChatConversation {
  final String chatId;
  final String withUserId;
  final String withName;
  final String? withAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? lastActivity;
  final bool isOnline;

  ChatConversation({
    required this.chatId,
    required this.withUserId,
    required this.withName,
    this.withAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastActivity,
    this.isOnline = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      chatId: json['chatId'] ?? '',
      withUserId: json['withUserId'] ?? '',
      withName: json['withName'] ?? '',
      withAvatar: json['withAvatar'],
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }
}

// Chat state
class ChatState {
  final List<ChatConversation> conversations;
  final bool isLoading;
  final String? error;
  final int totalUnreadCount;

  const ChatState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.totalUnreadCount = 0,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    bool? isLoading,
    String? error,
    int? totalUnreadCount,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }
}

// Chat service
class ChatService extends StateNotifier<ChatState> {
  ChatService() : super(const ChatState()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final data = await MockApi.loadChats();
      final chatList = (data['chats'] as List).cast<Map<String, dynamic>>();
      
      final conversations = chatList.map((chat) {
        final messages = (chat['messages'] as List)
            .cast<Map<String, dynamic>>()
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        
        final lastMessage = messages.isNotEmpty ? messages.last : null;
        
        return ChatConversation(
          chatId: chat['chatId'],
          withUserId: chat['withUserId'],
          withName: chat['withName'],
          withAvatar: chat['withAvatar'],
          lastMessage: lastMessage,
          unreadCount: chat['unreadCount'] ?? 0,
          lastActivity: lastMessage?.timestamp,
          isOnline: chat['isOnline'] ?? false,
        );
      }).toList();
      
      // Sort by last activity
      conversations.sort((a, b) {
        final aTime = a.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      final totalUnread = conversations.fold<int>(
        0, 
        (sum, conv) => sum + conv.unreadCount,
      );
      
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        totalUnreadCount: totalUnread,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> markAsRead(String chatId) async {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.chatId == chatId) {
        return ChatConversation(
          chatId: conv.chatId,
          withUserId: conv.withUserId,
          withName: conv.withName,
          withAvatar: conv.withAvatar,
          lastMessage: conv.lastMessage?.copyWith(isRead: true),
          unreadCount: 0,
          lastActivity: conv.lastActivity,
          isOnline: conv.isOnline,
        );
      }
      return conv;
    }).toList();
    
    final totalUnread = updatedConversations.fold<int>(
      0, 
      (sum, conv) => sum + conv.unreadCount,
    );
    
    state = state.copyWith(
      conversations: updatedConversations,
      totalUnreadCount: totalUnread,
    );
  }

  Future<void> updateLastMessage(String chatId, ChatMessage message) async {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.chatId == chatId) {
        return ChatConversation(
          chatId: conv.chatId,
          withUserId: conv.withUserId,
          withName: conv.withName,
          withAvatar: conv.withAvatar,
          lastMessage: message,
          unreadCount: message.senderId != 'me' ? conv.unreadCount + 1 : conv.unreadCount,
          lastActivity: message.timestamp,
          isOnline: conv.isOnline,
        );
      }
      return conv;
    }).toList();
    
    // Resort by last activity
    updatedConversations.sort((a, b) {
      final aTime = a.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    
    final totalUnread = updatedConversations.fold<int>(
      0, 
      (sum, conv) => sum + conv.unreadCount,
    );
    
    state = state.copyWith(
      conversations: updatedConversations,
      totalUnreadCount: totalUnread,
    );
  }

  Future<void> deleteConversation(String chatId) async {
    final updatedConversations = state.conversations
        .where((conv) => conv.chatId != chatId)
        .toList();
    
    final totalUnread = updatedConversations.fold<int>(
      0, 
      (sum, conv) => sum + conv.unreadCount,
    );
    
    state = state.copyWith(
      conversations: updatedConversations,
      totalUnreadCount: totalUnread,
    );
  }

  void updateOnlineStatus(String userId, bool isOnline) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.withUserId == userId) {
        return ChatConversation(
          chatId: conv.chatId,
          withUserId: conv.withUserId,
          withName: conv.withName,
          withAvatar: conv.withAvatar,
          lastMessage: conv.lastMessage,
          unreadCount: conv.unreadCount,
          lastActivity: conv.lastActivity,
          isOnline: isOnline,
        );
      }
      return conv;
    }).toList();
    
    state = state.copyWith(conversations: updatedConversations);
  }

  void refresh() {
    loadConversations();
  }
}

// Providers
final chatServiceProvider = StateNotifierProvider<ChatService, ChatState>(
  (ref) => ChatService(),
);

// Individual chat room state
class ChatRoomState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? chatPartner;
  final bool isTyping;
  final bool isOnline;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.chatPartner,
    this.isTyping = false,
    this.isOnline = false,
  });

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? chatPartner,
    bool? isTyping,
    bool? isOnline,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      chatPartner: chatPartner ?? this.chatPartner,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

// Chat room service
class ChatRoomService extends StateNotifier<ChatRoomState> {
  final String chatId;
  final Ref ref;
  
  ChatRoomService(this.chatId, this.ref) : super(const ChatRoomState()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final data = await MockApi.loadChats();
      final chats = (data['chats'] as List).cast<Map<String, dynamic>>();
      final chat = chats.firstWhere(
        (e) => e['chatId'] == chatId,
        orElse: () => {},
      );
      
      if (chat.isNotEmpty) {
        final messages = (chat['messages'] as List)
            .cast<Map<String, dynamic>>()
            .map((m) => ChatMessage.fromJson(m))
            .toList()
            .reversed
            .toList();
        
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          chatPartner: chat['withName'],
          isOnline: chat['isOnline'] ?? false,
        );
        
        // Mark as read in chat service
        ref.read(chatServiceProvider.notifier).markAsRead(chatId);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty) return;
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      text: text.trim(),
      timestamp: DateTime.now(),
      type: type,
      status: MessageStatus.sending,
    );
    
    // Add message immediately for better UX
    state = state.copyWith(
      messages: [message, ...state.messages],
    );
    
    // Update chat service with new message
    ref.read(chatServiceProvider.notifier).updateLastMessage(chatId, message);
    
    // Simulate sending delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update message status to sent
    final updatedMessages = state.messages.map((m) {
      return m.id == message.id ? m.copyWith(status: MessageStatus.sent) : m;
    }).toList();
    
    state = state.copyWith(messages: updatedMessages);
    
    // Simulate auto-reply after 2 seconds
    _simulateAutoReply();
  }

  void _simulateAutoReply() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Show typing indicator
      state = state.copyWith(isTyping: true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        
        final replies = [
          'ຂອບໃຈເຈົ້າ ພວກເຮົາຈະຕິດຕໍ່ກັບຄືນໃນໄວໆນີ້',
          'ຂໍຄວາມສະດວກໃນການສັມພາດໜ້ອຍເຈົ້າ',
          'ພວກເຮົາສາມາດນັດເວລາສັມພາດໄດ້ບໍເຈົ້າ?',
          'ຂໍໃຫ້ສົ່ງ Resume ມາດ້ວຍນະເຈົ້າ',
          'ສະບາຍດີເຈົ້າ ຍິນດີຕ້ອນຮັບ',
          'ຂອບໃຈທີ່ສົນໃຈຕໍາແໜ່ງງານຂອງພວກເຮົາ',
        ];
        
        final reply = replies[DateTime.now().millisecond % replies.length];
        final replyMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'hr',
          senderName: state.chatPartner ?? 'HR',
          text: reply,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        );
        
        state = state.copyWith(
          messages: [replyMessage, ...state.messages],
          isTyping: false,
        );
        
        // Update chat service
        ref.read(chatServiceProvider.notifier).updateLastMessage(chatId, replyMessage);
      });
    });
  }

  void simulateTyping() {
    state = state.copyWith(isTyping: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(isTyping: false);
      }
    });
  }

  void markMessagesAsRead() {
    final updatedMessages = state.messages.map((m) {
      return m.senderId != 'me' ? m.copyWith(isRead: true) : m;
    }).toList();
    
    state = state.copyWith(messages: updatedMessages);
  }

  void updateOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }
}

// Chat room provider
final chatRoomServiceProvider = StateNotifierProvider.family<ChatRoomService, ChatRoomState, String>(
  (ref, chatId) => ChatRoomService(chatId, ref),
);