import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MockApi {
  static Future<List<dynamic>> loadJobs() async {
    final raw = await rootBundle.loadString('assets/mock_jobs.json');
    return jsonDecode(raw) as List<dynamic>;
    }

  static Future<Map<String, dynamic>> loadChats() async {
    final raw = await rootBundle.loadString('assets/mock_chats.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> loadProfile() async {
    final raw = await rootBundle.loadString('assets/mock_profile.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // Mock data for new features
  static Future<List<dynamic>> loadBookmarks() async {
    // Return mock bookmark data
    return [];
  }

  static Future<List<dynamic>> loadNotifications() async {
    // Return mock notification data
    return [];
  }

  static Future<List<dynamic>> loadCompanies() async {
    // Return mock company data
    return [];
  }

  static Future<List<dynamic>> loadReviews() async {
    // Return mock review data
    return [];
  }

  static Future<List<dynamic>> loadCVTemplates() async {
    // Return mock CV template data
    return [];
  }

  static Future<List<dynamic>> loadInterviews() async {
    // Return mock interview data
    return [];
  }
}
