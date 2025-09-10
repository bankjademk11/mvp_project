import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

void main() async {
  // Initialize Appwrite client
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setSelfSigned(status: false);

  // Initialize services
  final account = Account(client);
  final databases = Databases(client);
  
  print('Testing Appwrite connection...');
  
  try {
    // Test getting current user (this will fail if not logged in, but connection should work)
    final user = await account.get();
    print('Current user: ${user.email}');
  } on AppwriteException catch (e) {
    print('AppwriteException: ${e.message}, Code: ${e.code}');
    // This is expected if not logged in
  } catch (e) {
    print('Error: $e');
  }
  
  try {
    // Test listing databases
    final dbList = await databases.list();
    print('Found ${dbList.total} databases');
  } on AppwriteException catch (e) {
    print('AppwriteException when listing databases: ${e.message}, Code: ${e.code}');
  } catch (e) {
    print('Error when listing databases: $e');
  }
}