import 'package:flutter/material.dart';
import '../services/language_service.dart';

enum ApplicationStatus {
  pending('status_pending', 'pending'),
  reviewing('status_reviewing', 'reviewing'),
  interview('status_interview', 'interview'),
  accepted('status_accepted', 'accepted'),
  rejected('status_rejected', 'rejected');

  const ApplicationStatus(this.displayNameKey, this.value);
  final String displayNameKey;
  final String value;

  String getDisplayName(String languageCode) {
    return AppLocalizations.translate(displayNameKey, languageCode);
  }

  static ApplicationStatus fromString(String value) {
    return ApplicationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? coverLetter;
  final String? resumeUrl;
  final DateTime? interviewDate;
  final String? notes;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.appliedAt,
    this.coverLetter,
    this.resumeUrl,
    this.interviewDate,
    this.notes,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      status: ApplicationStatus.fromString(json['status'] ?? 'pending'),
      appliedAt: DateTime.parse(json['appliedAt'] ?? DateTime.now().toIso8601String()),
      coverLetter: json['coverLetter'],
      resumeUrl: json['resumeUrl'],
      interviewDate: json['interviewDate'] != null 
          ? DateTime.parse(json['interviewDate']) 
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'status': status.value,
      'appliedAt': appliedAt.toIso8601String(),
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
      'interviewDate': interviewDate?.toIso8601String(),
      'notes': notes,
    };
  }

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    ApplicationStatus? status,
    DateTime? appliedAt,
    String? coverLetter,
    String? resumeUrl,
    DateTime? interviewDate,
    String? notes,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      interviewDate: interviewDate ?? this.interviewDate,
      notes: notes ?? this.notes,
    );
  }
}