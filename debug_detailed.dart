import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('=== Detailed Appwrite Debug Script ===');
  
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
    // Check for documents with companyLogoUrl
    print('Checking for documents with companyLogoUrl...');
    try {
      final documentsResponse = await HttpClient().getUrl(Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/documents'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      final documentsData = json.decode(documentsResponse);
      print('Total documents: ${documentsData['total']}');
      
      int documentsWithLogo = 0;
      for (var doc in documentsData['documents']) {
        if (doc['companyLogoUrl'] != null && doc['companyLogoUrl'].toString().isNotEmpty && doc['companyLogoUrl'] != 'null') {
          documentsWithLogo++;
          print('Document with company logo:');
          print('  ID: ${doc['\$id']}');
          print('  User ID: ${doc['userId']}');
          print('  Company Logo URL: ${doc['companyLogoUrl']}');
          print('  Company Name: ${doc['companyName']}');
          print('');
        }
      }
      
      print('Found $documentsWithLogo documents with company logos');
      
      if (documentsWithLogo == 0) {
        print('No documents found with company logos. This explains why the data disappears after logout.');
      }
      
    } catch (e) {
      print('Error checking documents: $e');
    }
    
    // Check storage files
    print('\nChecking storage files in company_logos bucket...');
    try {
      final filesResponse = await HttpClient().getUrl(Uri.parse('$endpoint/storage/buckets/company_logos/files'))
        .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                   ..headers.set('X-Appwrite-Key', apiKey))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join());
      
      final filesData = json.decode(filesResponse);
      print('Total files in company_logos bucket: ${filesData['total']}');
      
      for (var i = 0; i < filesData['files'].length && i < 5; i++) {
        final file = filesData['files'][i];
        print('File ${i + 1}:');
        print('  ID: ${file['\$id']}');
        print('  Name: ${file['name']}');
        print('  Created: ${file['\$createdAt']}');
        print('');
      }
      
    } catch (e) {
      print('Error checking storage files: $e');
    }
    
    print('\n=== Detailed Debug Complete ===');
    
  } catch (e) {
    print('Unexpected error: $e');
  }
}