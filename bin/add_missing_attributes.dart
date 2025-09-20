import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Adding missing attributes to chat collections in Appwrite...');

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
    // Get current chats collection to check existing attributes
    print('\n1. Checking current Chats collection attributes...');
    final chatsData = await checkCollection(endpoint, projectId, databaseId, 'chats', headers);
    
    if (chatsData != null) {
      final existingAttributes = <String>{};
      for (var attr in chatsData['attributes']) {
        existingAttributes.add(attr['key']);
      }
      
      print('Existing attributes: $existingAttributes');
      
      // Add missing attributes if they don't exist
      if (!existingAttributes.contains('createdAt')) {
        print('Adding createdAt attribute to Chats collection...');
        await createDatetimeAttribute(endpoint, projectId, databaseId, 'chats', 'createdAt', true, headers);
        print('✅ Added createdAt attribute');
      } else {
        print('✅ createdAt attribute already exists');
      }
      
      if (!existingAttributes.contains('updatedAt')) {
        print('Adding updatedAt attribute to Chats collection...');
        await createDatetimeAttribute(endpoint, projectId, databaseId, 'chats', 'updatedAt', true, headers);
        print('✅ Added updatedAt attribute');
      } else {
        print('✅ updatedAt attribute already exists');
      }
    }

    // Get current messages collection to check existing attributes
    print('\n2. Checking current Messages collection attributes...');
    final messagesData = await checkCollection(endpoint, projectId, databaseId, 'messages', headers);
    
    if (messagesData != null) {
      final existingAttributes = <String>{};
      for (var attr in messagesData['attributes']) {
        existingAttributes.add(attr['key']);
      }
      
      print('Existing attributes: $existingAttributes');
      
      // Add missing attributes if they don't exist
      if (!existingAttributes.contains('type')) {
        print('Adding type attribute to Messages collection...');
        await createStringAttribute(endpoint, projectId, databaseId, 'messages', 'type', 50, true, headers, 'text');
        print('✅ Added type attribute');
      } else {
        print('✅ type attribute already exists');
      }
      
      if (!existingAttributes.contains('status')) {
        print('Adding status attribute to Messages collection...');
        await createStringAttribute(endpoint, projectId, databaseId, 'messages', 'status', 50, true, headers, 'sent');
        print('✅ Added status attribute');
      } else {
        print('✅ status attribute already exists');
      }
      
      if (!existingAttributes.contains('isRead')) {
        print('Adding isRead attribute to Messages collection...');
        await createBooleanAttribute(endpoint, projectId, databaseId, 'messages', 'isRead', true, headers, false);
        print('✅ Added isRead attribute');
      } else {
        print('✅ isRead attribute already exists');
      }
    }

    print('\nAll missing attributes added successfully!');
  } catch (e) {
    print('Error adding attributes: $e');
    exit(1);
  }
}

Future<Map<String, dynamic>?> checkCollection(
  String endpoint,
  String projectId,
  String databaseId,
  String collectionId,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  
  try {
    final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId');
    final request = await client.getUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      return jsonDecode(responseBody);
    } else {
      print('Failed to get collection $collectionId: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error checking collection $collectionId: $e');
    return null;
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
  
  try {
    final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/string');
    final request = await client.postUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final body = jsonEncode({
      'key': key,
      'size': size,
      'required': required,
      // Only add default value if the attribute is not required
      if (defaultValue != null && !required) 'default': defaultValue,
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode != 201) {
      final responseBody = await response.transform(utf8.decoder).join();
      throw Exception('Failed to create string attribute: ${response.statusCode} - $responseBody');
    }
  } finally {
    client.close();
  }
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
  
  try {
    final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/datetime');
    final request = await client.postUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final body = jsonEncode({
      'key': key,
      'required': required,
      // Removed default value for required attributes
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode != 201) {
      final responseBody = await response.transform(utf8.decoder).join();
      throw Exception('Failed to create datetime attribute: ${response.statusCode} - $responseBody');
    }
  } finally {
    client.close();
  }
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
  
  try {
    final url = Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/boolean');
    final request = await client.postUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final body = jsonEncode({
      'key': key,
      'required': required,
      // Only add default value if the attribute is not required
      if (!required) 'default': defaultValue,
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode != 201) {
      final responseBody = await response.transform(utf8.decoder).join();
      throw Exception('Failed to create boolean attribute: ${response.statusCode} - $responseBody');
    }
  } finally {
    client.close();
  }
}