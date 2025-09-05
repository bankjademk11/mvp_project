import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';

class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ແດດບອດນາຍຈ້າງ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ສະຖິຕິລວມ
            _buildStatsSection(context),
            const SizedBox(height: 24),
            
            // ເມນູຫລັກ
            _buildMainMenuSection(context),
            const SizedBox(height: 24),
            
            // ງານລ່າສຸດ
            _buildRecentJobsSection(context),
            const SizedBox(height: 24),
            
            // ຜູ້ສະມັກລ່າສຸດ
            _buildRecentApplicationsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ສະຖິຕິລວມ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'ງານທີ່ເປີດຮັບ',
                    '5',
                    Icons.work_outline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'ຜູ້ສະມັກໃໝ່',
                    '23',
                    Icons.person_add_outlined,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'ຜູ້ສະມັກທັງໝົດ',
                    '89',
                    Icons.group_outlined,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'ການແຈ້ງເຕືອນ',
                    '7',
                    Icons.notifications_outlined,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_outlined, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ເມນູຫລັກ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildMenuCard(
                  context,
                  'ປະກາດງານໃໝ່',
                  Icons.add_business_outlined,
                  Colors.blue,
                  () => context.push('/post-job'),
                ),
                _buildMenuCard(
                  context,
                  'ຈັດການງານ',
                  Icons.work_history_outlined,
                  Colors.green,
                  () => context.push('/employer/jobs'),
                ),
                _buildMenuCard(
                  context,
                  'ຜູ້ສະມັກງານ',
                  Icons.people_outlined,
                  Colors.orange,
                  () => context.push('/employer/applications'),
                ),
                _buildMenuCard(
                  context,
                  'ແຊດກັບຜູ້ສະມັກ',
                  Icons.chat_bubble_outline,
                  Colors.purple,
                  () => context.push('/chats'),
                ),
                _buildMenuCard(
                  context,
                  'ຂໍ້ມູນບໍລິສັດ',
                  Icons.business_outlined,
                  Colors.teal,
                  () => context.push('/employer/company'),
                ),
                _buildMenuCard(
                  context,
                  'ລາຍງານ',
                  Icons.analytics_outlined,
                  Colors.indigo,
                  () => context.push('/employer/reports'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsSection(BuildContext context) {
    return Card(
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
                Row(
                  children: [
                    Icon(Icons.work_outline, 
                         color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ງານລ່າສຸດ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/employer/jobs'),
                  child: const Text('ເບິ່ງທັງໝົດ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildJobListItem(
              context,
              'ນັກພັດທະນາ Flutter',
              'ເປີດຮັບສະມັກ',
              '15 ຜູ້ສະມັກ',
              Colors.green,
            ),
            _buildJobListItem(
              context,
              'UI/UX Designer',
              'ເປີດຮັບສະມັກ',
              '8 ຜູ້ສະມັກ',
              Colors.green,
            ),
            _buildJobListItem(
              context,
              'Project Manager',
              'ປິດຮັບສະມັກ',
              '25 ຜູ້ສະມັກ',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListItem(
    BuildContext context,
    String title,
    String status,
    String applicants,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.work_outline, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      applicants,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildRecentApplicationsSection(BuildContext context) {
    return Card(
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
                Row(
                  children: [
                    Icon(Icons.people_outline, 
                         color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ຜູ້ສະມັກລ່າສຸດ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/employer/applications'),
                  child: const Text('ເບິ່ງທັງໝົດ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildApplicationListItem(
              context,
              'ສົມໄຊ ໃຈດີ',
              'ນັກພັດທະນາ Flutter',
              '2 ຊົ່ວໂມງທີ່ແລ້ວ',
              Colors.blue,
            ),
            _buildApplicationListItem(
              context,
              'ສົມຍິງ ຮັກງານ',
              'UI/UX Designer',
              '5 ຊົ່ວໂມງທີ່ແລ້ວ',
              Colors.blue,
            ),
            _buildApplicationListItem(
              context,
              'ວິໄຊ ຂະຍັນ',
              'ນັກພັດທະນາ Flutter',
              '1 ມື້ທີ່ແລ້ວ',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationListItem(
    BuildContext context,
    String name,
    String position,
    String time,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              name.substring(0, 1),
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // เพิ่มปุ่มสำหรับแชทกับผู้สมัคร
          IconButton(
            onPressed: () => context.push('/chats/applicant_${name.hashCode}'),
            icon: Icon(Icons.chat_bubble_outline, color: color),
            tooltip: 'ແຊດກັບຜູ້ສະມັກ',
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}