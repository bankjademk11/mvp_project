import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import 'mock_api.dart';

// Provider สำหรับ Company Service
final companyServiceProvider = StateNotifierProvider<CompanyService, CompanyState>((ref) {
  return CompanyService();
});

class CompanyService extends StateNotifier<CompanyState> {
  CompanyService() : super(const CompanyState()) {
    loadCompanies();
  }

  // โหลดข้อมูลบริษัททั้งหมด
  Future<void> loadCompanies() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockCompanies = [
        Company(
          id: 'company_001',
          name: 'ODG Mall Co., Ltd.',
          description: 'บริษัทค้าปลีกชั้นนำของลาว ดำเนินธุรกิจห้างสรรพสินค้าและการขายออนไลน์',
          logo: 'https://example.com/odg-logo.png',
          website: 'https://odgmall.com',
          province: 'Vientiane Capital',
          address: '123 Setthathirath Road, Vientiane',
          phone: '+856 21 123456',
          email: 'hr@odgmall.com',
          industry: ['Retail', 'E-commerce'],
          employeeCount: 150,
          foundedYear: DateTime(2010),
          rating: 4.2,
          reviewCount: 28,
          benefits: [
            'ประกันสุขภาพ',
            'โบนัสประจำปี',
            'วันหยุดพักผ่อน',
            'ฝึกอบรมพัฒนาทักษะ',
          ],
          culture: 'บริษัทที่เน้นการทำงานเป็นทีม มีโอกาสเติบโตในอาชีพ',
        ),
        Company(
          id: 'company_002',
          name: 'NX Creations',
          description: 'บริษัทพัฒนาซอฟต์แวร์และแอปพลิเคชันมือถือ เชี่ยวชาญด้าน Flutter และ Mobile Development',
          logo: 'https://example.com/nx-logo.png',
          website: 'https://nxcreations.la',
          province: 'Vientiane Capital',
          address: '456 That Luang Road, Vientiane',
          phone: '+856 21 654321',
          email: 'careers@nxcreations.la',
          industry: ['Technology', 'Software Development'],
          employeeCount: 45,
          foundedYear: DateTime(2018),
          rating: 4.5,
          reviewCount: 15,
          benefits: [
            'ทำงานแบบ Flexible',
            'อุปกรณ์คอมพิวเตอร์ครบ',
            'การฝึกอบรมเทคโนโลยีใหม่',
            'ประกันสุขภาพ',
          ],
          culture: 'สภาพแวดล้อมการทำงานที่ทันสมัย เน้นนวัตกรรมและความคิดสร้างสรรค์',
        ),
        Company(
          id: 'company_003',
          name: 'Odien Group',
          description: 'กลุ่มบริษัทด้านโลจิสติกส์และคลังสินค้า ให้บริการขนส่งและจัดการสินค้าทั่วลาว',
          province: 'Savannakhet',
          address: '789 Route 13 South, Savannakhet',
          phone: '+856 41 987654',
          email: 'info@odiengroup.com',
          industry: ['Logistics', 'Warehousing'],
          employeeCount: 200,
          foundedYear: DateTime(2005),
          rating: 3.8,
          reviewCount: 42,
          benefits: [
            'โบนัสตามผลงาน',
            'ประกันสุขภาพ',
            'เบี้ยขยัน',
            'ฝึกอบรมพัฒนาทักษะ',
          ],
          culture: 'องค์กรที่มีวินัยและความปลอดภัยในการทำงานเป็นสำคัญ',
        ),
      ];
      
      state = state.copyWith(
        companies: mockCompanies,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // โหลดข้อมูลบริษัทตาม ID
  Future<void> loadCompanyById(String companyId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 300));
      
      final company = state.companies.firstWhere(
        (c) => c.id == companyId,
        orElse: () => throw Exception('Company not found'),
      );
      
      state = state.copyWith(
        selectedCompany: company,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // ค้นหาบริษัท
  List<Company> searchCompanies(String query) {
    if (query.isEmpty) return state.companies;
    
    final lowerQuery = query.toLowerCase();
    return state.companies.where((company) {
      return company.name.toLowerCase().contains(lowerQuery) ||
             company.description.toLowerCase().contains(lowerQuery) ||
             company.industry.any((industry) => industry.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // กรองบริษัทตามจังหวัด
  List<Company> getCompaniesByProvince(String province) {
    return state.companies.where((company) => company.province == province).toList();
  }

  // กรองบริษัทตามอุตสาหกรรม
  List<Company> getCompaniesByIndustry(String industry) {
    return state.companies.where((company) => company.industry.contains(industry)).toList();
  }

  // รับบริษัทยอดนิยม (เรียงตาม rating)
  List<Company> getTopRatedCompanies({int limit = 10}) {
    final sorted = [...state.companies];
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }

  // รับบริษัทขนาดใหญ่ (เรียงตามจำนวนพนักงาน)
  List<Company> getLargestCompanies({int limit = 10}) {
    final sorted = [...state.companies];
    sorted.sort((a, b) => b.employeeCount.compareTo(a.employeeCount));
    return sorted.take(limit).toList();
  }

  // อัพเดตข้อมูลบริษัท
  Future<void> updateCompany(Company updatedCompany) async {
    try {
      // TODO: เรียก API อัพเดตข้อมูล
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedCompanies = state.companies.map((company) {
        return company.id == updatedCompany.id ? updatedCompany : company;
      }).toList();

      state = state.copyWith(
        companies: updatedCompanies,
        selectedCompany: state.selectedCompany?.id == updatedCompany.id 
            ? updatedCompany 
            : state.selectedCompany,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ล้างข้อมูลบริษัทที่เลือก
  void clearSelectedCompany() {
    state = state.copyWith(selectedCompany: null);
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadCompanies();
  }

  // รับสถิติบริษัท
  Map<String, dynamic> getCompanyStatistics() {
    final total = state.companies.length;
    final provinces = state.companies.map((c) => c.province).toSet().length;
    final industries = state.companies.expand((c) => c.industry).toSet().length;
    final averageRating = state.companies.isEmpty 
        ? 0.0 
        : state.companies.map((c) => c.rating).reduce((a, b) => a + b) / state.companies.length;
    
    return {
      'totalCompanies': total,
      'totalProvinces': provinces,
      'totalIndustries': industries,
      'averageRating': averageRating,
    };
  }
}