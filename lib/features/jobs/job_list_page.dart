import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/job_service.dart';
import '../../common/widgets/search_bar.dart';
import '../../common/widgets/job_card.dart';
import '../../common/widgets/notification_badge.dart';
import '../../services/language_service.dart';

class JobListPage extends ConsumerStatefulWidget {
  const JobListPage({super.key});

  @override
  ConsumerState<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends ConsumerState<JobListPage> {
  final _search = TextEditingController();
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final jobService = ref.watch(JobService.jobServiceProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t('all_jobs')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => context.push('/bookmarks'),
            icon: const Icon(Icons.bookmark_border),
            tooltip: t('bookmarked_jobs'),
          ),
          const NotificationIcon(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchBarField(
              controller: _search,
              onFilter: () => context.push('/filters'),
              onChanged: (v) => setState(() { _keyword = v.trim().toLowerCase(); }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List>(
                future: _keyword.isEmpty ? jobService.getJobs() : jobService.searchJobs(_keyword),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  final jobs = snapshot.data ?? [];
                  
                  if (jobs.isEmpty) {
                    return Center(child: Text(t('no_jobs_found')));
                  }
                  
                  return ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (_, i) {
                      final job = jobs[i];
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
                        onTap: () => context.push('/jobs/${job.$id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}