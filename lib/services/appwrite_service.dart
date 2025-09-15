import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppwriteService {
  Client client = Client();
  late Account account;
  late Databases databases;
  late Storage storage;
  late Teams teams;
  late Functions functions; // Add this

  AppwriteService() {
    _init();
  }

  void _init() {
    client
        .setEndpoint('https://cloud.appwrite.io/v1') // Changed to general Appwrite endpoint
        .setProject('68bbb97a003baa58bb9c') // Your Project ID
        .setSelfSigned(status: false); // Set to false for production/cloud environments

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    teams = Teams(client);
    functions = Functions(client); // Add this
  }
}

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});