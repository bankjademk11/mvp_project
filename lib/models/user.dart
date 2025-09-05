class User {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'seeker' or 'employer'
  final String? phone;
  final String? province;
  final List<String> skills;
  final String? bio;
  final String? resumeUrl;
  final String? avatarUrl;
  
  // ข้อมูลสำหรับนายจ้าง
  final String? companyName;
  final String? companySize;
  final String? industry;
  final String? companyDescription;
  final String? website;
  final String? companyAddress;

  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone,
    this.province,
    this.skills = const [],
    this.bio,
    this.resumeUrl,
    this.avatarUrl,
    // ข้อมูลบริษัท
    this.companyName,
    this.companySize,
    this.industry,
    this.companyDescription,
    this.website,
    this.companyAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? 'seeker',
      phone: json['phone'],
      province: json['province'],
      skills: List<String>.from(json['skills'] ?? []),
      bio: json['bio'],
      resumeUrl: json['resumeUrl'],
      avatarUrl: json['avatarUrl'],
      // ข้อมูลบริษัท
      companyName: json['companyName'],
      companySize: json['companySize'],
      industry: json['industry'],
      companyDescription: json['companyDescription'],
      website: json['website'],
      companyAddress: json['companyAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'phone': phone,
      'province': province,
      'skills': skills,
      'bio': bio,
      'resumeUrl': resumeUrl,
      'avatarUrl': avatarUrl,
      // ข้อมูลบริษัท
      'companyName': companyName,
      'companySize': companySize,
      'industry': industry,
      'companyDescription': companyDescription,
      'website': website,
      'companyAddress': companyAddress,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? phone,
    String? province,
    List<String>? skills,
    String? bio,
    String? resumeUrl,
    String? avatarUrl,
    // ข้อมูลบริษัท
    String? companyName,
    String? companySize,
    String? industry,
    String? companyDescription,
    String? website,
    String? companyAddress,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyName: companyName ?? this.companyName,
      companySize: companySize ?? this.companySize,
      industry: industry ?? this.industry,
      companyDescription: companyDescription ?? this.companyDescription,
      website: website ?? this.website,
      companyAddress: companyAddress ?? this.companyAddress,
    );
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}