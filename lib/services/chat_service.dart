import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'appwrite_service.dart';
import '../models/user.dart';
import 'auth_service.dart';

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
  final String? withAvatarUrl; // Changed from withAvatar
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? lastActivity;
  final bool isOnline;

  ChatConversation({
    required this.chatId,
    required this.withUserId,
    required this.withName,
    this.withAvatarUrl,
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
      withAvatarUrl: json['withAvatarUrl'], // Changed from withAvatar
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
  final Ref ref;
  
  ChatService(this.ref) : super(const ChatState()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final authService = ref.read(authServiceProvider);
      final currentUser = ref.read(authProvider).user;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Query for chats where the user is either participant
      final response1 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [Query.equal('participant1Id', currentUser.uid)],
      );
      
      final response2 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [Query.equal('participant2Id', currentUser.uid)],
      );

      final allDocuments = [...response1.documents, ...response2.documents];
      final uniqueDocuments = { for (var doc in allDocuments) doc.$id : doc }.values.toList();

      final conversations = <ChatConversation>[];
      
      for (var doc in uniqueDocuments) {
        final otherUserId = doc.data['participant1Id'] == currentUser.uid 
            ? doc.data['participant2Id'] as String
            : doc.data['participant1Id'] as String;

        // Fetch the full profile of the other user
        final partnerProfile = await authService.getUserProfile(otherUserId);

        if (partnerProfile == null) {
          // Skip this conversation if the other user's profile can't be fetched
          continue;
        }

        // Determine the correct name and avatar for the conversation list
        String conversationName;
        String? conversationAvatarUrl;

        if (currentUser.role == 'employer') {
          // If I am an employer, the other person must be a seeker
          conversationName = partnerProfile.displayName;
          conversationAvatarUrl = partnerProfile.avatarUrl;
        } else {
          // If I am a seeker, the other person must be an employer
          conversationName = partnerProfile.companyName ?? partnerProfile.displayName;
          conversationAvatarUrl = partnerProfile.companyLogoUrl;
        }

        // Get the latest message for this chat
        final messagesResponse = await appwriteService.databases.listDocuments(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'messages',
          queries: [
            Query.equal('chatId', doc.$id),
            Query.orderDesc('\$createdAt'),
            Query.limit(1),
          ],
        );
        
        ChatMessage? lastMessage;
        if (messagesResponse.documents.isNotEmpty) {
          final messageDoc = messagesResponse.documents.first;
          lastMessage = ChatMessage.fromJson({
            ...messageDoc.data,
            'id': messageDoc.$id,
            'createdAt': messageDoc.$createdAt,
          });
        }
        
        conversations.add(ChatConversation(
          chatId: doc.$id,
          withUserId: otherUserId,
          withName: conversationName,
          withAvatarUrl: conversationAvatarUrl,
          lastMessage: lastMessage,
          unreadCount: 0, // TODO: Implement unread count logic
          lastActivity: lastMessage?.timestamp ?? DateTime.parse(doc.$updatedAt),
          isOnline: false, // TODO: Implement online status
        ));
      }
      
      // Sort by last activity
      conversations.sort((a, b) => (b.lastActivity ?? DateTime(1970)).compareTo(a.lastActivity ?? DateTime(1970)));
      
      final totalUnread = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        totalUnreadCount: totalUnread,
      );
    } catch (error, stackTrace) {
      print('Error loading conversations: $error');
      print(stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<String> createChat(String participantId, String participantName) async {
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final user = ref.read(authProvider).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if chat already exists
      final existingChats = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'chats',
        queries: [
          Query.equal('participant1Id', user.uid),
          Query.equal('participant2Id', participantId),
        ],
      );
      
      if (existingChats.total > 0) {
        return existingChats.documents.first.$id;
      }
      
      final now = DateTime.now().toIso8601String();
      
      // Create new chat
      final response = await appwriteService.databases.createDocument(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'chats',
        documentId: ID.unique(),
        data: {
          'participant1Id': user.uid,
          'participant1Name': user.displayName,
          'participant2Id': participantId,
          'participant2Name': participantName,
          'createdAt': now, // Add the createdAt attribute
          'updatedAt': now, // Add the updatedAt attribute
        },
      );
      
      return response.$id;
    } catch (error) {
      throw Exception('Failed to create chat: $error');
    }
  }

  Future<void> sendMessage(String chatId, String text, {MessageType type = MessageType.text}) async {
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final user = ref.read(authProvider).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      await appwriteService.databases.createDocument(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'messages',
        documentId: ID.unique(),
        data: {
          'chatId': chatId,
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Unknown User',
          'text': text,
          'type': type.name, // Add the type attribute
          'status': 'sent', // Add the status attribute
          'isRead': false, // Add the isRead attribute
          'createdAt': DateTime.now().toIso8601String(), // Add the createdAt attribute
        },
      );
      
      
      
      // Create a simple message object for updating local state
      final message = ChatMessage(
        id: ID.unique(),
        senderId: user.uid,
        senderName: user.displayName ?? 'Unknown User',
        text: text,
        timestamp: DateTime.now(),
        type: type,
        status: MessageStatus.sent,
      );
      
      // Update local state
      updateLastMessage(chatId, message);
    } catch (error) {
      print('Detailed error in sendMessage: $error');
      // Re-throw with more context
      throw Exception('Failed to send message: ${error.toString()}');
    }
  }

  Future<List<ChatMessage>> loadMessages(String chatId) async {
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      
      final response = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'messages',
        queries: [
          Query.equal('chatId', chatId),
          Query.orderDesc('\$createdAt'),
        ],
      );
      
      final messages = response.documents.map((doc) {
        return ChatMessage(
          id: doc.$id,
          senderId: doc.data['senderId'] as String? ?? '',
          senderName: doc.data['senderName'] as String? ?? 'Unknown User',
          text: doc.data['text'] as String? ?? '',
          timestamp: DateTime.parse(doc.$createdAt),
          isRead: doc.data['isRead'] as bool? ?? false,
          // Handle the type attribute
          type: MessageType.values.firstWhere(
            (e) => e.name == (doc.data['type'] as String? ?? 'text'),
            orElse: () => MessageType.text,
          ),
          // Handle the status attribute
          status: MessageStatus.values.firstWhere(
            (e) => e.name == (doc.data['status'] as String? ?? 'sent'),
            orElse: () => MessageStatus.sent,
          ),
        );
      }).toList();
      
      return messages;
    } catch (error) {
      throw Exception('Failed to load messages: $error');
    }
  }

  Future<void> markAsRead(String chatId) async {
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      
      // Update all unread messages in this chat to read
      // Note: This is a simplified implementation. In a real app, you might want to 
      // update messages in batches or use a more efficient approach.
      
      // First, get the current user
      final user = ref.read(authProvider).user;
      if (user == null) return;
      
      // Update local state
      final updatedConversations = state.conversations.map((conv) {
        if (conv.chatId == chatId) {
          return ChatConversation(
            chatId: conv.chatId,
            withUserId: conv.withUserId,
            withName: conv.withName,
            withAvatarUrl: conv.withAvatarUrl,
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
    } catch (error) {
      // Handle error silently for now, but in a real app you might want to show an error message
      print('Failed to mark messages as read: $error');
    }
  }

  Future<void> updateLastMessage(String chatId, ChatMessage message) async {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.chatId == chatId) {
        return ChatConversation(
          chatId: conv.chatId,
          withUserId: conv.withUserId,
          withName: conv.withName,
          withAvatarUrl: conv.withAvatarUrl,
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
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      
      // Delete all messages in the chat first
      final messagesResponse = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'messages',
        queries: [
          Query.equal('chatId', chatId),
        ],
      );
      
      // Delete messages (in a real app, you might want to do this in batches)
      for (var message in messagesResponse.documents) {
        await appwriteService.databases.deleteDocument(
          databaseId: '68bbb9e6003188d8686f', // mvpDB
          collectionId: 'messages',
          documentId: message.$id,
        );
      }
      
      // Delete the chat
      await appwriteService.databases.deleteDocument(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'chats',
        documentId: chatId,
      );
      
      // Update local state
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
    } catch (error) {
      throw Exception('Failed to delete conversation: $error');
    }
  }

  void updateOnlineStatus(String userId, bool isOnline) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.withUserId == userId) {
        return ChatConversation(
          chatId: conv.chatId,
          withUserId: conv.withUserId,
          withName: conv.withName,
          withAvatarUrl: conv.withAvatarUrl,
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
  (ref) => ChatService(ref),
);

// Individual chat room state
class ChatRoomState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? chatPartner;
  final bool isTyping;
  final bool isOnline;
  final String? chatPartnerAvatarUrl;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.chatPartner,
    this.isTyping = false,
    this.isOnline = false,
    this.chatPartnerAvatarUrl,
  });

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? chatPartner,
    bool? isTyping,
    bool? isOnline,
    String? chatPartnerAvatarUrl,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      chatPartner: chatPartner ?? this.chatPartner,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
      chatPartnerAvatarUrl: chatPartnerAvatarUrl ?? this.chatPartnerAvatarUrl,
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
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final chatService = ref.read(chatServiceProvider.notifier);
      final messages = await chatService.loadMessages(chatId);
      
      // Get chat partner details
      final chatState = ref.read(chatServiceProvider);
      ChatConversation? conversation;
      try {
        conversation = chatState.conversations.firstWhere((c) => c.chatId == chatId);
      } catch (e) {
        // Handle case where conversation is not in the list (e.g., deep link)
        print('Conversation not found in list, fetching details...');
      }

      String? otherUserId;
      if (conversation != null) {
        otherUserId = conversation.withUserId;
      } else {
        // Fallback: get partner ID from the chat document itself
        final appwriteService = ref.read(appwriteServiceProvider);
        final chatDoc = await appwriteService.databases.getDocument(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'chats',
          documentId: chatId,
        );
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null) {
           otherUserId = chatDoc.data['participant1Id'] == currentUser.uid
              ? chatDoc.data['participant2Id'] as String
              : chatDoc.data['participant1Id'] as String;
        }
      }

      String partnerName = 'Unknown User';
      String? partnerAvatarUrl;

      if (otherUserId != null) {
        final authService = ref.read(authServiceProvider);
                final partnerProfile = await authService.getUserProfile(otherUserId);
        if (partnerProfile != null) {
          if (partnerProfile.role == 'employer') {
            partnerName = partnerProfile.companyName ?? partnerProfile.displayName ?? 'Unknown Company';
            partnerAvatarUrl = partnerProfile.companyLogoUrl;
          } else {
            partnerName = partnerProfile.displayName ?? 'Unknown User';
            partnerAvatarUrl = partnerProfile.avatarUrl;
          }
        }
      }
      
      state = state.copyWith(
        messages: messages.reversed.toList(),
        isLoading: false,
        chatPartner: partnerName,
        chatPartnerAvatarUrl: partnerAvatarUrl,
        isOnline: conversation?.isOnline ?? false,
      );
      
      if (conversation != null) {
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

    final user = ref.read(authProvider).user;
    if (user == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    // 1. Optimistic UI: Create a message and add it to the state immediately.
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary local ID
      senderId: user.uid,
      senderName: user.displayName ?? 'Unknown User',
      text: text,
      timestamp: DateTime.now(),
      type: type,
      status: MessageStatus.sending, // Show as 'sending'
    );

    // The UI list is reversed, so add new messages to the beginning.
    state = state.copyWith(messages: [optimisticMessage, ...state.messages], error: null);

    try {
      final chatService = ref.read(chatServiceProvider.notifier);
      // 2. Send the message to the backend in the background.
      await chatService.sendMessage(chatId, text, type: type);

      // 3. On success, update the message from 'sending' to 'sent'.
      final updatedMessages = state.messages.map((m) {
        if (m.id == optimisticMessage.id) {
          // We don't have the real server ID, so we just update the status.
          // This is a limitation of the current backend implementation.
          return m.copyWith(status: MessageStatus.sent);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);

    } catch (error) {
      // 4. On failure, update the message to 'failed'.
      print('Error sending message: $error');
      final updatedMessages = state.messages.map((m) {
        if (m.id == optimisticMessage.id) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();
      state = state.copyWith(
        messages: updatedMessages,
        error: 'Failed to send message. Please try again.',
      );
    }
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