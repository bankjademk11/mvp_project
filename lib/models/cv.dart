// เทมเพลต CV Model
enum CVTemplateType {
  modern,
  classic,
  creative,
  professional,
  minimal,
}

class CVTemplate {
  final String id;
  final String name;
  final CVTemplateType type;
  final String description;
  final String thumbnailUrl;
  final bool isPremium;
  final Map<String, dynamic> layout;

  const CVTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.thumbnailUrl,
    this.isPremium = false,
    this.layout = const {},
  });

  factory CVTemplate.fromJson(Map<String, dynamic> json) {
    return CVTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: CVTemplateType.values.firstWhere(
        (e) => e.toString() == 'CVTemplateType.${json['type']}',
        orElse: () => CVTemplateType.modern,
      ),
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      isPremium: json['isPremium'] ?? false,
      layout: json['layout'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      'layout': layout,
    };
  }
}

// ข้อมูล CV Model
class CVData {
  final String id;
  final String userId;
  final String templateId;
  final Map<String, dynamic> personalInfo;
  final List<Map<String, dynamic>> experience;
  final List<Map<String, dynamic>> education;
  final List<String> skills;
  final List<Map<String, dynamic>> certifications;
  final List<Map<String, dynamic>> projects;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CVData({
    required this.id,
    required this.userId,
    required this.templateId,
    this.personalInfo = const {},
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.certifications = const [],
    this.projects = const [],
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CVData.fromJson(Map<String, dynamic> json) {
    return CVData(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      templateId: json['templateId'] ?? '',
      personalInfo: json['personalInfo'] ?? {},
      experience: List<Map<String, dynamic>>.from(json['experience'] ?? []),
      education: List<Map<String, dynamic>>.from(json['education'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      certifications: List<Map<String, dynamic>>.from(json['certifications'] ?? []),
      projects: List<Map<String, dynamic>>.from(json['projects'] ?? []),
      summary: json['summary'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'templateId': templateId,
      'personalInfo': personalInfo,
      'experience': experience,
      'education': education,
      'skills': skills,
      'certifications': certifications,
      'projects': projects,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CVData copyWith({
    String? id,
    String? userId,
    String? templateId,
    Map<String, dynamic>? personalInfo,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? education,
    List<String>? skills,
    List<Map<String, dynamic>>? certifications,
    List<Map<String, dynamic>>? projects,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CVData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      personalInfo: personalInfo ?? this.personalInfo,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// State สำหรับ CV Builder
class CVState {
  final List<CVTemplate> templates;
  final List<CVData> userCVs;
  final CVData? currentCV;
  final bool isLoading;
  final String? error;

  const CVState({
    this.templates = const [],
    this.userCVs = const [],
    this.currentCV,
    this.isLoading = false,
    this.error,
  });

  CVState copyWith({
    List<CVTemplate>? templates,
    List<CVData>? userCVs,
    CVData? currentCV,
    bool? isLoading,
    String? error,
  }) {
    return CVState(
      templates: templates ?? this.templates,
      userCVs: userCVs ?? this.userCVs,
      currentCV: currentCV ?? this.currentCV,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}