import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';
import 'bookmark_button.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  String _formatSalary(dynamic min, dynamic max, String languageCode) {
    if (min == null || max == null) return AppLocalizations.translate('negotiable', languageCode);
    
    final formatter = NumberFormat('#,###');
    final minStr = formatter.format(min / 1000000); // Convert to millions
    final maxStr = formatter.format(max / 1000000);
    
    return '${minStr}M - ${maxStr}M ${AppLocalizations.translate('lao_currency', languageCode)}';
  }

  String _formatDate(String? dateStr, String languageCode) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      
      if (diff == 0) return AppLocalizations.translate('today', languageCode);
      if (diff == 1) return AppLocalizations.translate('yesterday', languageCode);
      if (diff < 7) return '${AppLocalizations.translate('days_ago', languageCode)} $diff';
      if (diff < 30) return '${(diff / 7).floor()} ${AppLocalizations.translate('weeks_ago', languageCode)}';
      return '${(diff / 30).floor()} ${AppLocalizations.translate('months_ago', languageCode)}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get language code from context or default to Lao
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'lo';
    
    final title = job['title'] ?? '';
    final company = job['companyName'] ?? '';
    final province = job['province'] ?? '';
    final type = job['type'] ?? 'Full-time';
    final tags = (job['tags'] as List?)?.cast<String>() ?? [];
    final salaryText = _formatSalary(job['salaryMin'], job['salaryMax'], languageCode);
    final dateText = _formatDate(job['createdAt'], languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with company logo and title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company logo placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Job title and company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bookmark button
                    BookmarkIconButton(
                      jobId: job['id'] ?? '',
                      jobData: {
                        'title': title,
                        'companyName': company,
                        'province': province,
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Job details
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      province,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.work_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      type,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Salary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    salaryText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}