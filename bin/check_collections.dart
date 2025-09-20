import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

void main() async {
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setKey('standard_040b0edb3383d6fc688f3383ffb86e95f5de797dc14c914eb0696d8cc962bf4f45bda934b83e64e32c8b54cd408fe707a98b9e32fc927af03089e157457a502a9d3717a7141d950dcf6a007a10e3f1052044ea00f038b0309eecd9a8ca08c6b24f066e05361be51ba8c34a9522359ad7d56b34f1fd6d789972530333aa8c5647');

  final databases = Databases(client);

  print('Checking Appwrite collections...');

  try {
    print('\n1. Checking if "chats" collection exists...');
    final chatsCollection = await databases.getCollection(
      databaseId: '68bbb9e6003188d8686f',
      collectionId: 'chats',
    );
    print('✅ Chats collection found: ${chatsCollection.name} (ID: ${chatsCollection.$id})');
    
    // Print collection details
    print('   Attributes:');
    for (var attr in chatsCollection.attributes) {
      print('   - ${attr.key}: ${attr.type}');
    }
  } catch (e) {
    print('❌ Chats collection not found: $e');
  }

  try {
    print('\n2. Checking if "messages" collection exists...');
    final messagesCollection = await databases.getCollection(
      databaseId: '68bbb9e6003188d8686f',
      collectionId: 'messages',
    );
    print('✅ Messages collection found: ${messagesCollection.name} (ID: ${messagesCollection.$id})');
    
    // Print collection details
    print('   Attributes:');
    for (var attr in messagesCollection.attributes) {
      print('   - ${attr.key}: ${attr.type}');
    }
  } catch (e) {
    print('❌ Messages collection not found: $e');
  }

  try {
    print('\n3. Listing all collections in database...');
    final collections = await databases.listCollections(
      databaseId: '68bbb9e6003188d8686f',
    );
    print('Found ${collections.total} collections:');
    for (var collection in collections.collections) {
      print('- ${collection.$id}: ${collection.name}');
    }
  } catch (e) {
    print('Error listing collections: $e');
  }
}