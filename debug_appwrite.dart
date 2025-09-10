import 'package:appwrite/appwrite.dart';
import 'dart:convert';

void main() async {
  // Initialize the client
  Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setKey('standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e');

  final databases = Databases(client);
  final storage = Storage(client);
  
  print('=== Appwrite Debug Script ===');
  print('Project ID: 68bbb97a003baa58bb9c');
  print('');
  
  try {
    // 1. Check collection structure
    print('1. Checking collection structure...');
    final collection = await databases.getCollection(
      databaseId: '68bbb9e6003188d8686f',
      collectionId: 'user_profiles',
    );
    
    print('Collection ID: ${collection.$id}');
    print('Collection Name: ${collection.name}');
    print('Attributes:');
    
    // Check if companyLogoUrl attribute exists
    bool hasCompanyLogoUrl = false;
    for (var attr in collection.attributes) {
      print('  - ${attr.key}: ${attr.type}');
      if (attr.key == 'companyLogoUrl') {
        hasCompanyLogoUrl = true;
      }
    }
    
    if (hasCompanyLogoUrl) {
      print('✅ companyLogoUrl attribute exists');
    } else {
      print('❌ companyLogoUrl attribute does not exist');
    }
    
    print('');
    
    // 2. Check specific user document
    print('2. Checking user document for test33@gmail.com...');
    try {
      // First, we need to find the user document
      // Since we don't have the user ID, we'll try to list documents
      final documents = await databases.listDocuments(
        databaseId: '68bbb9e6003188d8686f',
        collectionId: 'user_profiles',
      );
      
      print('Total documents in collection: ${documents.total}');
      
      // Look for the user with email test33@gmail.com
      var targetDocument;
      for (var doc in documents.documents) {
        if (doc.data.containsKey('userId')) {
          print('Document ID: ${doc.$id}, User ID: ${doc.data['userId']}');
          // We'll need to find a way to match with email
        }
      }
      
      // If we can't find by email, let's just check the first few documents
      if (documents.documents.isNotEmpty) {
        print('Showing first document data:');
        final firstDoc = documents.documents[0];
        print('Document ID: ${firstDoc.$id}');
        print('Document data:');
        firstDoc.data.forEach((key, value) {
          print('  $key: $value');
        });
      }
      
    } catch (e) {
      print('Error checking user documents: $e');
    }
    
    print('');
    
    // 3. Check storage buckets
    print('3. Checking storage buckets...');
    try {
      final buckets = await storage.listBuckets();
      print('Total buckets: ${buckets.total}');
      
      for (var bucket in buckets.buckets) {
        print('Bucket ID: ${bucket.$id}, Name: ${bucket.name}');
        
        // List files in this bucket
        try {
          final files = await storage.listFiles(bucketId: bucket.$id);
          print('  Files in bucket: ${files.total}');
          
          // Show first few files
          for (var file in files.files.take(5)) {
            print('    File ID: ${file.$id}, Name: ${file.name}');
          }
        } catch (e) {
          print('  Error listing files: $e');
        }
      }
    } catch (e) {
      print('Error checking storage buckets: $e');
    }
    
    print('');
    print('=== Debug Complete ===');
    
  } catch (e) {
    print('Error: $e');
  }
}