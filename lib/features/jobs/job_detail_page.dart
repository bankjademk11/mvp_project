import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import '../../services/job_service.dart';
import '../../services/application_service.dart';
import '../../services/company_service.dart';
import '../../models/company.dart';
import '../../common/widgets/company_logo_widget.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool isBookmarked = false;
  bool isLoading = false;

  String _formatSalary(dynamic min, dynamic max, String languageCode) {
    if (min == null || max == null) return AppLocalizations.translate('negotiable', languageCode);
    
    final formatter = NumberFormat('#,###');
    final minStr = formatter.format(min / 1000000);
    final maxStr = formatter.format(max / 1000000);
    
    return '${minStr}M - ${maxStr}M ${AppLocalizations.translate('lao_currency', languageCode)}';
  }

  String _formatDate(String? dateStr, String languageCode) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      
      if (diff == 0) return AppLocalizations.translate('today', languageCode);
      if (diff == 1) return AppLocalizations.translate('yesterday', languageCode);
      if (diff < 7) return '${diff} ${AppLocalizations.translate('days_ago', languageCode)}';
      if (diff < 30) return '${(diff / 7).floor()} ${AppLocalizations.translate('weeks_ago', languageCode)}';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  void _handleApply(String languageCode) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final jobService = ref.read(JobService.jobServiceProvider);
      final job = await jobService.getJobById(widget.jobId);
      
      if (job.$id.isEmpty) {
        throw Exception(AppLocalizations.translate('job_not_found_error', languageCode));
      }
      
      await ref.read(applicationProvider.notifier).submitApplication(
        jobId: widget.jobId,
        jobTitle: job.data['title'] ?? '',
        companyName: job.data['companyName'] ?? '',
        coverLetter: AppLocalizations.translate('default_cover_letter', languageCode),
      );
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.translate('application_submitted', languageCode)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.translate('error', languageCode)}: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(String languageCode) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.translate('confirm_delete_job_title', languageCode)),
          content: Text(AppLocalizations.translate('confirm_delete_job_message', languageCode)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.translate('cancel', languageCode)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(AppLocalizations.translate('delete', languageCode)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      _deleteJob(languageCode);
    }
  }

  Future<void> _deleteJob(String languageCode) async {
    setState(() {
      isLoading = true;
    });
    try {
      await ref.read(JobService.jobServiceProvider).deleteJob(widget.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.translate('job_deleted_successfully', languageCode)),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.translate('error', languageCode)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobService = ref.watch(JobService.jobServiceProvider);
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);

    return FutureBuilder<models.Document>(
      future: jobService.getJobById(widget.jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: Text(t('loading'))),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(t('job_not_found'))),
            body: Center(
              child: Text('${t('error')}: ${snapshot.error}'),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.$id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(t('job_not_found'))),
            body: Center(
              child: Text(t('job_not_found_message')),
            ),
          );
        }

        final job = snapshot.data!;
        final title = job.data['title'] ?? '';
        final companyId = job.data['companyId'] ?? '';
        final companyName = job.data['companyName'] ?? '';
        final province = job.data['province'] ?? '';
        final type = job.data['type'] ?? 'Full-time';
        final tags = List<String>.from(job.data['tags'] ?? []);
        final description = job.data['description'] ?? '';
        final salaryText = _formatSalary(job.data['salaryMin'], job.data['salaryMax'], languageCode);
        final dateText = _formatDate(job.data['createdAt'], languageCode);

        final companyState = ref.watch(companyServiceProvider);
        final Company? currentCompany = companyState.selectedCompany;

        if (currentCompany == null || currentCompany.id != companyId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(companyServiceProvider.notifier).loadCompanyById(companyId);
          });
        }

        final authState = ref.watch(authProvider);
        final isJobPoster = authState.user?.role == 'employer' && authState.user?.uid == companyId;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                title: Text(t('job_detail')),
                actions: [
                  if (isJobPoster) ...[
                    IconButton(
                      onPressed: () => context.push('/employer/applications?jobId=${widget.jobId}'),
                      icon: const Icon(Icons.people_alt_outlined),
                      tooltip: t('view_applicants'),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : () => _confirmDelete(languageCode),
                      icon: const Icon(Icons.delete_forever),
                      tooltip: t('delete_job'),
                    ),
                  ],
                  if (!isJobPoster) ...[
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isBookmarked = !isBookmarked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBookmarked ? t('job_bookmarked') : t('job_bookmark_removed'),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('share_job'))),
                        );
                      },
                      icon: const Icon(Icons.share),
                    ),
                  ],
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CompanyLogoWidget(
                                logoUrl: currentCompany?.logo,
                                companyName: currentCompany?.name ?? companyName,
                                size: 64,
                                borderRadius: 16,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      companyName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          province,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                Icons.work_outline,
                                type,
                                Theme.of(context).colorScheme.primary,
                              ),
                              _buildInfoChip(
                                Icons.payments_outlined,
                                salaryText,
                                Colors.green,
                              ),
                              if (dateText.isNotEmpty)
                                _buildInfoChip(
                                  Icons.schedule,
                                  '${t('posted_on')} $dateText',
                                  Colors.orange,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSection(
                      title: t('job_detail'),
                      icon: Icons.description_outlined,
                      child: Text(
                        description.isNotEmpty ? description : t('no_description'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                    if (tags.isNotEmpty)
                      _buildSection(
                        title: t('requirements'),
                        icon: Icons.psychology_outlined,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    _buildSection(
                      title: t('about_company'),
                      icon: Icons.business_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('company_description'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                province,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isJobPoster
              ? null
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t('start_chat_with_hr')),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(t('chat')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: isLoading ? t('applying') : t('apply'),
                            onPressed: isLoading ? null : () => _handleApply(languageCode),
                            loading: isLoading,
                            icon: isLoading ? null : Icons.send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}