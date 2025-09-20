import 'package:appwrite/appwrite.dart';
import 'dart:io';

// Configuration - Replace with your actual Appwrite endpoint and project ID
const String endpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '66f06501000a66812049';
const String databaseId = '68bbb9e6003188d8686f';
const String userProfilesCollectionId = 'user_profiles';

Future<void> main() async {
  // Initialize Appwrite client
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setSelfSigned(); // Remove this line in production with a valid SSL certificate

  final databases = Databases(client);

  // Ask user for email and password
  stdout.write('Enter your email: ');
  final email = stdin.readLineSync()?.trim();
  stdout.write('Enter your password: ');
  final password = stdin.readLineSync()?.trim();

  if (email == null || password == null || email.isEmpty || password.isEmpty) {
    print('Email and password are required.');
    return;
  }

  try {
    // Create account instance
    final account = Account(client);
    
    // Login user
    await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    
    print('Login successful!');
    
    // Get current user
    final user = await account.get();
    print('Current User ID: ${user.$id}');
    print('Current User Name: ${user.name}');
    print('Current User Email: ${user.email}');
    print('Current User Prefs: ${user.prefs.data}');
    
    // Get user profile document
    try {
      final profileDocument = await databases.getDocument(
        databaseId: databaseId,
        collectionId: userProfilesCollectionId,
        documentId: user.$id,
      );
      
      print('\nUser Profile Document:');
      print('Document ID: ${profileDocument.$id}');
      print('Document Data: ${profileDocument.data}');
      
      // Print specific fields
      print('\nSpecific Profile Fields:');
      print('Display Name: ${profileDocument.data['displayName']}');
      print('Role: ${profileDocument.data['role']}');
      print('Company Name: ${profileDocument.data['companyName']}');
      print('Company Logo URL: ${profileDocument.data['companyLogoUrl']}');
      print('Avatar URL: ${profileDocument.data['avatarUrl']}');
      
    } catch (e) {
      print('Error getting user profile document: $e');
    }
    
    // List all user profile documents (for debugging)
    print('\n\nAll User Profiles (first 5):');
    final allProfiles = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: userProfilesCollectionId,
      queries: [
        Query.limit(5)
      ],
    );
    
    for (var doc in allProfiles.documents) {
      print('---');
      print('Document ID: ${doc.$id}');
      print('Display Name: ${doc.data['displayName']}');
      print('Role: ${doc.data['role']}');
      print('Company Name: ${doc.data['companyName']}');
      print('Company Logo URL: ${doc.data['companyLogoUrl']}');
      print('Avatar URL: ${doc.data['avatarUrl']}');
    }
    
  } on AppwriteException catch (e) {
    print('Appwrite error: ${e.message} (Code: ${e.code})');
  } catch (e) {
    print('Unexpected error: $e');
  }
}