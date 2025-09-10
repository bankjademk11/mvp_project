import 'package:appwrite/appwrite.dart';
import 'dart:io';

void main() async {
  print('=== Appwrite Direct Debug Script ===');
  
  // Initialize the client with your credentials
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setKey('standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e');

  final databases = Databases(client);
  final users = Users(client);
  final storage = Storage(client);
  
  try {
    print('1. Checking project information...');
    // Note: We can't directly get project info with server key, but we can test connectivity
    
    // 2. Check database and collection structure
    print('\n2. Checking database structure...');
    try {
      final collection = await databases.getCollection(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'user_profiles',
      );
      
      print('Collection found:');
      print('  ID: ${collection.$id}');
      print('  Name: ${collection.name}');
      print('  Attributes:');
      
      bool hasCompanyLogoUrl = false;
      for (var attr in collection.attributes) {
        print('    - ${attr.key}: ${attr.type}');
        if (attr.key == 'companyLogoUrl') {
          hasCompanyLogoUrl = true;
        }
      }
      
      if (hasCompanyLogoUrl) {
        print('  ✅ companyLogoUrl attribute exists');
      } else {
        print('  ❌ companyLogoUrl attribute does not exist');
      }
    } catch (e) {
      print('Error checking collection: $e');
    }
    
    // 3. Check user documents
    print('\n3. Checking user documents...');
    try {
      final documents = await databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'user_profiles',
      );
      
      print('Total documents: ${documents.total}');
      
      for (var i = 0; i < documents.documents.length && i < 5; i++) {
        final doc = documents.documents[i];
        print('Document ${i + 1}:');
        print('  ID: ${doc.$id}');
        doc.data.forEach((key, value) {
          print('    $key: $value');
        });
        print('');
      }
    } catch (e) {
      print('Error listing documents: $e');
    }
    
    // 4. Check storage buckets
    print('\n4. Checking storage buckets...');
    try {
      final buckets = await storage.listBuckets();
      print('Total buckets: ${buckets.total}');
      
      for (var bucket in buckets.buckets) {
        print('Bucket:');
        print('  ID: ${bucket.$id}');
        print('  Name: ${bucket.name}');
        
        // List files in this bucket
        try {
          final files = await storage.listFiles(bucketId: bucket.$id);
          print('  Files: ${files.total}');
          
          for (var file in files.files.take(3)) {
            print('    File ID: ${file.$id}, Name: ${file.name}');
          }
        } catch (e) {
          print('  Error listing files: $e');
        }
        print('');
      }
    } catch (e) {
      print('Error checking storage: $e');
    }
    
    print('\n=== Debug Complete ===');
    
  } catch (e) {
    print('Unexpected error: $e');
    if (e is AppwriteException) {
      print('Appwrite error details:');
      print('  Message: ${e.message}');
      print('  Code: ${e.code}');
      print('  Type: ${e.type}');
    }
  }
}