import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployerJobsPage extends ConsumerStatefulWidget {
  const EmployerJobsPage({super.key});

  @override
  ConsumerState<EmployerJobsPage> createState() => _EmployerJobsPageState();
}

class _EmployerJobsPageState extends ConsumerState<EmployerJobsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('ຈັດການງານ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ເປີດຮັບສະມັກ'),
            Tab(text: 'ປິດຮັບສະມັກ'),
            Tab(text: 'ທັງໝົດ'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/post-job'),
            icon: const Icon(Icons.add),
            tooltip: 'ປະກາດງານໃໝ່',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobList(context, 'active'),
          _buildJobList(context, 'closed'),
          _buildJobList(context, 'all'),
        ],
      ),
    );
  }

  Widget _buildJobList(BuildContext context, String type) {
    final jobs = _getMockJobs(type);
    
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobCard(context, job);
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job['title'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, value, job),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('ແກ້ໄຂ'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'applications',
                      child: Row(
                        children: [
                          Icon(Icons.people_outlined),
                          SizedBox(width: 8),
                          Text('ຜູ້ສະມັກ'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: job['status'] == 'active' ? 'close' : 'reopen',
                      child: Row(
                        children: [
                          Icon(job['status'] == 'active' 
                              ? Icons.close 
                              : Icons.refresh_outlined),
                          const SizedBox(width: 8),
                          Text(job['status'] == 'active' ? 'ປິດງານ' : 'ເປີດໃໝ່'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ລົບ', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ລາຍລະອຽດງານ
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on_outlined, 
                       size: 16, 
                       color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  job['location'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.access_time_outlined, 
                       size: 16, 
                       color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  job['type'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.monetization_on_outlined, 
                       size: 16, 
                       color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  job['salary'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ສະຖິຕິ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatChip(
                      '${job['applications']} ຜູ້ສະມັກ',
                      Colors.blue,
                      Icons.people_outline,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      '${job['views']} ຄົນເບິ່ງ',
                      Colors.green,
                      Icons.visibility_outlined,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: job['status'] == 'active' 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: job['status'] == 'active' ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        job['status'] == 'active' ? Icons.check_circle : Icons.pause_circle,
                        color: job['status'] == 'active' ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job['status'] == 'active' ? 'ເປີດຮັບສະມັກ' : 'ປິດຮັບສະມັກ',
                        style: TextStyle(
                          color: job['status'] == 'active' ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'ປະກາດເມື່ອ: ${job['postedDate']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // ປຸ່ມແຊດກັບຜູ້ສະມັກ
                    IconButton(
                      onPressed: () => context.push('/chats'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'ແຊດກັບຜູ້ສະມັກ',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ປຸ່ມເບິ່ງຜູ້ສະມັກ
                    ElevatedButton.icon(
                      onPressed: () => context.push('/employer/applications?jobId=${job['id']}'),
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: Text('ເບິ່ງຜູ້ສະມັກ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        foregroundColor: Colors.blue,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context, 
    String action, 
    Map<String, dynamic> job,
  ) {
    switch (action) {
      case 'edit':
        context.push('/post-job?edit=${job['id']}');
        break;
      case 'applications':
        context.push('/employer/applications?jobId=${job['id']}');
        break;
      case 'close':
        _showCloseJobDialog(context, job);
        break;
      case 'reopen':
        _showReopenJobDialog(context, job);
        break;
      case 'delete':
        _showDeleteJobDialog(context, job);
        break;
    }
  }

  void _showCloseJobDialog(BuildContext context, Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ປິດງານ'),
        content: Text('ທ່ານຕ້ອງການປິດຮັບສະໝັກງານ "${job['title']}" ຫຼືບໍ່?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ປິດງານເລຍບຮ້ອຍແລ້ວ')),
              );
            },
            child: const Text('ປິດງານ'),
          ),
        ],
      ),
    );
  }

  void _showReopenJobDialog(BuildContext context, Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ເປີດງານໃໝ່'),
        content: Text('ທ່ານຕ້ອງການເປີດຮັບສະໝັກງານ "${job['title']}" ໃໝ່ຫຼືບໍ່?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ເປີດງານໃໝ່ເລຍບຮ້ອຍແລ້ວ')),
              );
            },
            child: const Text('ເປີດໃໝ່'),
          ),
        ],
      ),
    );
  }

  void _showDeleteJobDialog(BuildContext context, Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ລົບງານ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ທ່ານຕ້ອງການລົບງານ "${job['title']}" ຫຼືບໍ່?'),
            const SizedBox(height: 8),
            const Text(
              'ການລົບງານຈະເຮັດໃຫ້ຂໍ້ມູນທັງໝົດຫາຍໄປ ແລະບໍ່ສາມາດກັບຄືນໄດ້',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ລົບງານເລຍບຮ້ອຍແລ້ວ')),
              );
            },
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockJobs(String type) {
    final allJobs = [
      {
        'id': '1',
        'title': 'ນักพัฒนา Flutter',
        'location': 'กรุงเทพฯ',
        'type': 'เต็มเวลา',
        'salary': '25,000 - 45,000 บาท',
        'applications': 15,
        'views': 128,
        'status': 'active',
        'postedDate': '2 วันที่แล้ว',
      },
      {
        'id': '2',
        'title': 'UI/UX Designer',
        'location': 'กรุงเทพฯ',
        'type': 'เต็มเวลา',
        'salary': '20,000 - 35,000 บาท',
        'applications': 8,
        'views': 89,
        'status': 'active',
        'postedDate': '5 วันที่แล้ว',
      },
      {
        'id': '3',
        'title': 'Project Manager',
        'location': 'กรุงเทพฯ',
        'type': 'เต็มเวลา',
        'salary': '35,000 - 55,000 บาท',
        'applications': 25,
        'views': 256,
        'status': 'closed',
        'postedDate': '2 สัปดาห์ที่แล้ว',
      },
      {
        'id': '4',
        'title': 'Frontend Developer',
        'location': 'ปทุมธานี',
        'type': 'เต็มเวลา',
        'salary': '22,000 - 40,000 บาท',
        'applications': 12,
        'views': 95,
        'status': 'active',
        'postedDate': '1 สัปดาห์ที่แล้ว',
      },
      {
        'id': '5',
        'title': 'Marketing Coordinator',
        'location': 'กรุงเทพฯ',
        'type': 'พาร์ทไทม์',
        'salary': '15,000 - 25,000 บาท',
        'applications': 6,
        'views': 47,
        'status': 'closed',
        'postedDate': '3 สัปดาห์ที่แล้ว',
      },
    ];

    switch (type) {
      case 'active':
        return allJobs.where((job) => job['status'] == 'active').toList();
      case 'closed':
        return allJobs.where((job) => job['status'] == 'closed').toList();
      default:
        return allJobs;
    }
  }
}