import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Adding createdAt attribute to Messages collection...');

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
    final client = HttpClient();
    
    // Add createdAt attribute to Messages collection
    print('Adding createdAt attribute to Messages collection...');
    final url = Uri.parse('$endpoint/databases/$databaseId/collections/messages/attributes/datetime');
    
    final request = await client.postUrl(url);
    headers.forEach((key, value) => request.headers.set(key, value));
    
    final body = jsonEncode({
      'key': 'createdAt',
      'required': true,
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode == 201) {
      print('✅ Added createdAt attribute to Messages collection');
    } else {
      final responseBody = await response.transform(utf8.decoder).join();
      print('❌ Failed to add createdAt attribute: ${response.statusCode} - $responseBody');
    }
    
    client.close();
    print('\nProcess completed!');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}