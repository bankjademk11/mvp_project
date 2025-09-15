import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import '../../services/job_service.dart';
import '../../services/application_service.dart';
import '../../services/company_service.dart';
import '../../services/bookmark_service.dart';
import '../../models/company.dart';
import '../../common/widgets/company_logo_widget.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';

// Provider to fetch job details once
final jobDetailProvider = FutureProvider.family<models.Document?, String>((ref, jobId) {
  final jobService = ref.watch(JobService.jobServiceProvider);
  // Return null if the job is not found, handled in the UI.
  try {
    return jobService.getJobById(jobId);
  } catch (e) {
    return null;
  }
});

class JobDetailPage extends ConsumerWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsyncValue = ref.watch(jobDetailProvider(jobId));
    final t = (key) => AppLocalizations.translate(key, ref.watch(languageProvider).languageCode);

    return jobAsyncValue.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(t('job_not_found'))),
        body: Center(child: Text('${t('error')}: $err')),
      ),
      data: (job) {
        if (job == null || job.$id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(t('job_not_found'))),
            body: Center(child: Text(t('job_not_found_message'))),
          );
        }
        return _JobDetailView(job: job);
      },
    );
  }
}

class _JobDetailView extends ConsumerStatefulWidget {
  final models.Document job;
  const _JobDetailView({required this.job});

  @override
  ConsumerState<_JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends ConsumerState<_JobDetailView> {
  bool _isApplying = false;

  String _formatSalary(dynamic min, dynamic max, String languageCode) {
    final t = (key) => AppLocalizations.translate(key, languageCode);
    if (min == null || max == null) return t('negotiable');
    final formatter = NumberFormat('#,###');
    return '${formatter.format(min)} - ${formatter.format(max)} ${t('lao_currency')}';
  }

  String _formatDate(String? dateStr, String languageCode) {
    if (dateStr == null) return '';
    final t = (key) => AppLocalizations.translate(key, languageCode);
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return t('today');
      if (diff == 1) return t('yesterday');
      if (diff < 7) return '${diff} ${t('days_ago')}';
      if (diff < 30) return '${(diff / 7).floor()} ${t('weeks_ago')}';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  void _showApplyDialog(String languageCode) {
    final t = (key) => AppLocalizations.translate(key, languageCode);
    final coverLetterController = TextEditingController(text: t('default_cover_letter'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('apply_job'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.job.data['title'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: coverLetterController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: t('cover_letter'),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: _isApplying ? t('applying') : t('confirm'),
                    onPressed: _isApplying
                        ? null
                        : () async {
                            setModalState(() => _isApplying = true);
                            try {
                              final authState = ref.read(authProvider);
                              final applicantName = authState.user?.displayName;

                              // Use creatorUserId if available, otherwise fall back to companyId for older data.
                              final employerId = widget.job.data['creatorUserId'] ?? widget.job.data['companyId'];
                              final teamId = widget.job.data['teamId']; // Add this

                              if (applicantName == null || applicantName.isEmpty) {
                                throw Exception('Applicant name is missing.');
                              }
                              if (employerId == null || employerId.isEmpty) {
                                throw Exception('Could not determine Employer ID from job data.');
                              }
                              if (teamId == null || teamId.isEmpty) {
                                throw Exception('Could not determine Team ID from job data.');
                              }

                              await ref.read(applicationProvider.notifier).submitApplication(
                                    jobId: widget.job.$id,
                                    applicantName: applicantName,
                                    employerId: employerId,
                                    teamId: teamId, // Add this
                                    jobTitle: widget.job.data['title'] ?? '',
                                    companyName: widget.job.data['companyName'] ?? '',
                                    coverLetter: coverLetterController.text,
                                  );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t('application_submitted')),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (error) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${t('error')}: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setModalState(() => _isApplying = false);
                              }
                            }
                          },
                    loading: _isApplying,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);
    final bookmarkState = ref.watch(bookmarkServiceProvider);
    final authState = ref.watch(authProvider);

    final job = widget.job;
    final title = job.data['title'] ?? '';
    final companyId = job.data['companyId'] ?? '';
    final companyName = job.data['companyName'] ?? '';
    final province = job.data['province'] ?? '';
    final type = job.data['type'] ?? 'Full-time';
    final tags = List<String>.from(job.data['tags'] ?? []);
    final description = job.data['description'] ?? '';
    final salaryText = _formatSalary(job.data['salaryMin'], job.data['salaryMax'], languageCode);
    final dateText = _formatDate(job.data['createdAt'], languageCode);

    final isBookmarked = bookmarkState.isBookmarked(job.$id);
    final isJobPoster = authState.user?.role == 'employer' && authState.user?.uid == companyId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(t('job_detail')),
            actions: [
              if (isJobPoster) ...[
                // Employer actions
              ] else ...[
                IconButton(
                  onPressed: () {
                    ref.read(bookmarkServiceProvider.notifier).toggleBookmark(job.$id, job.data);
                  },
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Job Info Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // We pass the company logo from the company details section later
                          CompanyLogoWidget(companyName: companyName, size: 64, borderRadius: 16),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2)),
                                const SizedBox(height: 8),
                                Text(companyName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                    const SizedBox(width: 4),
                                    Text(province, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
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
                          _buildInfoChip(Icons.work_outline, type, Theme.of(context).colorScheme.primary),
                          _buildInfoChip(Icons.payments_outlined, salaryText, Colors.green),
                          if (dateText.isNotEmpty) _buildInfoChip(Icons.schedule, '${t('posted_on')} $dateText', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                // Job Description Section
                _buildSection(
                  context: context,
                  title: t('job_description'),
                  icon: Icons.description_outlined,
                  child: Text(description.isNotEmpty ? description : t('no_description'), style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                ),
                // Requirements Section
                if (tags.isNotEmpty)
                  _buildSection(
                    context: context,
                    title: t('requirements'),
                    icon: Icons.psychology_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(tag, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ),
                // Company Details Section
                _CompanyDetailsSection(companyId: companyId, companyName: companyName, province: province),
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
              child: PrimaryButton(
                text: t('apply'),
                onPressed: () => _showApplyDialog(languageCode),
              ),
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// A dedicated widget to handle fetching and displaying company details
class _CompanyDetailsSection extends ConsumerWidget {
  final String companyId;
  final String companyName;
  final String province;

  const _CompanyDetailsSection({
    required this.companyId,
    required this.companyName,
    required this.province,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = (key) => AppLocalizations.translate(key, ref.watch(languageProvider).languageCode);
    final companyState = ref.watch(companyServiceProvider);
    final company = companyState.selectedCompany;

    if (companyId.isNotEmpty && (company == null || company.id != companyId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(companyServiceProvider.notifier).loadCompanyById(companyId);
      });
    }

    return _buildSection(
      context: context,
      title: t('about_company'),
      icon: Icons.business_outlined,
      child: companyState.isLoading && (company == null || company.id != companyId)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(companyName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  (company != null && company.description.isNotEmpty) ? company.description : t('no_description'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(province, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
