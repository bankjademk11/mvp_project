import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/models.dart';
import '../../services/job_service.dart';
import '../../common/widgets/search_bar.dart';
import '../../common/widgets/job_card.dart';
import '../../common/widgets/notification_badge.dart';
import '../../services/language_service.dart';
import 'job_filters.dart';

// New provider that performs server-side filtering
final filteredJobsProvider = FutureProvider<List<Document>>((ref) {
  final jobService = ref.watch(JobService.jobServiceProvider);
  final filters = ref.watch(jobFiltersProvider);
  final languageCode = ref.watch(languageProvider).languageCode;

  // Translate keys to values for the query, as that's what is stored in the DB
  final province = filters.provinceKey != null
      ? AppLocalizations.translate(filters.provinceKey!, languageCode)
      : null;
  final jobType = filters.jobTypeKey != null
      ? AppLocalizations.translate(filters.jobTypeKey!, languageCode)
      : null;

  return jobService.getFilteredJobs(
    keyword: filters.keyword,
    province: province,
    jobType: jobType,
    sortBy: filters.sortBy,
  );
});

class JobListPage extends ConsumerStatefulWidget {
  const JobListPage({super.key});

  @override
  ConsumerState<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends ConsumerState<JobListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(jobFiltersProvider).keyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    final filteredJobsAsyncValue = ref.watch(filteredJobsProvider);

    ref.listen(jobFiltersProvider, (previous, next) {
      if (next.keyword != _searchController.text) {
        _searchController.text = next.keyword ?? '';
      }
    });

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
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(filteredJobsProvider.future),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SearchBarField(
                controller: _searchController,
                onFilter: () => context.push('/filters'),
                onChanged: (value) {
                  ref.read(jobFiltersProvider.notifier).update((state) => state.copyWith(keyword: value));
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredJobsAsyncValue.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return Center(child: Text(t('no_jobs_match_filters')));
                    }
                    return ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (_, i) {
                        final job = jobs[i];
                        final salaryMinValue = job.data['salaryMin'] as int?;
                        final salaryMaxValue = job.data['salaryMax'] as int?;

                        return JobCard(
                          job: {
                            'id': job.$id,
                            'title': job.data['title'] ?? '',
                            'companyName': job.data['companyName'] ?? '',
                            'province': job.data['province'] ?? '',
                            'type': job.data['type'] ?? '',
                            'tags': List<String>.from(job.data['tags'] ?? []),
                            'salaryMin': salaryMinValue,
                            'salaryMax': salaryMaxValue,
                            'createdAt': job.data['createdAt'],
                            'companyLogoUrl': job.data['companyLogoUrl'],
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
      ),
    );
  }
}
