import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// TODO: Add share_plus package to pubspec.yaml for this feature to work
import 'package:share_plus/share_plus.dart';
import '../../services/bookmark_service.dart';
import '../../services/language_service.dart';
import '../../models/bookmark.dart'; // Add import
import '../../common/widgets/job_card.dart';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลบุ๊คมาร์คเมื่อเปิดหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkServiceProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkServiceProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('bookmarked_jobs')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (bookmarkState.bookmarks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.clear_all, size: 20),
                      const SizedBox(width: 8),
                      Text(t('clear_all')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookmarkServiceProvider.notifier).refresh();
        },
        child: _buildBody(bookmarkState, t),
      ),
    );
  }

  Widget _buildBody(bookmarkState, Function t) {
    if (bookmarkState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (bookmarkState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              bookmarkState.error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(bookmarkServiceProvider.notifier).refresh();
              },
              child: Text(t('try_again')),
            ),
          ],
        ),
      );
    }

    if (bookmarkState.bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              t('no_bookmarks'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('no_bookmarks_desc'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.go('/jobs');
              },
              icon: const Icon(Icons.search),
              label: Text(t('find_jobs')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarkState.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarkState.bookmarks[index];
        return _buildBookmarkItem(bookmark, t);
      },
    );
  }

  Widget _buildBookmarkItem(bookmark, Function t) {
    final jobData = bookmark.jobData;
    
    if (jobData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(t('job_not_found')),
            subtitle: Text(t('job_not_found_message')),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeBookmark(bookmark),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            context.push('/jobs/${bookmark.jobId}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobData['title'] ?? t('unknown_job'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jobData['companyName'] ?? t('unknown_company'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                jobData['province'] ?? t('unknown_location'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.bookmark,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _removeBookmark(bookmark),
                      tooltip: t('remove_bookmark'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t('bookmarked_on')} ${_formatDate(bookmark.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            context.push('/jobs/${bookmark.jobId}');
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: Text(t('view_job')),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () => _shareJob(bookmark),
                          tooltip: t('share_job'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeBookmark(Bookmark bookmark) {
    // Immediately remove the bookmark from the service
    ref.read(bookmarkServiceProvider.notifier).removeBookmark(bookmark.id);

    // Show a snackbar with an undo action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.translate('bookmark_removed', 
            ref.read(languageProvider).languageCode)),
        action: SnackBarAction(
          label: AppLocalizations.translate('undo', 
              ref.read(languageProvider).languageCode),
          onPressed: () {
            // If undo is pressed, add the bookmark back
            ref.read(bookmarkServiceProvider.notifier).addBookmark(bookmark.jobId, bookmark.jobData);
          },
        ),
      ),
    );
  }

  void _shareJob(Bookmark bookmark) {
    final jobData = bookmark.jobData;
    if (jobData == null) return;

    final title = jobData['title'] ?? '';
    final companyName = jobData['companyName'] ?? '';
    // Note: Replace 'yourapp.com' with your actual app domain for deep linking
    final jobUrl = 'https://yourapp.com/jobs/${bookmark.jobId}';
    final shareText = '$title at $companyName\n\nFind out more: $jobUrl';

    Share.share(shareText);
  }

  void _showClearAllDialog() {
    final t = (key) => AppLocalizations.translate(key, ref.read(languageProvider).languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('clear_all_bookmarks')),
        content: Text(t('clear_all_bookmarks_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              ref.read(bookmarkServiceProvider.notifier).clearAllBookmarks();
              Navigator.pop(context);
            },
            child: Text(t('clear_all')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return AppLocalizations.translate('today', ref.read(languageProvider).languageCode);
    } else if (difference.inDays == 1) {
      return AppLocalizations.translate('yesterday', ref.read(languageProvider).languageCode);
    } else {
      return '${difference.inDays} ${AppLocalizations.translate('days_ago', ref.read(languageProvider).languageCode)}';
    }
  }
}