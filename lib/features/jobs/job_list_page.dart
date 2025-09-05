import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/mock_api.dart';
import '../../common/widgets/search_bar.dart';
import '../../common/widgets/job_card.dart';
import '../../common/widgets/notification_badge.dart';
import '../../services/language_service.dart';

final jobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final items = await MockApi.loadJobs();
  return items.cast<Map<String, dynamic>>();
});

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
    final jobsAsync = ref.watch(jobsProvider);
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
              child: jobsAsync.when(
                data: (jobs) {
                  final filtered = jobs.where((j) {
                    if (_keyword.isEmpty) return true;
                    final hay = (j['title'].toString() + ' ' + j['companyName'].toString() + ' ' + j['province'].toString()).toLowerCase();
                    return hay.contains(_keyword);
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text(t('no_jobs_found')));
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final job = filtered[i];
                      return JobCard(
                        job: job,
                        onTap: () => context.push('/jobs/${job['id']}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}