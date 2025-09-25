import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/user.dart' as local_user;
import 'appwrite_service.dart';
import 'auth_service.dart';

// Enums
enum MessageType { text, image, file, voice, verification_request, verification_response }
enum MessageStatus { sending, sent, delivered, read, failed }

// Models
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
      id: json['id'] ?? json[r'$id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json[r'$createdAt'] != null ? DateTime.parse(json[r'$createdAt']) : DateTime.now()),
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

// Main Chat Service (for conversation list)
class ChatService extends StateNotifier<ChatState> {
  final Ref ref;
  StreamSubscription<RealtimeMessage>? _streamSubscription;

  ChatService(this.ref) : super(const ChatState()) {
    loadConversations();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      final client = ref.read(appwriteServiceProvider).client;
      final realtime = Realtime(client);
      final dbId = '68bbb9e6003188d8686f';
      final collectionId = 'messages';
      final subscription = realtime.subscribe([
        'databases.$dbId.collections.$collectionId.documents'
      ]);

      _streamSubscription = subscription.stream.listen((response) {
        if (response.events.contains('databases.$dbId.collections.$collectionId.documents.*.create')) {
          _handleRealtimeMessage(response.payload);
        }
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

  void _handleRealtimeMessage(Map<String, dynamic> payload) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final newMessage = ChatMessage.fromJson(payload);

    if (newMessage.senderId == user.uid) {
      return; // Don't process outgoing messages here
    }

    final incomingChatId = payload['chatId'] as String;
    int conversationIndex = state.conversations.indexWhere((c) => c.chatId == incomingChatId);

    if (conversationIndex != -1) {
      final conversation = state.conversations[conversationIndex];
      final updatedConversation = ChatConversation(
        chatId: conversation.chatId,
        withUserId: conversation.withUserId,
        withName: conversation.withName,
        withAvatar: conversation.withAvatar,
        lastMessage: newMessage,
        unreadCount: conversation.unreadCount + 1,
        lastActivity: newMessage.timestamp,
        isOnline: conversation.isOnline,
      );

      final updatedList = List<ChatConversation>.from(state.conversations);
      updatedList.removeAt(conversationIndex);
      updatedList.insert(0, updatedConversation);

      final totalUnread = updatedList.fold<int>(0, (sum, conv) => sum + conv.unreadCount);

      state = state.copyWith(
        conversations: updatedList,
        totalUnreadCount: totalUnread,
      );
    } else {
      // If conversation doesn't exist, reload all to fetch the new one
      loadConversations();
    }
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not authenticated');

      final response1 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [Query.equal('participant1Id', user.uid)],
      );

      final response2 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [Query.equal('participant2Id', user.uid)],
      );

      final allDocuments = [...response1.documents, ...response2.documents];
      final uniqueDocuments = { for (var doc in allDocuments) doc.$id : doc }.values.toList();

      final otherUserIds = uniqueDocuments.map((doc) {
        return doc.data['participant1Id'] == user.uid
            ? doc.data['participant2Id'] as String
            : doc.data['participant1Id'] as String;
      }).toSet();

      final Map<String, local_user.User> otherUserProfilesMap = {};
      if (otherUserIds.isNotEmpty) {
        final profilesResponse = await appwriteService.databases.listDocuments(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'user_profiles',
          queries: [Query.equal(r'$id', otherUserIds.toList())],
        );
        for (var doc in profilesResponse.documents) {
          otherUserProfilesMap[doc.$id] = local_user.User.fromJson(doc.data..[r'$id'] = doc.$id);
        }
      }

      List<ChatConversation> conversations = [];
      for (var doc in uniqueDocuments) {
        final otherUserId = doc.data['participant1Id'] == user.uid
            ? doc.data['participant2Id'] as String
            : doc.data['participant1Id'] as String;
        final otherUserName = doc.data['participant1Id'] == user.uid
            ? doc.data['participant2Name'] as String
            : doc.data['participant1Name'] as String;

        final messagesResponse = await appwriteService.databases.listDocuments(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'messages',
          queries: [
            Query.equal('chatId', doc.$id),
            Query.orderDesc(r'$createdAt'),
            Query.limit(1),
          ],
        );

        ChatMessage? lastMessage;
        if (messagesResponse.documents.isNotEmpty) {
          lastMessage = ChatMessage.fromJson(messagesResponse.documents.first.data..[r'$id'] = messagesResponse.documents.first.$id);
        }

        final unreadCountResponse = await appwriteService.databases.listDocuments(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'messages',
          queries: [
            Query.equal('chatId', doc.$id),
            Query.equal('isRead', false),
            Query.notEqual('senderId', user.uid),
          ],
        );
        final unreadCount = unreadCountResponse.total;

        final otherUserProfile = otherUserProfilesMap[otherUserId];
        String? otherUserAvatarUrl = otherUserProfile?.role == 'employer'
            ? otherUserProfile?.companyLogoUrl
            : otherUserProfile?.avatarUrl;

        conversations.add(ChatConversation(
          chatId: doc.$id,
          withUserId: otherUserId,
          withName: otherUserName,
          withAvatar: otherUserAvatarUrl,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
          lastActivity: lastMessage?.timestamp ?? DateTime.parse(doc.$updatedAt),
          isOnline: false, // TODO: Implement online status
        ));
      }

      conversations.sort((a, b) => (b.lastActivity ?? DateTime(0)).compareTo(a.lastActivity ?? DateTime(0)));
      final totalUnread = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        totalUnreadCount: totalUnread,
      );
    } catch (error, stacktrace) {
      print('Error loading conversations: $error');
      print(stacktrace);
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<String> findOrCreateChat(String otherUserId) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception("User not authenticated");

    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      // Check if a chat already exists between the two users
      final query1 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [
          Query.equal('participant1Id', user.uid),
          Query.equal('participant2Id', otherUserId),
        ],
      );

      if (query1.documents.isNotEmpty) {
        return query1.documents.first.$id;
      }

      final query2 = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        queries: [
          Query.equal('participant1Id', otherUserId),
          Query.equal('participant2Id', user.uid),
        ],
      );

      if (query2.documents.isNotEmpty) {
        return query2.documents.first.$id;
      }

      // If no chat exists, create a new one
      final otherUserProfile = await ref.read(authServiceProvider).getUserProfile(otherUserId);
      if (otherUserProfile == null) throw Exception("Other user profile not found");

      final newChatDoc = await appwriteService.databases.createDocument(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'chats',
        documentId: ID.unique(),
        data: {
          'participant1Id': user.uid,
          'participant1Name': user.displayName,
          'participant2Id': otherUserId,
          'participant2Name': otherUserProfile.displayName,
        },
      );
      loadConversations(); // Refresh list
      return newChatDoc.$id;
    } catch (e) {
      print('Error finding or creating chat: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String chatId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final conversationIndex = state.conversations.indexWhere((c) => c.chatId == chatId);
    if (conversationIndex == -1 || state.conversations[conversationIndex].unreadCount == 0) return;

    final conversation = state.conversations[conversationIndex];
    final updatedConversation = ChatConversation(
      chatId: conversation.chatId,
      withUserId: conversation.withUserId,
      withName: conversation.withName,
      withAvatar: conversation.withAvatar,
      lastMessage: conversation.lastMessage,
      unreadCount: 0,
      lastActivity: conversation.lastActivity,
      isOnline: conversation.isOnline,
    );

    final updatedList = List<ChatConversation>.from(state.conversations)..[conversationIndex] = updatedConversation;
    final totalUnread = updatedList.fold<int>(0, (sum, conv) => sum + conv.unreadCount);

    state = state.copyWith(conversations: updatedList, totalUnreadCount: totalUnread);

    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final unreadMessages = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'messages',
        queries: [
          Query.equal('chatId', chatId),
          Query.equal('isRead', false),
          Query.notEqual('senderId', user.uid),
        ],
      );

      for (final message in unreadMessages.documents) {
        await appwriteService.databases.updateDocument(
          databaseId: '68bbb9e6003188d8686f',
          collectionId: 'messages',
          documentId: message.$id,
          data: {'isRead': true},
        );
      }
    } catch (error) {
      print('Failed to mark messages as read on backend: $error');
      // Optionally revert local state change
    }
  }

  Future<void> deleteConversation(String chatId) async {
    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      
      // Delete all messages in the chat first
      final messagesResponse = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'messages',
        queries: [
          Query.equal('chatId', chatId)],
      );
      
      for (var message in messagesResponse.documents) {
        await appwriteService.databases.deleteDocument(
          databaseId: '68bbb9e6003188d8686f', // mvpDB
          collectionId: 'messages',
          documentId: message.$id,
        );
      }
      
      await appwriteService.databases.deleteDocument(
        databaseId: '68bbb9e6003188d8686f', // mvpDB
        collectionId: 'chats',
        documentId: chatId,
      );
      
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
      throw Exception('Failed to delete conversation: ${error.toString()}');
    }
  }
  
  void refresh() {
    loadConversations();
  }
}

// Individual Chat Room State & Service
class ChatRoomState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? chatPartnerName;
  final String? chatPartnerAvatarUrl;
  final String? chatPartnerRole;
  final String? chatPartnerVerificationStatus;
  final String? chatPartnerId;
  final bool isSending;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.chatPartnerName,
    this.chatPartnerAvatarUrl,
    this.chatPartnerRole,
    this.chatPartnerVerificationStatus,
    this.chatPartnerId,
    this.isSending = false,
  });

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? chatPartnerName,
    String? chatPartnerAvatarUrl,
    String? chatPartnerRole,
    String? chatPartnerVerificationStatus,
    String? chatPartnerId,
    bool? isSending,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      chatPartnerName: chatPartnerName ?? this.chatPartnerName,
      chatPartnerAvatarUrl: chatPartnerAvatarUrl ?? this.chatPartnerAvatarUrl,
      chatPartnerRole: chatPartnerRole ?? this.chatPartnerRole,
      chatPartnerVerificationStatus: chatPartnerVerificationStatus ?? this.chatPartnerVerificationStatus,
      chatPartnerId: chatPartnerId ?? this.chatPartnerId,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatRoomService extends StateNotifier<ChatRoomState> {
  final String chatId;
  final String otherUserId;
  final Ref ref;
  StreamSubscription<RealtimeMessage>? _streamSubscription;

  ChatRoomService(this.chatId, this.otherUserId, this.ref) : super(const ChatRoomState()) {
    _loadInitialData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch partner profile first
      final partnerProfile = await ref.read(authServiceProvider).getUserProfile(otherUserId);
      if (partnerProfile == null) throw Exception("Partner profile not found");

      final partnerAvatarUrl = partnerProfile.role == 'employer'
          ? partnerProfile.companyLogoUrl
          : partnerProfile.avatarUrl;

      // Fetch messages
      final appwriteService = ref.read(appwriteServiceProvider);
      final messagesResponse = await appwriteService.databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'messages',
        queries: [
          Query.equal('chatId', chatId),
          Query.orderDesc(r'$createdAt'),
          Query.limit(50), // Load recent 50 messages
        ],
      );
      final messages = messagesResponse.documents.map((doc) => ChatMessage.fromJson(doc.data..[r'$id'] = doc.$id)).toList();

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        chatPartnerName: partnerProfile.displayName,
        chatPartnerAvatarUrl: partnerAvatarUrl,
        chatPartnerRole: partnerProfile.role,
        chatPartnerVerificationStatus: partnerProfile.verificationStatus,
        chatPartnerId: otherUserId,
      );

      // Mark messages as read after loading
      ref.read(chatServiceProvider.notifier).markAsRead(chatId);
    } catch (e, st) {
      print('Error loading initial chat data: $e');
      print(st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime() {
    try {
      final client = ref.read(appwriteServiceProvider).client;
      final realtime = Realtime(client);
      final dbId = '68bbb9e6003188d8686f';
      final collectionId = 'messages';
      final subscription = realtime.subscribe([
        'databases.$dbId.collections.$collectionId.documents'
      ]);

      _streamSubscription = subscription.stream.listen((response) {
        if (response.payload['chatId'] == chatId) {
          final eventType = response.events.first.split('.').last;
          if (eventType == 'create') {
            _handleRealtimeMessageCreate(response.payload);
          }
        }
      });
    } catch (e) {
      state = state.copyWith(error: 'Could not connect to real-time service.');
    }
  }

  void _handleRealtimeMessageCreate(Map<String, dynamic> payload) {
    final newMessage = ChatMessage.fromJson(payload);
    final currentUser = ref.read(authProvider).user;

    // If it's an echo of a message we just sent, we replace the optimistic one
    if (currentUser != null && newMessage.senderId == currentUser.uid) {
      final updatedMessages = state.messages.map((m) {
        return (m.status == MessageStatus.sending && m.text == newMessage.text) ? newMessage : m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
    } else { // Otherwise, it's a new message from the other user
      if (!state.messages.any((m) => m.id == newMessage.id)) {
        state = state.copyWith(messages: [newMessage, ...state.messages]);
        ref.read(chatServiceProvider.notifier).markAsRead(chatId);
      }
    }
  }

  Future<void> sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isSending: true);

    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderName: user.displayName,
      text: text,
      timestamp: DateTime.now(),
      type: type,
      status: MessageStatus.sending,
    );

    state = state.copyWith(messages: [optimisticMessage, ...state.messages]);

    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      await appwriteService.databases.createDocument(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'messages',
        documentId: ID.unique(),
        data: {
          'chatId': chatId,
          'senderId': user.uid,
          'senderName': user.displayName,
          'text': text,
          'type': type.name,
          'status': 'sent',
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      // Realtime listener will handle updating the message status
    } catch (error) {
      final updatedMessages = state.messages.map((m) {
        return m.id == optimisticMessage.id ? m.copyWith(status: MessageStatus.failed) : m;
      }).toList();
      state = state.copyWith(
        messages: updatedMessages,
        error: 'Failed to send message.',
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendVerificationRequest() async {
    final employerName = ref.read(authProvider).user?.displayName ?? 'An employer';
    final messageText = '$employerName has requested to view your identity verification documents. Please respond with your PIN to grant access.';
    await sendMessage(messageText, type: MessageType.verification_request);
  }

  Future<void> sendVerificationResponse(String pin) async {
    final joberId = ref.read(authProvider).user?.uid;
    if (joberId == null) throw Exception('User not authenticated');

    try {
      final authService = ref.read(authServiceProvider);
      final joberProfile = await authService.getUserProfile(joberId);

      if (joberProfile == null || joberProfile.verificationPinHash == null) {
        throw Exception('Your verification information is not set up.');
      }

      final bytes = utf8.encode(pin);
      final digest = sha256.convert(bytes);
      final hashedPin = digest.toString();

      if (hashedPin != joberProfile.verificationPinHash) {
        throw Exception('Incorrect PIN.');
      }

      final messageText = jsonEncode({
        'idCardUrl': joberProfile.idCardUrl,
        'selfieWithIdUrl': joberProfile.selfieWithIdUrl,
      });

      await sendMessage(messageText, type: MessageType.verification_response);
    } catch (e) {
      print("Error sending verification response: $e");
      rethrow;
    }
  }
}

// Providers
final chatServiceProvider = StateNotifierProvider<ChatService, ChatState>(
  (ref) => ChatService(ref),
);

final chatRoomServiceProvider = StateNotifierProvider.family<ChatRoomService, ChatRoomState, (String, String)>(
  (ref, ids) => ChatRoomService(ids.$1, ids.$2, ref),
);