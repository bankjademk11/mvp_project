import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Adding verification attributes to user_profiles collection in Appwrite...');

  final projectId = '68bbb97a003baa58bb9c';
  final apiKey = 'standard_040b0edb3383d6fc688f3383ffb86e95f5de797dc14c914eb0696d8cc962bf4f45bda934b83e64e32c8b54cd408fe707a98b9e32fc927af03089e157457a502a9d3717a7141d950dcf6a007a10e3f1052044ea00f038b0309eecd9a8ca08c6b24f066e05361be51ba8c34a9522359ad7d56b34f1fd6d789972530333aa8c5647';
  final databaseId = '68bbb9e6003188d8686f';
  final endpoint = 'https://fra.cloud.appwrite.io/v1';
  final collectionId = 'user_profiles';

  final headers = {
    'X-Appwrite-Response-Format': '1.0.0',
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };

  try {
    print('\n1. Checking current User Profiles collection attributes...');
    final collectionData = await checkCollection(endpoint, projectId, databaseId, collectionId, headers);
    
    if (collectionData != null) {
      final existingAttributes = <String>{};
      for (var attr in collectionData['attributes']) {
        existingAttributes.add(attr['key']);
      }
      
      print('Existing attributes: $existingAttributes');
      
      // Add idCardUrl
      if (!existingAttributes.contains('idCardUrl')) {
        print('Adding idCardUrl attribute...');
        await createStringAttribute(endpoint, projectId, databaseId, collectionId, 'idCardUrl', 2048, false, headers);
        print('✅ Added idCardUrl attribute');
      } else {
        print('✅ idCardUrl attribute already exists');
      }
      
      // Add selfieWithIdUrl
      if (!existingAttributes.contains('selfieWithIdUrl')) {
        print('Adding selfieWithIdUrl attribute...');
        await createStringAttribute(endpoint, projectId, databaseId, collectionId, 'selfieWithIdUrl', 2048, false, headers);
        print('✅ Added selfieWithIdUrl attribute');
      } else {
        print('✅ selfieWithIdUrl attribute already exists');
      }

      // Add verificationStatus
      if (!existingAttributes.contains('verificationStatus')) {
        print('Adding verificationStatus attribute...');
        await createStringAttribute(endpoint, projectId, databaseId, collectionId, 'verificationStatus', 50, false, headers, 'unverified');
        print('✅ Added verificationStatus attribute');
      } else {
        print('✅ verificationStatus attribute already exists');
      }

      // Add verificationPinHash
      if (!existingAttributes.contains('verificationPinHash')) {
        print('Adding verificationPinHash attribute...');
        await createStringAttribute(endpoint, projectId, databaseId, collectionId, 'verificationPinHash', 256, false, headers);
        print('✅ Added verificationPinHash attribute');
      } else {
        print('✅ verificationPinHash attribute already exists');
      }
    }

    print('\nAll verification attributes processed successfully!');
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
      final responseBody = await response.transform(utf8.decoder).join();
      print('Response body: $responseBody');
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
    
    final body = <String, dynamic>{
      'key': key,
      'size': size,
      'required': required,
    };

    if (defaultValue != null) {
      body['default'] = defaultValue;
    }
    
    request.write(jsonEncode(body));
    final response = await request.close();
    
    if (response.statusCode != 202) { // Appwrite returns 202 for attribute creation
      final responseBody = await response.transform(utf8.decoder).join();
      // It might be a 409 conflict if it already exists, which is fine.
      if (response.statusCode != 409) {
        throw Exception('Failed to create string attribute: ${response.statusCode} - $responseBody');
      }
    }
  } finally {
    client.close();
  }
}
