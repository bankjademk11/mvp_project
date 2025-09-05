import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/mock_api.dart';
import '../../services/application_service.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/language_service.dart';

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
      // Get job details for application
      final jobs = await MockApi.loadJobs();
      final job = jobs.cast<Map<String, dynamic>>().firstWhere(
        (e) => e['id'] == widget.jobId,
        orElse: () => {},
      );
      
      if (job.isEmpty) {
        throw Exception(AppLocalizations.translate('job_not_found_error', languageCode));
      }
      
      // Submit application
      await ref.read(applicationProvider.notifier).submitApplication(
        jobId: widget.jobId,
        jobTitle: job['title'] ?? '',
        companyName: job['companyName'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Get translations
    final jobDetailsTitle = AppLocalizations.translate('job_detail', languageCode);
    final notFoundTitle = AppLocalizations.translate('job_not_found', languageCode);
    final notFoundMessage = AppLocalizations.translate('job_not_found_message', languageCode);
    final bookmarkSaved = AppLocalizations.translate('job_bookmarked', languageCode);
    final bookmarkRemoved = AppLocalizations.translate('job_bookmark_removed', languageCode);
    final shareJob = AppLocalizations.translate('share_job', languageCode);
    final postedOn = AppLocalizations.translate('posted_on', languageCode);
    final noDescription = AppLocalizations.translate('no_description', languageCode);
    final requiredSkills = AppLocalizations.translate('requirements', languageCode);
    final aboutCompany = AppLocalizations.translate('about_company', languageCode);
    final companyDescription = AppLocalizations.translate('company_description', languageCode);
    final startChat = AppLocalizations.translate('start_chat_with_hr', languageCode);
    final chat = AppLocalizations.translate('chat', languageCode);
    final apply = AppLocalizations.translate('apply', languageCode);
    final applying = AppLocalizations.translate('applying', languageCode);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder(
        future: MockApi.loadJobs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              body: Center(child: Text(AppLocalizations.translate('loading', languageCode))),
            );
          }
          
          final jobs = (snapshot.data as List).cast<Map<String, dynamic>>();
          final job = jobs.firstWhere(
            (e) => e['id'] == widget.jobId,
            orElse: () => {},
          );
          
          if (job.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(notFoundTitle)),
              body: Center(
                child: Text(notFoundMessage),
              ),
            );
          }

          final title = job['title'] ?? '';
          final company = job['companyName'] ?? '';
          final province = job['province'] ?? '';
          final type = job['type'] ?? 'Full-time';
          final tags = (job['tags'] as List?)?.cast<String>() ?? [];
          final description = job['description'] ?? '';
          final salaryText = _formatSalary(job['salaryMin'], job['salaryMax'], languageCode);
          final dateText = _formatDate(job['createdAt'], languageCode);

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                title: Text(jobDetailsTitle),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isBookmarked = !isBookmarked;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked ? bookmarkSaved : bookmarkRemoved,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(shareJob)),
                      );
                    },
                    icon: const Icon(Icons.share),
                  ),
                ],
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Header Card
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
                          // Company logo and basic info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 32,
                                ),
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
                                      company,
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
                          
                          // Job details chips
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
                                  '$postedOn $dateText',
                                  Colors.orange,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Job Description
                    _buildSection(
                      title: jobDetailsTitle,
                      icon: Icons.description_outlined,
                      child: Text(
                        description.isNotEmpty 
                            ? description 
                            : noDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                    
                    // Required Skills
                    if (tags.isNotEmpty)
                      _buildSection(
                        title: requiredSkills,
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
                    
                    // Company Info
                    _buildSection(
                      title: aboutCompany,
                      icon: Icons.business_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            companyDescription,
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
                    
                    // Bottom spacing for floating buttons
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      
      // Floating Bottom Actions
      bottomNavigationBar: Container(
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
                    // TODO: Start chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(startChat),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(chat),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: isLoading ? applying : apply,
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