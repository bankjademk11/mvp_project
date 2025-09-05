import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cv.dart';
import 'mock_api.dart';

// Provider สำหรับ CV Service
final cvServiceProvider = StateNotifierProvider<CVService, CVState>((ref) {
  return CVService();
});

class CVService extends StateNotifier<CVState> {
  CVService() : super(const CVState()) {
    loadTemplatesAndCVs();
  }

  // โหลดเทมเพลตและ CV ทั้งหมด
  Future<void> loadTemplatesAndCVs() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock Templates
      final mockTemplates = [
        CVTemplate(
          id: 'template_001',
          name: 'Modern Professional',
          type: CVTemplateType.modern,
          description: 'เทมเพลตสมัยใหม่สำหรับมืออาชีพ',
          thumbnailUrl: 'https://example.com/template1.jpg',
          layout: {
            'headerColor': '#2196F3',
            'fontFamily': 'Roboto',
            'sections': ['header', 'summary', 'experience', 'education', 'skills'],
          },
        ),
        CVTemplate(
          id: 'template_002',
          name: 'Classic Elegant',
          type: CVTemplateType.classic,
          description: 'เทมเพลตคลาสสิคที่สง่างาม',
          thumbnailUrl: 'https://example.com/template2.jpg',
          layout: {
            'headerColor': '#424242',
            'fontFamily': 'Times New Roman',
            'sections': ['header', 'objective', 'experience', 'education', 'skills'],
          },
        ),
        CVTemplate(
          id: 'template_003',
          name: 'Creative Design',
          type: CVTemplateType.creative,
          description: 'เทมเพลตสร้างสรรค์สำหรับงานดีไซน์',
          thumbnailUrl: 'https://example.com/template3.jpg',
          isPremium: true,
          layout: {
            'headerColor': '#FF5722',
            'fontFamily': 'Montserrat',
            'sections': ['header', 'portfolio', 'experience', 'skills', 'education'],
          },
        ),
      ];

      // Mock User CVs
      final mockUserCVs = [
        CVData(
          id: 'cv_001',
          userId: 'user_001',
          templateId: 'template_001',
          personalInfo: {
            'fullName': 'นายสมชาย ใจดี',
            'email': 'somchai@email.com',
            'phone': '+856 20 1234567',
            'address': 'Vientiane Capital, Laos',
            'linkedIn': 'linkedin.com/in/somchai',
          },
          experience: [
            {
              'position': 'Senior Flutter Developer',
              'company': 'NX Creations',
              'startDate': '2022-01-01',
              'endDate': null,
              'description': 'พัฒนาแอปพลิเคชันมือถือด้วย Flutter',
              'achievements': [
                'พัฒนาแอป MVP Package',
                'ปรับปรุงประสิทธิภาพแอปได้ 30%',
              ],
            },
            {
              'position': 'Mobile Developer',
              'company': 'Tech Solutions',
              'startDate': '2020-06-01',
              'endDate': '2021-12-31',
              'description': 'พัฒนาแอปพลิเคชันมือถือ',
            },
          ],
          education: [
            {
              'degree': 'ปริญญาตรี วิทยาการคอมพิวเตอร์',
              'institution': 'National University of Laos',
              'startDate': '2016-08-01',
              'endDate': '2020-05-31',
              'gpa': '3.45',
            },
          ],
          skills: [
            'Flutter',
            'Dart',
            'Firebase',
            'REST APIs',
            'Git',
            'Mobile UI/UX',
          ],
          summary: 'นักพัฒนาแอปพลิเคชันมือถือที่มีประสบการณ์ 3+ ปี เชี่ยวชาญ Flutter และ Dart',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      
      state = state.copyWith(
        templates: mockTemplates,
        userCVs: mockUserCVs,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // สร้าง CV ใหม่
  Future<void> createCV(String templateId) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // TODO: เรียก API สร้าง CV
      await Future.delayed(const Duration(milliseconds: 500));

      final newCV = CVData(
        id: 'cv_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_001', // TODO: ใช้ user ID จริง
        templateId: templateId,
        personalInfo: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedCVs = [...state.userCVs, newCV];
      state = state.copyWith(
        userCVs: updatedCVs,
        currentCV: newCV,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // อัพเดตข้อมูล CV
  Future<void> updateCV(CVData updatedCV) async {
    try {
      // TODO: เรียก API อัพเดต CV
      await Future.delayed(const Duration(milliseconds: 300));

      final updated = updatedCV.copyWith(updatedAt: DateTime.now());
      
      final updatedCVs = state.userCVs.map((cv) {
        return cv.id == updated.id ? updated : cv;
      }).toList();

      state = state.copyWith(
        userCVs: updatedCVs,
        currentCV: state.currentCV?.id == updated.id ? updated : state.currentCV,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ลบ CV
  Future<void> deleteCV(String cvId) async {
    try {
      // TODO: เรียก API ลบ CV
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedCVs = state.userCVs.where((cv) => cv.id != cvId).toList();
      
      state = state.copyWith(
        userCVs: updatedCVs,
        currentCV: state.currentCV?.id == cvId ? null : state.currentCV,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // โหลด CV เฉพาะ
  Future<void> loadCV(String cvId) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // TODO: เรียก API โหลด CV
      await Future.delayed(const Duration(milliseconds: 300));

      final cv = state.userCVs.firstWhere(
        (cv) => cv.id == cvId,
        orElse: () => throw Exception('CV not found'),
      );

      state = state.copyWith(
        currentCV: cv,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // ทำสำเนา CV
  Future<void> duplicateCV(String cvId) async {
    try {
      final originalCV = state.userCVs.firstWhere(
        (cv) => cv.id == cvId,
        orElse: () => throw Exception('CV not found'),
      );

      final duplicatedCV = originalCV.copyWith(
        id: 'cv_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: เรียก API สร้าง CV
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedCVs = [...state.userCVs, duplicatedCV];
      state = state.copyWith(userCVs: updatedCVs);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ส่งออก CV เป็น PDF
  Future<String> exportToPDF(String cvId) async {
    try {
      // TODO: เรียก API ส่งออก PDF
      await Future.delayed(const Duration(seconds: 2));
      
      // ส่งคืน URL ของ PDF ที่สร้างแล้ว
      return 'https://example.com/cv_exports/cv_$cvId.pdf';
    } catch (error) {
      throw Exception('ไม่สามารถส่งออก PDF ได้: $error');
    }
  }

  // ส่งออก CV เป็น Word
  Future<String> exportToWord(String cvId) async {
    try {
      // TODO: เรียก API ส่งออก Word
      await Future.delayed(const Duration(seconds: 2));
      
      return 'https://example.com/cv_exports/cv_$cvId.docx';
    } catch (error) {
      throw Exception('ไม่สามารถส่งออก Word ได้: $error');
    }
  }

  // อัพเดตข้อมูลส่วนตัว
  Future<void> updatePersonalInfo(Map<String, dynamic> personalInfo) async {
    if (state.currentCV == null) return;
    
    final updatedCV = state.currentCV!.copyWith(
      personalInfo: personalInfo,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // เพิ่มประสบการณ์ทำงาน
  Future<void> addExperience(Map<String, dynamic> experience) async {
    if (state.currentCV == null) return;
    
    final updatedExperience = [...state.currentCV!.experience, experience];
    final updatedCV = state.currentCV!.copyWith(
      experience: updatedExperience,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // อัพเดตประสบการณ์ทำงาน
  Future<void> updateExperience(int index, Map<String, dynamic> experience) async {
    if (state.currentCV == null) return;
    
    final updatedExperience = [...state.currentCV!.experience];
    updatedExperience[index] = experience;
    
    final updatedCV = state.currentCV!.copyWith(
      experience: updatedExperience,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // ลบประสบการณ์ทำงาน
  Future<void> removeExperience(int index) async {
    if (state.currentCV == null) return;
    
    final updatedExperience = [...state.currentCV!.experience];
    updatedExperience.removeAt(index);
    
    final updatedCV = state.currentCV!.copyWith(
      experience: updatedExperience,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // เพิ่มการศึกษา
  Future<void> addEducation(Map<String, dynamic> education) async {
    if (state.currentCV == null) return;
    
    final updatedEducation = [...state.currentCV!.education, education];
    final updatedCV = state.currentCV!.copyWith(
      education: updatedEducation,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // อัพเดตทักษะ
  Future<void> updateSkills(List<String> skills) async {
    if (state.currentCV == null) return;
    
    final updatedCV = state.currentCV!.copyWith(
      skills: skills,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // อัพเดตสรุปข้อมูล
  Future<void> updateSummary(String summary) async {
    if (state.currentCV == null) return;
    
    final updatedCV = state.currentCV!.copyWith(
      summary: summary,
      updatedAt: DateTime.now(),
    );
    
    await updateCV(updatedCV);
  }

  // ล้างข้อมูล CV ปัจจุบัน
  void clearCurrentCV() {
    state = state.copyWith(currentCV: null);
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadTemplatesAndCVs();
  }

  // รับเทมเพลตฟรี
  List<CVTemplate> getFreeTemplates() {
    return state.templates.where((template) => !template.isPremium).toList();
  }

  // รับเทมเพลตพรีเมียม
  List<CVTemplate> getPremiumTemplates() {
    return state.templates.where((template) => template.isPremium).toList();
  }
}