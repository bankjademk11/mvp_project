import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/bookmark_service.dart';
import '../../services/language_service.dart';

class BookmarkButton extends ConsumerWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;
  final bool showText;
  final IconData? bookmarkedIcon;
  final IconData? unbookmarkedIcon;

  const BookmarkButton({
    super.key,
    required this.jobId,
    this.jobData,
    this.showText = false,
    this.bookmarkedIcon = Icons.bookmark,
    this.unbookmarkedIcon = Icons.bookmark_border,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkServiceProvider);
    final languageState = ref.watch(languageProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
    
    final isBookmarked = bookmarkState.isBookmarked(jobId);

    if (showText) {
      return FilledButton.tonalIcon(
        onPressed: () => _toggleBookmark(ref),
        icon: Icon(
          isBookmarked ? bookmarkedIcon : unbookmarkedIcon,
          size: 20,
        ),
        label: Text(
          isBookmarked ? t('bookmarked') : t('bookmark'),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isBookmarked 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
          foregroundColor: isBookmarked 
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      );
    }

    return IconButton(
      onPressed: () => _toggleBookmark(ref),
      icon: Icon(
        isBookmarked ? bookmarkedIcon : unbookmarkedIcon,
        color: isBookmarked 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      tooltip: isBookmarked ? t('remove_bookmark') : t('add_bookmark'),
    );
  }

  void _toggleBookmark(WidgetRef ref) {
    ref.read(bookmarkServiceProvider.notifier).toggleBookmark(jobId, jobData);
  }
}

class BookmarkIconButton extends ConsumerWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;
  final double size;
  final Color? color;

  const BookmarkIconButton({
    super.key,
    required this.jobId,
    this.jobData,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkServiceProvider);
    final isBookmarked = bookmarkState.isBookmarked(jobId);

    return GestureDetector(
      onTap: () {
        ref.read(bookmarkServiceProvider.notifier).toggleBookmark(jobId, jobData);
        
        // แสดง feedback
        final languageState = ref.read(languageProvider);
        final message = isBookmarked 
            ? AppLocalizations.translate('bookmark_removed', languageState.languageCode)
            : AppLocalizations.translate('job_bookmarked', languageState.languageCode);
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isBookmarked),
          size: size,
          color: color ?? (isBookmarked 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ),
    );
  }
}