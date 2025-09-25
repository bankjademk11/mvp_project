import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';
import '../../services/application_service.dart';
import '../../models/application.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ApplicationDetailPage extends ConsumerWidget {
  final String applicationId;
  
  const ApplicationDetailPage({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);
    
    return FutureBuilder<models.Document?>(
      future: _fetchApplication(ref, applicationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(t('loading'))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t('error'))),
            body: Center(
              child: Text('${t('error')}: ${snapshot.error?.toString() ?? 'Application not found'}'),
            ),
          );
        }

        final application = snapshot.data!;
        return _ApplicationDetailView(application: application, t: t, ref: ref);
      },
    );
  }

  Future<models.Document?> _fetchApplication(WidgetRef ref, String applicationId) async {
    try {
      final applicationService = ref.read(ApplicationService.applicationServiceProvider);
      final application = await applicationService.getApplicationById(applicationId);
      return application;
    } catch (e) {
      // Handle error
      return null;
    }
  }
}

class _ApplicationDetailView extends ConsumerWidget {
  final models.Document application;
  final Function(String) t;
  final WidgetRef ref;
  
  const _ApplicationDetailView({required this.application, required this.t, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationData = application.data;
    
    final applicantAvatarUrl = applicationData['applicantAvatarUrl'] as String?;
    final applicantName = applicationData['applicantName']?.toString() ?? t('unknown_applicant');
    final jobTitle = applicationData['jobTitle']?.toString() ?? t('unknown_job');
    final companyName = applicationData['companyName']?.toString() ?? t('unknown_company');
    final appliedAtRaw = applicationData['appliedAt'] as String?;
    final coverLetter = applicationData['coverLetter']?.toString() ?? '';
    final resumeUrl = applicationData['resumeUrl'] as String?;
    final status = applicationData['status'] ?? 'pending';
    
    String appliedAtFormatted = t('unknown_date');
    if (appliedAtRaw != null) {
      try {
        final dateTime = DateTime.parse(appliedAtRaw);
        appliedAtFormatted = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        appliedAtFormatted = appliedAtRaw; // Fallback
      }
    }

    final bool hasCv = resumeUrl != null && resumeUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('application_details')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Info Card
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _getStatusColor(status).withOpacity(0.1),
                          backgroundImage: (applicantAvatarUrl != null && applicantAvatarUrl.isNotEmpty)
                              ? NetworkImage(applicantAvatarUrl)
                              : null,
                          child: (applicantAvatarUrl == null || applicantAvatarUrl.isEmpty)
                              ? Text(
                                  applicantName.isNotEmpty ? applicantName.substring(0, 1).toUpperCase() : '?',
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applicantName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t('applied_for_position')}: $jobTitle',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                companyName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${t('applied_on')}: $appliedAtFormatted',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(status, t),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Cover Letter Section
            if (coverLetter.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('cover_letter'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        coverLetter,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Resume/CV Section
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('resume'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasCv) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(resumeUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open CV link: $resumeUrl'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: Text(t('open_cv_of').replaceAll('{name}', applicantName)),
                        ),
                      ),
                    ] else ...[
                      Text(
                        t('no_resume'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Show reject confirmation dialog
                      _showConfirmDialog(
                        context,
                        t('reject_application_title'),
                        t('reject_application_confirm').replaceAll('{name}', applicantName),
                        () async {
                          try {
                            final applicationService = ref.read(ApplicationService.applicationServiceProvider);
                            await applicationService.updateApplicationStatus(
                              application.$id,
                              ApplicationStatus.rejected,
                            );
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('application_rejected_success'))),
                              );
                              // Navigate back
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${t('error')}: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        t,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Text(t('reject')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Show approve confirmation dialog
                      _showConfirmDialog(
                        context,
                        t('approve_application_title'),
                        t('approve_application_confirm').replaceAll('{name}', applicantName),
                        () async {
                          try {
                            final applicationService = ref.read(ApplicationService.applicationServiceProvider);
                            await applicationService.updateApplicationStatus(
                              application.$id,
                              ApplicationStatus.accepted,
                            );
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('application_approved_success'))),
                              );
                              // Navigate back
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${t('error')}: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        t,
                      );
                    },
                    child: Text(t('approve')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement schedule interview functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('interview_feature_dev'))),
                  );
                },
                icon: const Icon(Icons.event),
                label: Text(t('schedule_interview_action')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    // Get the chat service
                    final chatService = ref.read(chatServiceProvider.notifier);
                    
                    // Get applicant info from application data
                    final applicantId = application.data['userId'] as String?;
                    final applicantName = application.data['applicantName'] as String?;
                    
                    if (applicantId == null || applicantName == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to start chat: Applicant information missing')),
                        );
                      }
                      return;
                    }
                    
                    // Create or get existing chat
                    final chatId = await chatService.findOrCreateChat(applicantId);
                    
                    // Navigate to chat room
                    if (context.mounted) {
                      context.push('/chats/$chatId?otherUserId=$applicantId');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble),
                label: Text(t('contact_applicant')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final appStatus = ApplicationStatus.fromString(status);
    switch (appStatus) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, Function t) {
    final appStatus = ApplicationStatus.fromString(status);
    return t(appStatus.displayNameKey);
  }
  
  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    Function t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }
}