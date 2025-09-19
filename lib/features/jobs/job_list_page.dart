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

// Provider to fetch all jobs once
final allJobsProvider = FutureProvider<List<Document>>((ref) {
  final jobService = ref.watch(JobService.jobServiceProvider);
  return jobService.getJobs();
});

// Provider to apply filters to the job list
final filteredJobsProvider = Provider<List<Document>>((ref) {
  final allJobs = ref.watch(allJobsProvider).asData?.value ?? [];
  final filters = ref.watch(jobFiltersProvider);
  final languageCode = ref.watch(languageProvider).languageCode;

  if (allJobs.isEmpty) return [];

  return allJobs.where((job) {
    final data = job.data;
    final title = (data['title'] as String? ?? '').toLowerCase();
    final companyName = (data['companyName'] as String? ?? '').toLowerCase();
    final province = data['province'] as String? ?? '';
    final type = data['type'] as String? ?? '';

    // Keyword filter (searches title and company name)
    if (filters.keyword != null && filters.keyword!.isNotEmpty) {
      final keyword = filters.keyword!.toLowerCase();
      if (!title.contains(keyword) && !companyName.contains(keyword)) {
        return false;
      }
    }

    // Province filter
    if (filters.provinceKey != null && filters.provinceKey!.isNotEmpty) {
      final translatedProvince = AppLocalizations.translate(filters.provinceKey!, languageCode);
      if (province != translatedProvince) {
        return false;
      }
    }

    // Job type filter
    if (filters.jobTypeKey != null && filters.jobTypeKey!.isNotEmpty) {
      final translatedJobType = AppLocalizations.translate(filters.jobTypeKey!, languageCode);
      if (type != translatedJobType) {
        return false;
      }
    }

    return true;
  }).toList();
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
    // Initialize the controller with the current filter keyword
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
    final filteredJobs = ref.watch(filteredJobsProvider);
    final allJobsState = ref.watch(allJobsProvider);

    // Listen to filter changes to update the search bar text if needed
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchBarField(
              controller: _searchController, // Pass the controller
              onFilter: () => context.push('/filters'),
              onChanged: (v) => ref.read(jobFiltersProvider.notifier).update((state) => state.copyWith(keyword: v)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: allJobsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (allJobs) {
                  if (allJobs.isEmpty) {
                    return Center(child: Text(t('no_jobs_found')));
                  }
                  if (filteredJobs.isEmpty) {
                    return Center(child: Text(t('no_jobs_match_filters')));
                  }
                  return ListView.builder(
                    itemCount: filteredJobs.length,
                    itemBuilder: (_, i) {
                      final job = filteredJobs[i];
                      // Handle potential null or incorrect type values for salary fields with improved null safety
                      final salaryMinValue = job.data['salaryMin'] != null
                          ? (job.data['salaryMin'] is int 
                              ? job.data['salaryMin'] as int 
                              : job.data['salaryMin'] is double 
                                  ? (job.data['salaryMin'] as double).toInt() 
                                  : null)
                          : null;
                      final salaryMaxValue = job.data['salaryMax'] != null
                          ? (job.data['salaryMax'] is int 
                              ? job.data['salaryMax'] as int 
                              : job.data['salaryMax'] is double 
                                  ? (job.data['salaryMax'] as double).toInt() 
                                  : null)
                          : null;
                      
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
                          'companyLogoUrl': job.data['companyLogoUrl'], // Add companyLogoUrl
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
