import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        .setEndpoint('https://cloud.appwrite.io/v1') // Changed to general Appwrite endpoint
        .setProject('68bbb97a003baa58bb9c') // Your Project ID
        .setSelfSigned(status: false); // Set to false for production/cloud environments

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
}

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});