import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';

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
  String _selectedFilter = 'all';

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

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId != null ? t('applicants') : t('all_applications')),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_off),
                    const SizedBox(width: 8),
                    Text(t('all')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'today',
                child: Row(
                  children: [
                    const Icon(Icons.today),
                    const SizedBox(width: 8),
                    Text(t('today')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 8),
                    Text(t('this_week')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 8),
                    Text(t('this_month')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationList(context, 'all'),
          _buildApplicationList(context, 'pending'),
          _buildApplicationList(context, 'approved'),
          _buildApplicationList(context, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildApplicationList(BuildContext context, String status) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);
    final applications = _getMockApplications(status, t);

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              t('no_applications'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('no_applications_in_status'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return _buildApplicationCard(context, application, t);
        },
      ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, Map<String, dynamic> application, Function t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showApplicationDetails(context, application, t),
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
                    backgroundColor:
                        _getStatusColor(application['status']).withOpacity(0.1),
                    child: Text(
                      application['applicantName'].substring(0, 1),
                      style: TextStyle(
                        color: _getStatusColor(application['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application['applicantName'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application['position'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(application['status'], t),
                      style: TextStyle(
                        color: _getStatusColor(application['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    application['email'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    application['phone'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    application['location'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.work_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${application['experience']} ${t('years_experience')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (application['skills'] != null &&
                  application['skills'].isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: application['skills']
                      .take(3)
                      .map<Widget>(
                        (skill) => Chip(
                          label: Text(
                            skill,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          side: BorderSide.none,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${t('applied_on')}: ${application['appliedDate']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  Row(
                    children: [
                      if (application['hasCV'] == true)
                        TextButton.icon(
                          onPressed: () => _viewCV(context, application, t),
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: Text(t('view_cv')),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleApplicationAction(context, value, application, t),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(t('approve')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(t('reject')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'interview',
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 8),
                                Text(t('schedule_interview_action')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'message',
                            child: Row(
                              children: [
                                const Icon(Icons.message_outlined),
                                const SizedBox(width: 8),
                                Text(t('send_message')),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.more_vert, size: 16),
                        ),
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
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'interviewed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, Function t) {
    switch (status) {
      case 'pending':
        return t('pending_review');
      case 'approved':
        return t('shortlisted');
      case 'rejected':
        return t('rejected_applications');
      case 'interviewed':
        return t('interviewed');
      default:
        return t('unspecified');
    }
  }

  void _showApplicationDetails(
      BuildContext context, Map<String, dynamic> application, Function t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t('applicant_details'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(t('applicant_name'), application['applicantName']),
                      _buildDetailItem(t('email'), application['email']),
                      _buildDetailItem(t('phone'), application['phone']),
                      _buildDetailItem(t('location'), application['location']),
                      _buildDetailItem(
                          t('applied_for_position'), application['position']),
                      _buildDetailItem(t('experience'),
                          '${application['experience']} ${t('years_experience')}'),
                      const SizedBox(height: 16),
                      Text(
                        t('skills'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application['skills']
                            .map<Widget>(
                              (skill) => Chip(
                                label: Text(skill),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                            )
                            .toList(),
                      ),
                      if (application['coverLetter'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          t('cover_letter'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(application['coverLetter']),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _viewCV(BuildContext context, Map<String, dynamic> application, Function t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t('open_cv_of')} ${application['applicantName']}'),
        action: SnackBarAction(
          label: t('download'),
          onPressed: () {
            // TODO: Implement CV download
          },
        ),
      ),
    );
  }

  void _handleApplicationAction(
    BuildContext context,
    String action,
    Map<String, dynamic> application,
    Function t,
  ) {
    switch (action) {
      case 'approve':
        _showConfirmDialog(
          context,
          t('approve_application_title'),
          t('approve_application_confirm').replaceAll('{name}', application['applicantName']),
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('application_approved_success'))),
            );
          },
          t,
        );
        break;
      case 'reject':
        _showConfirmDialog(
          context,
          t('reject_application_title'),
          t('reject_application_confirm').replaceAll('{name}', application['applicantName']),
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('application_rejected_success'))),
            );
          },
          t,
        );
        break;
      case 'interview':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('interview_feature_dev'))),
        );
        break;
      case 'message':
        context.push('/chats/new?userId=${application['applicantId']}');
        break;
    }
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

  List<Map<String, dynamic>> _getMockApplications(String status, Function t) {
    final allApplications = [
      {
        'id': '1',
        'applicantId': 'user_001',
        'applicantName': 'ສົມຊາຍ ໃຈດີ',
        'email': 'somchai@email.com',
        'phone': '020-123-4567',
        'location': 'ນະຄອນຫຼວງວຽງຈັນ',
        'position': 'ນັກພັດທະນາ Flutter',
        'experience': 3,
        'skills': ['Flutter', 'Dart', 'Firebase', 'REST API'],
        'status': 'pending',
        'appliedDate': '2 ຊົ່ວໂມງກ່ອນ',
        'hasCV': true,
        'coverLetter':
            'ຂ້າພະເຈົ້າສົນໃຈຕຳແໜ່ງນີ້ຫຼາຍ ແລະ ມີປະສົບການໃນການພັດທະນາ Flutter 3 ປີ...',
      },
      {
        'id': '2',
        'applicantId': 'user_002',
        'applicantName': 'ສົມຍິງ ຮັກງານ',
        'email': 'somying@email.com',
        'phone': '020-234-5678',
        'location': 'ສະຫວັນນະເຂດ',
        'position': 'UI/UX Designer',
        'experience': 2,
        'skills': ['Figma', 'Adobe XD', 'Sketch', 'Prototyping'],
        'status': 'approved',
        'appliedDate': '5 ຊົ່ວໂມງກ່ອນ',
        'hasCV': true,
      },
      {
        'id': '3',
        'applicantId': 'user_003',
        'applicantName': 'ວິໄຊ ຂยัน',
        'email': 'wichai@email.com',
        'phone': '020-345-6789',
        'location': 'ປາກເຊ',
        'position': 'ນັກພັດທະນາ Flutter',
        'experience': 1,
        'skills': ['Flutter', 'Dart', 'Git'],
        'status': 'rejected',
        'appliedDate': '1 ມື້ກ່ອນ',
        'hasCV': true,
      },
      {
        'id': '4',
        'applicantId': 'user_004',
        'applicantName': 'ນາລີ ສວຍງາມ',
        'email': 'naree@email.com',
        'phone': '020-456-7890',
        'location': 'ຫຼວງພະບາງ',
        'position': 'Frontend Developer',
        'experience': 4,
        'skills': ['React', 'Vue.js', 'TypeScript', 'CSS'],
        'status': 'interviewed',
        'appliedDate': '3 ມື້ກ່ອນ',
        'hasCV': true,
      },
    ];

    switch (status) {
      case 'pending':
        return allApplications
            .where((app) => app['status'] == 'pending')
            .toList();
      case 'approved':
        return allApplications
            .where((app) => app['status'] == 'approved')
            .toList();
      case 'rejected':
        return allApplications
            .where((app) => app['status'] == 'rejected')
            .toList();
      case 'interviewed':
        return allApplications
            .where((app) => app['status'] == 'interviewed')
            .toList();
      default:
        return allApplications;
    }
  }
}
