import 'package:appwrite/appwrite.dart';

class AppwriteService {
  Client client = Client();
  late Account account;
  late Databases databases;
  late Storage storage;

  AppwriteService() {
    _init();
  }

  void _init() {
    client
        .setEndpoint('https://fra.cloud.appwrite.io/v1') // Your Appwrite Endpoint
        .setProject('68bbb97a003baa58bb9c') // Your Project ID
        .setSelfSigned(status: false); // Set to false for production/cloud environments

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
}

// You can create a Riverpod provider for this service later
// final appwriteServiceProvider = Provider((ref) => AppwriteService());
