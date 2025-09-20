import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Testing core chat functionality using HTTP API...');

  final projectId = '68bbb97a003baa58bb9c';
  final apiKey = 'standard_040b0edb3383d6fc688f3383ffb86e95f5de797dc14c914eb0696d8cc962bf4f45bda934b83e64e32c8b54cd408fe707a98b9e32fc927af03089e157457a502a9d3717a7141d950dcf6a007a10e3f1052044ea00f038b0309eecd9a8ca08c6b24f066e05361be51ba8c34a9522359ad7d56b34f1fd6d789972530333aa8c5647';
  final databaseId = '68bbb9e6003188d8686f';
  final endpoint = 'https://fra.cloud.appwrite.io/v1';

  final headers = {
    'X-Appwrite-Response-Format': '1.0.0',
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };

  String? chatId;
  String? messageId;

  try {
    // Test 1: Create a test chat
    print('\n1. Creating a test chat...');
    final chatClient = HttpClient();
    final chatUrl = Uri.parse('$endpoint/databases/$databaseId/collections/chats/documents');
    
    final chatRequest = await chatClient.postUrl(chatUrl);
    headers.forEach((key, value) => chatRequest.headers.set(key, value));
    
    final chatBody = jsonEncode({
      'documentId': 'unique()',
      'data': {
        'participant1Id': 'test_user_1',
        'participant1Name': 'Test User 1',
        'participant2Id': 'test_user_2',
        'participant2Name': 'Test User 2',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    });
    
    chatRequest.write(chatBody);
    final chatResponse = await chatRequest.close();
    
    if (chatResponse.statusCode == 201) {
      final chatResponseBody = await chatResponse.transform(utf8.decoder).join();
      final chatData = jsonDecode(chatResponseBody);
      chatId = chatData['\$id'];
      print('✅ Chat created with ID: $chatId');
    } else {
      final chatResponseBody = await chatResponse.transform(utf8.decoder).join();
      throw Exception('Failed to create chat: ${chatResponse.statusCode} - $chatResponseBody');
    }
    
    chatClient.close();
    
    // Test 2: Send a test message
    print('\n2. Sending a test message...');
    final messageClient = HttpClient();
    final messageUrl = Uri.parse('$endpoint/databases/$databaseId/collections/messages/documents');
    
    final messageRequest = await messageClient.postUrl(messageUrl);
    headers.forEach((key, value) => messageRequest.headers.set(key, value));
    
    final messageBody = jsonEncode({
      'documentId': 'unique()',
      'data': {
        'chatId': chatId,
        'senderId': 'test_user_1',
        'senderName': 'Test User 1',
        'text': 'Hello, this is a test message!',
        'type': 'text',
        'status': 'sent',
        'isRead': false,
      },
    });
    
    messageRequest.write(messageBody);
    final messageResponse = await messageRequest.close();
    
    if (messageResponse.statusCode == 201) {
      final messageResponseBody = await messageResponse.transform(utf8.decoder).join();
      final messageData = jsonDecode(messageResponseBody);
      messageId = messageData['\$id'];
      print('✅ Message sent with ID: $messageId');
    } else {
      final messageResponseBody = await messageResponse.transform(utf8.decoder).join();
      throw Exception('Failed to send message: ${messageResponse.statusCode} - $messageResponseBody');
    }
    
    messageClient.close();
    
    // Test 3: Update chat's updatedAt timestamp
    print('\n3. Updating chat timestamp...');
    final updateClient = HttpClient();
    final updateUrl = Uri.parse('$endpoint/databases/$databaseId/collections/chats/documents/$chatId');
    
    final updateRequest = await updateClient.patchUrl(updateUrl);
    headers.forEach((key, value) => updateRequest.headers.set(key, value));
    
    final updateBody = jsonEncode({
      'data': {
        'updatedAt': DateTime.now().toIso8601String(),
      },
    });
    
    updateRequest.write(updateBody);
    final updateResponse = await updateRequest.close();
    
    if (updateResponse.statusCode == 200) {
      print('✅ Chat timestamp updated');
    } else {
      final updateResponseBody = await updateResponse.transform(utf8.decoder).join();
      throw Exception('Failed to update chat: ${updateResponse.statusCode} - $updateResponseBody');
    }
    
    updateClient.close();
    
    // Test 4: Clean up - delete test message
    print('\n4. Cleaning up test message...');
    if (messageId != null) {
      final deleteMessageClient = HttpClient();
      final deleteMessageUrl = Uri.parse('$endpoint/databases/$databaseId/collections/messages/documents/$messageId');
      
      final deleteMessageRequest = await deleteMessageClient.deleteUrl(deleteMessageUrl);
      headers.forEach((key, value) => deleteMessageRequest.headers.set(key, value));
      
      final deleteMessageResponse = await deleteMessageRequest.close();
      
      if (deleteMessageResponse.statusCode == 204) {
        print('✅ Test message deleted');
      } else {
        final deleteMessageResponseBody = await deleteMessageResponse.transform(utf8.decoder).join();
        print('Warning: Failed to delete test message: ${deleteMessageResponse.statusCode} - $deleteMessageResponseBody');
      }
      
      deleteMessageClient.close();
    }
    
    // Test 5: Clean up - delete test chat
    print('\n5. Cleaning up test chat...');
    if (chatId != null) {
      final deleteChatClient = HttpClient();
      final deleteChatUrl = Uri.parse('$endpoint/databases/$databaseId/collections/chats/documents/$chatId');
      
      final deleteChatRequest = await deleteChatClient.deleteUrl(deleteChatUrl);
      headers.forEach((key, value) => deleteChatRequest.headers.set(key, value));
      
      final deleteChatResponse = await deleteChatRequest.close();
      
      if (deleteChatResponse.statusCode == 204) {
        print('✅ Test chat deleted');
      } else {
        final deleteChatResponseBody = await deleteChatResponse.transform(utf8.decoder).join();
        print('Warning: Failed to delete test chat: ${deleteChatResponse.statusCode} - $deleteChatResponseBody');
      }
      
      deleteChatClient.close();
    }
    
    print('\n🎉 All core tests passed! Chat functionality is working correctly.');
  } catch (e) {
    print('❌ Error during testing: $e');
    
    // Clean up any created resources in case of error
    if (messageId != null) {
      try {
        final cleanupClient = HttpClient();
        final cleanupUrl = Uri.parse('$endpoint/databases/$databaseId/collections/messages/documents/$messageId');
        
        final cleanupRequest = await cleanupClient.deleteUrl(cleanupUrl);
        headers.forEach((key, value) => cleanupRequest.headers.set(key, value));
        
        await cleanupRequest.close();
        cleanupClient.close();
        print('🧹 Cleaned up test message');
      } catch (cleanupError) {
        print('Warning: Failed to clean up test message: $cleanupError');
      }
    }
    
    if (chatId != null) {
      try {
        final cleanupClient = HttpClient();
        final cleanupUrl = Uri.parse('$endpoint/databases/$databaseId/collections/chats/documents/$chatId');
        
        final cleanupRequest = await cleanupClient.deleteUrl(cleanupUrl);
        headers.forEach((key, value) => cleanupRequest.headers.set(key, value));
        
        await cleanupRequest.close();
        cleanupClient.close();
        print('🧹 Cleaned up test chat');
      } catch (cleanupError) {
        print('Warning: Failed to clean up test chat: $cleanupError');
      }
    }
    
    exit(1);
  }
}