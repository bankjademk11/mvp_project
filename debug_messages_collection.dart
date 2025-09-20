
import 'package:appwrite/appwrite.dart';

void main() async {
  // Initialize the client
  Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c')
      .setKey('standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e');

  final databases = Databases(client);
  
  try {
    print('--- Checking "messages" collection schema ---');
    // Get the collection
    final collection = await databases.getCollection(
      databaseId: '68bbb9e6003188d8686f', // mvpDB
      collectionId: 'messages',
    );
    
    print('Collection ID: ${collection.$id}');
    print('Collection Name: ${collection.name}');
    print('Attributes:');
    
    bool hasCreatedAt = false;
    // Print all attributes
    for (var attr in collection.attributes) {
      if(attr.key == 'createdAt'){
        hasCreatedAt = true;
        print('  - ${attr.key}: ${attr.type} (Required: ${attr.isRequired})');
      } else {
        print('  - ${attr.key}: ${attr.type} (Required: ${attr.isRequired})');
      }
    }

    if (hasCreatedAt) {
      print('
✅ "createdAt" attribute exists.');
    } else {
      print('
❌ "createdAt" attribute DOES NOT exist.');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
