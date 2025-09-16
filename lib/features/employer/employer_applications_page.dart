import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import '../../services/language_service.dart';
import '../../services/application_service.dart';
import '../../services/notification_service.dart';
import '../../models/application.dart';
import '../../services/auth_service.dart';

// NOTE: The FutureProvider was removed as it was causing data consistency issues.
// We are now using a StatefulWidget with a FutureBuilder for more direct control.

class EmployerApplicationsPage extends ConsumerStatefulWidget {
  final String? jobId;

  const EmployerApplicationsPage({
    super.key,
    this.jobId,
  });

  @override
  ConsumerState<EmployerApplicationsPage> createState() =>
      _EmployerApplicationsPageState();
}

class _EmployerApplicationsPageState extends ConsumerState<EmployerApplicationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<models.Document>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Fetch initial data
    _fetchApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchApplications() {
    final applicationService = ref.read(ApplicationService.applicationServiceProvider);
    final currentUser = ref.read(authProvider).user;
    if (widget.jobId != null && currentUser != null) {
      _applicationsFuture = applicationService.getApplicationsForEmployer(widget.jobId!, currentUser.uid);
    } else {
      _applicationsFuture = Future.value([]);
    }
  }

  Future<void> _handleRefresh() async {
    // Trigger a refetch and update the UI
    setState(() {
      _fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId != null ? t('applicants') : t('all_applications')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: t('all')),
            Tab(text: t('pending_review')),
            Tab(text: t('shortlisted')),
            Tab(text: t('rejected_applications')),
          ],
        ),
      ),
      body: FutureBuilder<List<models.Document>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: Text(t('retry')),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(t('no_applications_found'), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              );
          }
          
          final applications = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildApplicationList(context, 'all', applications, t),
              _buildApplicationList(context, 'pending', applications, t),
              _buildApplicationList(context, ApplicationStatus.accepted.value, applications, t),
              _buildApplicationList(context, ApplicationStatus.rejected.value, applications, t),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplicationList(
      BuildContext context, String status, List<models.Document> allApplications, Function t) {
    
    final filteredApps = status == 'all'
        ? allApplications
        : allApplications.where((app) => app.data['status'] == status).toList();

    if (filteredApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(t('no_applications_in_status'), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredApps.length,
        itemBuilder: (context, index) {
          final application = filteredApps[index];
          return _buildApplicationCard(context, application, t);
        },
      ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, models.Document application, Function t) {
    final applicationData = application.data;

    final applicantName = applicationData['applicantName']?.toString() ?? t('unknown_applicant');
    final appliedAtRaw = applicationData['appliedAt'] as String?;
    String appliedAtFormatted = '';
    if (appliedAtRaw != null) {
      try {
        final dateTime = DateTime.parse(appliedAtRaw);
        appliedAtFormatted = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        appliedAtFormatted = appliedAtRaw; // Fallback
      }
    }

    final status = applicationData['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () { /* TODO: Show details */ },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Text(
                      applicantName.isNotEmpty ? applicantName.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(applicantName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(applicationData['jobTitle'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status, t),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${t('applied_on')}: $appliedAtFormatted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () { /* TODO: View CV */ },
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: Text(t('view_cv')),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleApplicationAction(context, value, application, t),
                        itemBuilder: (context) => [
                          if (status == 'pending')
                            PopupMenuItem(
                              value: 'approve',
                              child: Row(children: [const Icon(Icons.check_circle_outline, color: Colors.green), const SizedBox(width: 8), Text(t('approve'))]),
                            ),
                          if (status == 'pending' || status == 'approved')
                            PopupMenuItem(
                              value: 'reject',
                              child: Row(children: [const Icon(Icons.cancel_outlined, color: Colors.red), const SizedBox(width: 8), Text(t('reject'))]),
                            ),
                        ],
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

  void _handleApplicationAction(
    BuildContext context,
    String action,
    models.Document application,
    Function t,
  ) {
    ApplicationStatus newStatus;
    switch (action) {
      case 'approve':
        newStatus = ApplicationStatus.accepted;
        break;
      case 'reject':
        newStatus = ApplicationStatus.rejected;
        break;
      default:
        return;
    }

    _showConfirmDialog(
      context,
      t('${action}_application_title'),
      t('${action}_application_confirm').replaceAll('{name}', application.data['applicantName'] ?? 'applicant'),
      () async {
        try {
          final appService = ref.read(ApplicationService.applicationServiceProvider);
          await appService.updateApplicationStatus(application.$id, newStatus);

          _handleRefresh(); // Refresh data after update

          final notifService = ref.read(notificationServiceProvider.notifier);
          await notifService.sendApplicationNotification(
            newStatus.getDisplayName(ref.read(languageProvider).languageCode),
            application.data['jobTitle'] ?? '',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('application_${action}d_success') ?? 'Status updated')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      },
      t,
    );
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            onConfirm();
          }, child: Text(t('confirm'))),
        ],
      ),
    );
  }
}