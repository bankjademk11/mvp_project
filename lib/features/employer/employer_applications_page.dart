import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployerApplicationsPage extends ConsumerStatefulWidget {
  final String? jobId;
  
  const EmployerApplicationsPage({
    super.key,
    this.jobId,
  });

  @override
  ConsumerState<EmployerApplicationsPage> createState() => _EmployerApplicationsPageState();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId != null ? 'ຜູ້ສະໝັກງານ' : 'ໃບສະໝັກທັ້ງໜົດ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'ທั้งหมด'),
            Tab(text: 'รอพิจารณา'),
            Tab(text: 'ผ่านเข้ารอบ'),
            Tab(text: 'ไม่ผ่าน'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.filter_list_off),
                    SizedBox(width: 8),
                    Text('ทั้งหมด'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Row(
                  children: [
                    Icon(Icons.today),
                    SizedBox(width: 8),
                    Text('วันนี้'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('สัปดาห์นี้'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('เดือนนี้'),
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
    final applications = _getMockApplications(status);
    
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
              'ບໍ່ມີໃບສະໝັກ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ຍັງບໍ່ມີຜູ້ສະໝັກໃນສະຖານະບານນີ້',
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
          return _buildApplicationCard(context, application);
        },
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, Map<String, dynamic> application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showApplicationDetails(context, application),
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
                    backgroundColor: _getStatusColor(application['status']).withOpacity(0.1),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      _getStatusText(application['status']),
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
              
              // ข้อมูลพื้นฐาน
              Row(
                children: [
                  Icon(Icons.email_outlined, 
                       size: 16, 
                       color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    application['email'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone_outlined, 
                       size: 16, 
                       color: Colors.grey.shade600),
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
                       size: 16, 
                       color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    application['location'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.work_outline, 
                       size: 16, 
                       color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${application['experience']} ปี',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ทักษะ
              if (application['skills'] != null && application['skills'].isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: application['skills'].take(3).map<Widget>((skill) =>
                    Chip(
                      label: Text(
                        skill,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide.none,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // การกระทำ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ສະໝັກເມື່ອ: ${application['appliedDate']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Row(
                    children: [
                      if (application['hasCV'] == true)
                        TextButton.icon(
                          onPressed: () => _viewCV(context, application),
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('ดู CV'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleApplicationAction(
                          context, 
                          value, 
                          application,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green),
                                SizedBox(width: 8),
                                Text('อนุมัติ'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red),
                                SizedBox(width: 8),
                                Text('ไม่อนุมัติ'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'interview',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined),
                                SizedBox(width: 8),
                                Text('นัดสัมภาษณ์'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'message',
                            child: Row(
                              children: [
                                Icon(Icons.message_outlined),
                                SizedBox(width: 8),
                                Text('ส่งข้อความ'),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอพิจารณา';
      case 'approved':
        return 'ผ่านเข้ารอบ';
      case 'rejected':
        return 'ไม่ผ่าน';
      case 'interviewed':
        return 'สัมภาษณ์แล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }

  void _showApplicationDetails(BuildContext context, Map<String, dynamic> application) {
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
              
              // หัวข้อ
              Text(
                'ລາຍລະອຽດຜູ້ສະໝັກ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // รายละเอียดเต็ม
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('ชื่อ-นามสกุล', application['applicantName']),
                      _buildDetailItem('อีเมล', application['email']),
                      _buildDetailItem('เบอร์โทร', application['phone']),
                      _buildDetailItem('ที่อยู่', application['location']),
                      _buildDetailItem('ຕໍາແໜ່ງທີ່ສະໝັກ', application['position']),
                      _buildDetailItem('ປະສົບການ', '${application['experience']} ປີ'),
                      
                      const SizedBox(height: 16),
                      Text(
                        'ทักษะ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application['skills'].map<Widget>((skill) =>
                          Chip(
                            label: Text(skill),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          ),
                        ).toList(),
                      ),
                      
                      if (application['coverLetter'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'ຈົດຫມາຍສະໝັກງານ',
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

  void _viewCV(BuildContext context, Map<String, dynamic> application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เปิด CV ของ ${application['applicantName']}'),
        action: SnackBarAction(
          label: 'ดาวน์โหลด',
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
  ) {
    switch (action) {
      case 'approve':
        _showConfirmDialog(
          context, 
          'ອະນຸມັດໃບສະໝັກ',
          'ທ່ານຕ້ອງການອະນຸມັດໃບສະໝັກຂອງ ${application['applicantName']} ຫຼືບໍ່?',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ອະນຸມັດໃບສະໝັກເລຍບຮ້ອຍແລ້ວ')),
            );
          },
        );
        break;
      case 'reject':
        _showConfirmDialog(
          context, 
          'ບໍ່ອະນຸມັດໃບສະໝັກ',
          'ທ່ານຕ້ອງການບໍ່ອະນຸມັດໃບສະໝັກຂອງ ${application['applicantName']} ຫຼືບໍ່?',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ບໍ່ອະນຸມັດໃບສະໝັກເລຍບຮ້ອຍແລ້ວ')),
            );
          },
        );
        break;
      case 'interview':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ຟີເຈີນັດສຳພາດກຳລັງພັດທະນາ')),
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
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('ຢືນຢັນ'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockApplications(String status) {
    final allApplications = [
      {
        'id': '1',
        'applicantId': 'user_001',
        'applicantName': 'สมชาย ใจดี',
        'email': 'somchai@email.com',
        'phone': '081-234-5678',
        'location': 'กรุงเทพฯ',
        'position': 'นักพัฒนา Flutter',
        'experience': 3,
        'skills': ['Flutter', 'Dart', 'Firebase', 'REST API'],
        'status': 'pending',
        'appliedDate': '2 ชั่วโมงที่แล้ว',
        'hasCV': true,
        'coverLetter': 'ผมสนใจตำแหน่งนี้มาก และมีประสบการณ์ในการพัฒนา Flutter มา 3 ปี...',
      },
      {
        'id': '2',
        'applicantId': 'user_002',
        'applicantName': 'สมหญิง รักงาน',
        'email': 'somying@email.com',
        'phone': '082-345-6789',
        'location': 'นนทบุรี',
        'position': 'UI/UX Designer',
        'experience': 2,
        'skills': ['Figma', 'Adobe XD', 'Sketch', 'Prototyping'],
        'status': 'approved',
        'appliedDate': '5 ชั่วโมงที่แล้ว',
        'hasCV': true,
      },
      {
        'id': '3',
        'applicantId': 'user_003',
        'applicantName': 'วิชัย ขยัน',
        'email': 'wichai@email.com',
        'phone': '083-456-7890',
        'location': 'ปทุมธานี',
        'position': 'นักพัฒนา Flutter',
        'experience': 1,
        'skills': ['Flutter', 'Dart', 'Git'],
        'status': 'rejected',
        'appliedDate': '1 วันที่แล้ว',
        'hasCV': true,
      },
      {
        'id': '4',
        'applicantId': 'user_004',
        'applicantName': 'นารี สวยงาม',
        'email': 'naree@email.com',
        'phone': '084-567-8901',
        'location': 'กรุงเทพฯ',
        'position': 'Frontend Developer',
        'experience': 4,
        'skills': ['React', 'Vue.js', 'TypeScript', 'CSS'],
        'status': 'interviewed',
        'appliedDate': '3 วันที่แล้ว',
        'hasCV': true,
      },
    ];

    switch (status) {
      case 'pending':
        return allApplications.where((app) => app['status'] == 'pending').toList();
      case 'approved':
        return allApplications.where((app) => app['status'] == 'approved').toList();
      case 'rejected':
        return allApplications.where((app) => app['status'] == 'rejected').toList();
      case 'interviewed':
        return allApplications.where((app) => app['status'] == 'interviewed').toList();
      default:
        return allApplications;
    }
  }
}