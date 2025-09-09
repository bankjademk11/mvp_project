import 'package:appwrite/appwrite.dart';

void main() async {
  Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('68bbb97a003baa58bb9c');

  final databases = Databases(client);
  
  try {
    // List all jobs to see what data is stored
    final response = await databases.listDocuments(
      databaseId: '68bbb9e6003188d8686f',
      collectionId: 'jobs',
    );
    
    print('Total jobs found: ${response.total}');
    
    for (var doc in response.documents) {
      print('Job ID: ${doc.$id}');
      print('Job Data: ${doc.data}');
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
}