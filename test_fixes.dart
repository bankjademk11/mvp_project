import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('=== Testing Fixes ===');
  
  final projectId = '68bbb97a003baa58bb9c';
  final apiKey = 'standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e';
  final endpoint = 'https://cloud.appwrite.io/v1';
  final databaseId = '68bbb9e6003188d8686f';
  final collectionId = 'user_profiles';
  
  try {
    // Test 1: Check if we can retrieve a specific document with companyLogoUrl
    print('\n1. Testing document retrieval...');
    
    // We know from our earlier debug that document ID 68bfe5b6e38a0451388c has a companyLogoUrl
    final documentId = '68bfe5b6e38a0451388c';
    
    final documentResponse = await HttpClient().getUrl(Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/documents/$documentId'))
      .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                 ..headers.set('X-Appwrite-Key', apiKey))
      .then((request) => request.close())
      .then((response) => response.transform(utf8.decoder).join());
    
    final documentData = json.decode(documentResponse);
    print('Document ID: ${documentData['\$id']}');
    print('Company Name: ${documentData['companyName']}');
    print('Company Logo URL: ${documentData['companyLogoUrl']}');
    
    if (documentData['companyLogoUrl'] != null && documentData['companyLogoUrl'].toString().isNotEmpty) {
      print('✅ Document has companyLogoUrl - data persistence is working');
    } else {
      print('❌ Document does not have companyLogoUrl - data persistence issue');
    }
    
    // Test 2: Check if we can access the file in storage
    print('\n2. Testing file access...');
    
    if (documentData['companyLogoUrl'] != null) {
      try {
        final fileUrl = documentData['companyLogoUrl'];
        print('Testing access to file: $fileUrl');
        
        // Just check if we can make a HEAD request to the file URL
        final fileResponse = await HttpClient().headUrl(Uri.parse(fileUrl))
          .then((request) => request.close());
        
        if (fileResponse.statusCode == 200) {
          print('✅ File is accessible');
        } else {
          print('❌ File is not accessible. Status code: ${fileResponse.statusCode}');
        }
      } catch (e) {
        print('❌ Error accessing file: $e');
      }
    }
    
    print('\n=== Test Complete ===');
    
  } catch (e) {
    print('Error during testing: $e');
  }
}