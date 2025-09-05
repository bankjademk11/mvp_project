// ข้อมูลบริษัท Model
class Company {
  final String id;
  final String name;
  final String description;
  final String? logo;
  final String? website;
  final String province;
  final String address;
  final String? phone;
  final String? email;
  final List<String> industry;
  final int employeeCount;
  final DateTime foundedYear;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? socialMedia;
  final List<String> benefits;
  final String? culture;

  const Company({
    required this.id,
    required this.name,
    required this.description,
    this.logo,
    this.website,
    required this.province,
    required this.address,
    this.phone,
    this.email,
    this.industry = const [],
    this.employeeCount = 0,
    required this.foundedYear,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.socialMedia,
    this.benefits = const [],
    this.culture,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'],
      website: json['website'],
      province: json['province'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      email: json['email'],
      industry: List<String>.from(json['industry'] ?? []),
      employeeCount: json['employeeCount'] ?? 0,
      foundedYear: DateTime.parse(json['foundedYear'] ?? DateTime.now().toIso8601String()),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      socialMedia: json['socialMedia'],
      benefits: List<String>.from(json['benefits'] ?? []),
      culture: json['culture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'website': website,
      'province': province,
      'address': address,
      'phone': phone,
      'email': email,
      'industry': industry,
      'employeeCount': employeeCount,
      'foundedYear': foundedYear.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
      'socialMedia': socialMedia,
      'benefits': benefits,
      'culture': culture,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    String? website,
    String? province,
    String? address,
    String? phone,
    String? email,
    List<String>? industry,
    int? employeeCount,
    DateTime? foundedYear,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? socialMedia,
    List<String>? benefits,
    String? culture,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      website: website ?? this.website,
      province: province ?? this.province,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      industry: industry ?? this.industry,
      employeeCount: employeeCount ?? this.employeeCount,
      foundedYear: foundedYear ?? this.foundedYear,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      socialMedia: socialMedia ?? this.socialMedia,
      benefits: benefits ?? this.benefits,
      culture: culture ?? this.culture,
    );
  }
}

// State สำหรับการจัดการข้อมูลบริษัท
class CompanyState {
  final List<Company> companies;
  final Company? selectedCompany;
  final bool isLoading;
  final String? error;

  const CompanyState({
    this.companies = const [],
    this.selectedCompany,
    this.isLoading = false,
    this.error,
  });

  CompanyState copyWith({
    List<Company>? companies,
    Company? selectedCompany,
    bool? isLoading,
    String? error,
  }) {
    return CompanyState(
      companies: companies ?? this.companies,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}