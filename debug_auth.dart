import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('=== Authentication Debug Script ===');
  
  final projectId = '68bbb97a003baa58bb9c';
  final apiKey = 'standard_777a7fdaf418c77bbd436431ccbb9d841dd56c1d7595c2e3c3ad8424d6479238afb6f7287df4f29e6bf7d259fecb1c39bb09e35af7c61ba4fbe4b53bf32118a1102ad787cf8a129f42c42ac8c74ccc3d3343729c9298a782f5a2cc7f121bbff0ba08cf8143c04fcae5ee8d70c7dfdf20b782560d33a3678e14e48957e744409e';
  final endpoint = 'https://cloud.appwrite.io/v1';
  
  try {
    // Check current account/session
    print('\n1. Checking current account/session...');
    
    final accountResponse = await HttpClient().getUrl(Uri.parse('$endpoint/account'))
      .then((request) => request..headers.set('X-Appwrite-Project', projectId)
                                 ..headers.set('X-Appwrite-Key', apiKey))
      .then((request) => request.close())
      .then((response) => response.transform(utf8.decoder).join());
    
    final accountData = json.decode(accountResponse);
    print('Account ID: ${accountData['\$id']}');
    print('Account Email: ${accountData['email']}');
    print('Account Name: ${accountData['name']}');
    
    // Check user preferences/role
    print('\n2. Checking user preferences...');
    if (accountData['prefs'] != null) {
      print('Preferences: ${accountData['prefs']}');
      if (accountData['prefs']['role'] != null) {
        print('User Role: ${accountData['prefs']['role']}');
      } else {
        print('No role found in preferences');
      }
    } else {
      print('No preferences found');
    }
    
    print('\n=== Debug Complete ===');
    
  } catch (e) {
    print('Error during debugging: $e');
  }
}