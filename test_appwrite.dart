import 'package:appwrite/appwrite.dart';
import 'dart:io';

void main() async {
  // Initialize Appwrite client
  Client client = Client();
  
  client
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setSelfSigned(status: false);

  // Initialize services
  Account account = Account(client);
  
  print('Testing Appwrite connection...');
  
  try {
    // Test connection by getting account (should fail if not logged in, but that's OK)
    await account.get();
    print('✓ Successfully connected to Appwrite');
  } on AppwriteException catch (e) {
    // This is expected if not logged in
    if (e.code == 401) {
      print('✓ Successfully connected to Appwrite (not logged in)');
    } else {
      print('⚠ Appwrite connection issue: ${e.message}');
    }
  } catch (e) {
    print('✗ Failed to connect to Appwrite: $e');
    exit(1);
  }
  
  print('\nAppwrite configuration:');
  print('- Endpoint: https://fra.cloud.appwrite.io/v1');
  print('- Project ID: 68bbb97a003baa58bb9c');
  
  print('\nTo test registration and login:');
  print('1. Run the Flutter app: flutter run -d macos');
  print('2. Navigate to Register screen');
  print('3. Create a new account');
  print('4. Try logging in with the same credentials');
}