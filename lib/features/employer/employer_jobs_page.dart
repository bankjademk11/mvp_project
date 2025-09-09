import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/job_service.dart';
import '../../services/auth_service.dart';
import '../../common/widgets/job_card.dart';
import '../../services/language_service.dart';

class EmployerJobsPage extends ConsumerStatefulWidget {
  const EmployerJobsPage({super.key});

  @override
  ConsumerState<EmployerJobsPage> createState() => _EmployerJobsPageState();
}

class _EmployerJobsPageState extends ConsumerState<EmployerJobsPage> {
  late Future<List> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    final authState = ref.read(authProvider);
    final jobService = ref.read(JobService.jobServiceProvider);
    
    if (authState.user != null) {
      // Debug: Print user information
      print('Current user information:');
      print('- UID: ${authState.user!.uid}');
      print('- Display Name: ${authState.user!.displayName}');
      print('- Company Name: ${authState.user!.companyName}');
      print('- Role: ${authState.user!.role}');
      
      // First try using getJobsByCompanyId
      _jobsFuture = jobService.getJobsByCompanyId(authState.user!.uid).catchError((error) {
        print('Error in getJobsByCompanyId: $error');
        // If getJobsByCompanyId fails, try the manual filtering approach
        print('getJobsByCompanyId failed, trying manual filtering...');
        return jobService.getJobs().then((allJobs) {
          // Debug: Print all jobs data
          print('Total jobs fetched: ${allJobs.length}');
          for (var job in allJobs) {
            print('Job ID: ${job.$id}');
            print('- Title: ${job.data['title']}');
            print('- Company ID: ${job.data['companyId']}');
            print('- Company Name: ${job.data['companyName']}');
            print('---');
          }
          
          // กรองเฉพาะงานที่มี companyId ตรงกับ UID ของผู้ใช้
          final filteredJobs = allJobs.where((job) => job.data['companyId'] == authState.user!.uid).toList();
          print('Filtered jobs count: ${filteredJobs.length}');
          return filteredJobs as List;
        }).catchError((error2) {
          print('Error in fallback approach: $error2');
          return [] as List;
        });
      }) as Future<List>;
    } else {
      print('No user logged in');
      _jobsFuture = Future.value([]) as Future<List>;
    }
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('my_jobs')),
        actions: [
          IconButton(
            onPressed: () => context.push('/employer/post-job'),
            icon: const Icon(Icons.add),
            tooltip: t('post_new_job'),
          ),
        ],
      ),
      body: FutureBuilder<List>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Debug: Print error
            print('Snapshot error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${t('error')}: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshJobs,
                    child: Text(t('retry')),
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('no_jobs_posted'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('post_your_first_job'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/employer/post-job'),
                    icon: const Icon(Icons.add),
                    label: Text(t('post_new_job')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(
                  job: {
                    'id': job.$id,
                    'title': job.data['title'] ?? '',
                    'companyName': job.data['companyName'] ?? '',
                    'province': job.data['province'] ?? '',
                    'type': job.data['type'] ?? '',
                    'tags': List<String>.from(job.data['tags'] ?? []),
                    'salaryMin': job.data['salaryMin'],
                    'salaryMax': job.data['salaryMax'],
                    'createdAt': job.data['createdAt'],
                  },
                  onTap: () {
                    // นำทางไปหน้ารายละเอียดงาน
                    context.push('/employer/job/${job.$id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}