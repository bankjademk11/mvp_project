import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Import this
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> main(final context) async {
  // Access environment variables using Platform.environment
  final String databaseId = Platform.environment['APPWRITE_DATABASE_ID'] ?? '68bbb9e6003188d8686f';
  final String collectionId = Platform.environment['APPWRITE_APPLICATIONS_COLLECTION_ID'] ?? 'applications';
  final String projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID']!;
  final String apiKey = Platform.environment['APPWRITE_API_KEY']!;

  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject(projectId)
      .setKey(apiKey);

  final databases = Databases(client);

  try {
    final payload = jsonDecode(context.req.body);
    context.log('Payload received: $payload');

    final String userId = payload['userId'];
    final String applicantName = payload['applicantName'];
    final String? teamId = payload['teamId'];
    final String jobId = payload['jobId'];
    final String jobTitle = payload['jobTitle'];
    final String companyName = payload['companyName'];
    final String? coverLetter = payload['coverLetter'];
    final String? resumeUrl = payload['resumeUrl'];

    final applicationData = {
      'userId': userId,
      'applicantName': applicantName,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'status': 'pending',
      'appliedAt': DateTime.now().toIso8601String(),
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
    };

    final permissions = [
      Permission.read(Role.user(userId)),
      Permission.update(Role.user(userId)),
      Permission.delete(Role.user(userId)),
    ];

    if (teamId != null && teamId.isNotEmpty) {
      permissions.add(Permission.read(Role.team(teamId)));
      permissions.add(Permission.update(Role.team(teamId)));
    }

    await databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: applicationData,
      permissions: permissions,
    );

    context.log('Successfully created application for user $userId');
    return context.res.json({
      'success': true,
      'message': 'Application submitted successfully.',
    });

  } catch (e) {
    context.error('Error creating application: $e');
    return context.res.json({
      'success': false,
      'message': 'An error occurred: ${e.toString()}',
    }, status: 500);
  }
}
