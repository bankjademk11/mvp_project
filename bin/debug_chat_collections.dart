import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Debugging chat collections in Appwrite using HTTP API...');

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
    // Check chats collection
    print('\n1. Checking Chats collection...');
    final chatsResponse = await checkCollection(endpoint, projectId, databaseId, 'chats', headers);
    
    if (chatsResponse.statusCode == 200) {
      final responseBody = await chatsResponse.transform(utf8.decoder).join();
      final chatsData = jsonDecode(responseBody);
      print('✅ Chats collection found: ${chatsData['name']} (ID: ${chatsData['\$id']})');
      
      print('   Attributes:');
      for (var attr in chatsData['attributes']) {
        print('   - ${attr['key']}: ${attr['type']} (required: ${attr['required']})');
      }
    } else {
      print('❌ Failed to get Chats collection: ${chatsResponse.statusCode}');
    }

    // Check messages collection
    print('\n2. Checking Messages collection...');
    final messagesResponse = await checkCollection(endpoint, projectId, databaseId, 'messages', headers);
    
    if (messagesResponse.statusCode == 200) {
      final responseBody = await messagesResponse.transform(utf8.decoder).join();
      final messagesData = jsonDecode(responseBody);
      print('✅ Messages collection found: ${messagesData['name']} (ID: ${messagesData['\$id']})');
      
      print('   Attributes:');
      for (var attr in messagesData['attributes']) {
        print('   - ${attr['key']}: ${attr['type']} (required: ${attr['required']})');
      }
    } else {
      print('❌ Failed to get Messages collection: ${messagesResponse.statusCode}');
    }

    print('\nDebug completed!');
  } catch (e) {
    print('Error during debug: $e');
    exit(1);
  }
}

Future<HttpClientResponse> checkCollection(
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
    
    return await request.close();
  } catch (e) {
    rethrow;
  }
}