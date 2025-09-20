import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Setting up chat collections in Appwrite using HTTP API...');

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

  try {
    // Check if chats collection exists
    final chatsCollectionExists = await collectionExists(endpoint, projectId, databaseId, 'chats', headers);
    
    if (!chatsCollectionExists) {
      print('Creating Chats collection...');
      final chatsResponse = await createCollection(
        endpoint,
        projectId,
        databaseId,
        'chats',
        'Chats',
        headers,
      );
      
      if (chatsResponse.statusCode == 201) {
        print('Chats collection created successfully');
        final responseBody = await chatsResponse.transform(utf8.decoder).join();
        final chatsData = jsonDecode(responseBody);
        final chatsCollectionId = chatsData['\$id'];
        
        // Add attributes to Chats collection
        await createStringAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'participant1Id', 255, true, headers);
        print('Added participant1Id attribute to Chats collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'participant2Id', 255, true, headers);
        print('Added participant2Id attribute to Chats collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'participant1Name', 255, true, headers);
        print('Added participant1Name attribute to Chats collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'participant2Name', 255, true, headers);
        print('Added participant2Name attribute to Chats collection');
        
        await createDatetimeAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'createdAt', true, headers);
        print('Added createdAt attribute to Chats collection');
        
        await createDatetimeAttribute(endpoint, projectId, databaseId, chatsCollectionId, 'updatedAt', true, headers);
        print('Added updatedAt attribute to Chats collection');
      } else {
        final responseBody = await chatsResponse.transform(utf8.decoder).join();
        print('Failed to create Chats collection: ${chatsResponse.statusCode} - $responseBody');
      }
    } else {
      print('Chats collection already exists');
    }

    // Check if messages collection exists
    final messagesCollectionExists = await collectionExists(endpoint, projectId, databaseId, 'messages', headers);
    
    if (!messagesCollectionExists) {
      print('Creating Messages collection...');
      final messagesResponse = await createCollection(
        endpoint,
        projectId,
        databaseId,
        'messages',
        'Messages',
        headers,
      );
      
      if (messagesResponse.statusCode == 201) {
        print('Messages collection created successfully');
        final responseBody = await messagesResponse.transform(utf8.decoder).join();
        final messagesData = jsonDecode(responseBody);
        final messagesCollectionId = messagesData['\$id'];
        
        // Add attributes to Messages collection
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'chatId', 255, true, headers);
        print('Added chatId attribute to Messages collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'senderId', 255, true, headers);
        print('Added senderId attribute to Messages collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'senderName', 255, true, headers);
        print('Added senderName attribute to Messages collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'text', 1000, true, headers);
        print('Added text attribute to Messages collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'type', 50, true, headers, 'text');
        print('Added type attribute to Messages collection');
        
        await createStringAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'status', 50, true, headers, 'sent');
        print('Added status attribute to Messages collection');
        
        await createBooleanAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'isRead', true, headers, false);
        print('Added isRead attribute to Messages collection');
        
        await createDatetimeAttribute(endpoint, projectId, databaseId, messagesCollectionId, 'createdAt', true, headers);
        print('Added createdAt attribute to Messages collection');
      } else {
        final responseBody = await messagesResponse.transform(utf8.decoder).join();
        print('Failed to create Messages collection: ${messagesResponse.statusCode} - $responseBody');
      }
    } else {
      print('Messages collection already exists');
    }

    print('All chat collections setup completed!');
  } catch (e) {
    print('Error setting up chat collections: $e');
    exit(1);
  }
}

Future<HttpClientResponse> createCollection(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  String name,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  final url = Uri.parse('$endpoint/databases/$databaseId/collections');
  
  final request = await client.postUrl(url);
  headers.forEach((key, value) => request.headers.set(key, value));
  
  final body = jsonEncode({
    'collectionId': collectionId,
    'name': name,
    'permissions': [
      'read("any")',
      'create("any")',
      'update("any")',
      'delete("any")',
    ],
    'documentSecurity': true,
  });
  
  request.write(body);
  return await request.close();
}

Future<bool> collectionExists(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId');
  
  try {
    final request = await client.getUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final response = await request.close();
    await response.drain(); // Drain the response to avoid memory leaks
    
    return response.statusCode == 200;
  } catch (e) {
    return false;
  } finally {
    client.close();
  }
}

Future<void> createStringAttribute(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  String key,
  int size,
  bool required,
  Map<String, String> headers, [
  String? defaultValue,
]) async {
  final client = HttpClient();
  final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/string');
  
  final request = await client.postUrl(url);
  headers.forEach((key, value) => request.headers.set(key, value));
  
  final body = jsonEncode({
    'key': key,
    'size': size,
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
  });
  
  request.write(body);
  final response = await request.close();
  await response.drain();
  client.close();
}

Future<void> createDatetimeAttribute(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  String key,
  bool required,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/datetime');
  
  final request = await client.postUrl(url);
  headers.forEach((key, value) => request.headers.set(key, value));
  
  final body = jsonEncode({
    'key': key,
    'required': required,
    'default': '2025-09-17T00:00:00.000+00:00',
  });
  
  request.write(body);
  final response = await request.close();
  await response.drain();
  client.close();
}

Future<void> createBooleanAttribute(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  String key,
  bool required,
  Map<String, String> headers,
  bool defaultValue,
) async {
  final client = HttpClient();
  final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/boolean');
  
  final request = await client.postUrl(url);
  headers.forEach((key, value) => request.headers.set(key, value));
  
  final body = jsonEncode({
    'key': key,
    'required': required,
    'default': defaultValue,
  });
  
  request.write(body);
  final response = await request.close();
  await response.drain();
  client.close();
}