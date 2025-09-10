import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('=== Appwrite HTTP Debug Script ===');
  
  final projectId = '68bbb97a003baa58bb9c';
  final apiKey = 'standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e';
  final endpoint = 'https://cloud.appwrite.io/v1';
  final databaseId = '68bbb9e6003188d8686f';
  final collectionId = 'user_profiles';
  
  final headers = {
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };
  
  try {
    // 1. Check project info
    print('1. Checking project information...');
    try {
      final projectResponse = await HttpClient().getUrl(Uri.parse('$endpoint/projects/$projectId'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      print('Project response: $projectResponse');
    } catch (e) {
      print('Error checking project: $e');
    }
    
    // 2. Check collection structure
    print('\n2. Checking collection structure...');
    try {
      final collectionResponse = await HttpClient().getUrl(Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      final collectionData = json.decode(collectionResponse);
      print('Collection ID: ${collectionData['\$id']}');
      print('Collection Name: ${collectionData['name']}');
      
      print('Attributes:');
      bool hasCompanyLogoUrl = false;
      for (var attr in collectionData['attributes']) {
        print('  - ${attr['key']}: ${attr['type']}');
        if (attr['key'] == 'companyLogoUrl') {
          hasCompanyLogoUrl = true;
        }
      }
      
      if (hasCompanyLogoUrl) {
        print('✅ companyLogoUrl attribute exists');
      } else {
        print('❌ companyLogoUrl attribute does not exist');
      }
    } catch (e) {
      print('Error checking collection: $e');
    }
    
    // 3. Check user documents
    print('\n3. Checking user documents...');
    try {
      final documentsResponse = await HttpClient().getUrl(Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/documents'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      final documentsData = json.decode(documentsResponse);
      print('Total documents: ${documentsData['total']}');
      
      for (var i = 0; i < documentsData['documents'].length && i < 3; i++) {
        final doc = documentsData['documents'][i];
        print('Document ${i + 1}:');
        print('  ID: ${doc['\$id']}');
        doc.forEach((key, value) {
          if (key != '\$id' && key != '\$collectionId' && key != '\$databaseId') {
            print('    $key: $value');
          }
        });
        print('');
      }
    } catch (e) {
      print('Error listing documents: $e');
    }
    
    // 4. Check storage buckets
    print('\n4. Checking storage buckets...');
    try {
      final bucketsResponse = await HttpClient().getUrl(Uri.parse('$endpoint/storage/buckets'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      final bucketsData = json.decode(bucketsResponse);
      print('Total buckets: ${bucketsData['total']}');
      
      for (var bucket in bucketsData['buckets']) {
        print('Bucket:');
        print('  ID: ${bucket['\$id']}');
        print('  Name: ${bucket['name']}');
      }
    } catch (e) {
      print('Error checking storage: $e');
    }
    
    print('\n=== Debug Complete ===');
    
  } catch (e) {
    print('Unexpected error: $e');
  }
}