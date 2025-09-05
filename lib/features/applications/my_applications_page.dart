import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../services/language_service.dart';

class MyApplicationsPage extends ConsumerStatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  ConsumerState<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends ConsumerState<MyApplicationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, String languageCode) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) return AppLocalizations.translate('today', languageCode);
    if (diff == 1) return AppLocalizations.translate('yesterday', languageCode);
    if (diff < 7) return '${AppLocalizations.translate('days_ago', languageCode)} $diff';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.reviewing:
        return Colors.blue;
      case ApplicationStatus.interview:
        return Colors.purple;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.reviewing:
        return Icons.visibility;
      case ApplicationStatus.interview:
        return Icons.event;
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }

  List<JobApplication> _filterApplicationsByStatus(
    List<JobApplication> applications,
    ApplicationStatus? filterStatus,
  ) {
    if (filterStatus == null) return applications;
    return applications.where((app) => app.status == filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationProvider);
    // Get language code from the language provider
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Get translations
    final myApplicationsTitle = AppLocalizations.translate('my_applications', languageCode);
    final refreshTooltip = AppLocalizations.translate('refresh', languageCode);
    final allTab = AppLocalizations.translate('all', languageCode);
    final pendingTab = AppLocalizations.translate('pending', languageCode);
    final interviewTab = AppLocalizations.translate('interview', languageCode);
    final completedTab = AppLocalizations.translate('completed', languageCode);
    final errorTitle = AppLocalizations.translate('error', languageCode);
    final tryAgainText = AppLocalizations.translate('try_again', languageCode);
    final noApplicationsText = AppLocalizations.translate('no_applications_yet', languageCode);
    final noApplicationsDesc = AppLocalizations.translate('no_applications_desc', languageCode);
    final findJobsText = AppLocalizations.translate('find_jobs', languageCode);
    final noApplicationsInCategory = AppLocalizations.translate('no_applications_in_category', languageCode);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(myApplicationsTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(applicationProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            tooltip: refreshTooltip,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: allTab),
            Tab(text: pendingTab),
            Tab(text: interviewTab),
            Tab(text: completedTab),
          ],
        ),
      ),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                errorTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(applicationProvider.notifier).refresh();
                },
                child: Text(tryAgainText),
              ),
            ],
          ),
        ),
        data: (applications) {
          if (applications.isEmpty) {
            return _buildEmptyState(languageCode);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // All applications
              _buildApplicationList(applications, languageCode),
              // Pending applications
              _buildApplicationList(
                _filterApplicationsByStatus(
                  applications,
                  ApplicationStatus.pending,
                ),
                languageCode,
              ),
              // Interview applications
              _buildApplicationList(
                applications
                    .where((app) =>
                        app.status == ApplicationStatus.interview ||
                        app.status == ApplicationStatus.reviewing)
                    .toList(),
                languageCode,
              ),
              // Completed applications (accepted/rejected)
              _buildApplicationList(
                applications
                    .where((app) =>
                        app.status == ApplicationStatus.accepted ||
                        app.status == ApplicationStatus.rejected)
                    .toList(),
                languageCode,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String languageCode) {
    final noApplicationsText = AppLocalizations.translate('no_applications_yet', languageCode);
    final noApplicationsDesc = AppLocalizations.translate('no_applications_desc', languageCode);
    final findJobsText = AppLocalizations.translate('find_jobs', languageCode);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            noApplicationsText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noApplicationsDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to job search
              DefaultTabController.of(context)?.animateTo(0);
            },
            icon: const Icon(Icons.search),
            label: Text(findJobsText),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationList(List<JobApplication> applications, String languageCode) {
    final noApplicationsInCategory = AppLocalizations.translate('no_applications_in_category', languageCode);
    
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              noApplicationsInCategory,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return _buildApplicationCard(application, languageCode);
      },
    );
  }

  Widget _buildApplicationCard(JobApplication application, String languageCode) {
    final statusColor = _getStatusColor(application.status);
    final statusIcon = _getStatusIcon(application.status);
    final appliedText = AppLocalizations.translate('applied_on', languageCode);
    final interviewText = AppLocalizations.translate('interview_on', languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApplicationDetails(application, languageCode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.jobTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            application.companyName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            application.status.getDisplayName(languageCode),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Applied date and interview info
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$appliedText ${_formatDate(application.appliedAt, languageCode)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (application.interviewDate != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.event,
                        size: 16,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$interviewText ${_formatDate(application.interviewDate!, languageCode)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Cover letter preview
                if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            application.coverLetter!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplicationDetails(JobApplication application, String languageCode) {
    final detailsTitle = AppLocalizations.translate('application_details', languageCode);
    final jobTitleLabel = AppLocalizations.translate('job_title', languageCode);
    final companyLabel = AppLocalizations.translate('company', languageCode);
    final statusLabel = AppLocalizations.translate('status', languageCode);
    final appliedDateLabel = AppLocalizations.translate('applied_date', languageCode);
    final interviewDateLabel = AppLocalizations.translate('interview_date', languageCode);
    final coverLetterLabel = AppLocalizations.translate('cover_letter', languageCode);
    final deleteApplication = AppLocalizations.translate('delete_application', languageCode);
    final viewJob = AppLocalizations.translate('view_job', languageCode);
    final cancelText = AppLocalizations.translate('cancel', languageCode);
    final deleteText = AppLocalizations.translate('delete', languageCode);
    final deleteConfirmText = AppLocalizations.translate('delete_application_confirm', languageCode);
    final applicationDeletedText = AppLocalizations.translate('application_deleted', languageCode);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Text(
                      detailsTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Job info
                    _buildDetailRow(
                      jobTitleLabel,
                      application.jobTitle,
                      Icons.work_outline,
                    ),
                    _buildDetailRow(
                      companyLabel,
                      application.companyName,
                      Icons.business,
                    ),
                    _buildDetailRow(
                      statusLabel,
                      application.status.getDisplayName(languageCode),
                      _getStatusIcon(application.status),
                      valueColor: _getStatusColor(application.status),
                    ),
                    _buildDetailRow(
                      appliedDateLabel,
                      DateFormat('dd/MM/yyyy HH:mm').format(application.appliedAt),
                      Icons.schedule,
                    ),
                    
                    if (application.interviewDate != null)
                      _buildDetailRow(
                        interviewDateLabel,
                        DateFormat('dd/MM/yyyy HH:mm').format(application.interviewDate!),
                        Icons.event,
                        valueColor: Colors.purple,
                      ),
                    
                    // Cover letter
                    if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        coverLetterLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          application.coverLetter!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(application, languageCode);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(deleteApplication),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigate to job detail
                            },
                            icon: const Icon(Icons.visibility),
                            label: Text(viewJob),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(JobApplication application, String languageCode) {
    final deleteApplication = AppLocalizations.translate('delete_application', languageCode);
    final deleteConfirmText = AppLocalizations.translate('delete_application_confirm', languageCode);
    final cancelText = AppLocalizations.translate('cancel', languageCode);
    final deleteText = AppLocalizations.translate('delete', languageCode);
    final applicationDeletedText = AppLocalizations.translate('application_deleted', languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteApplication),
        content: Text(
          '$deleteConfirmText "${application.jobTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(applicationProvider.notifier).deleteApplication(application.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(applicationDeletedText),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(deleteText),
          ),
        ],
      ),
    );
  }
}