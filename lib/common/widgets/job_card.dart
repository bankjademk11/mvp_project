import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';
import 'bookmark_button.dart';
import 'company_logo_widget.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  String _formatSalary(int? min, int? max, String languageCode) {
    if (min == null && max == null) {
      return AppLocalizations.translate('salary_negotiable', languageCode);
    }
    
    final formatCurrency = NumberFormat('#,##0', 'lo');
    
    if (min != null && max != null) {
      return '${formatCurrency.format(min)} - ${formatCurrency.format(max)} ${AppLocalizations.translate('lao_currency', languageCode)}';
    }
    
    if (min != null) {
      return '${AppLocalizations.translate('from', languageCode)} ${formatCurrency.format(min)} ${AppLocalizations.translate('lao_currency', languageCode)}';
    }
    
    if (max != null) {
      return '${AppLocalizations.translate('up_to', languageCode)} ${formatCurrency.format(max)} ${AppLocalizations.translate('lao_currency', languageCode)}';
    }
    
    return AppLocalizations.translate('salary_negotiable', languageCode);
  }

  String _formatDate(String? dateStr, String languageCode) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      
      if (diff == 0) return AppLocalizations.translate('today', languageCode);
      if (diff == 1) return AppLocalizations.translate('yesterday', languageCode);
      if (diff < 7) return '$diff ${AppLocalizations.translate('days_ago', languageCode)}';
      if (diff < 30) return '${(diff / 7).floor()} ${AppLocalizations.translate('weeks_ago', languageCode)}';
      return '${(diff / 30).floor()} ${AppLocalizations.translate('months_ago', languageCode)}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'lo';
    
    final title = job['title'] ?? '';
    final company = job['companyName'] ?? '';
    final province = job['province'] ?? '';
    final type = job['type'] ?? 'Full-time';
    final tags = (job['tags'] as List?)?.cast<String>() ?? [];
    // Ensure proper null safety for salary fields
    final salaryMin = job['salaryMin'] != null 
        ? (job['salaryMin'] is int 
            ? job['salaryMin'] as int 
            : job['salaryMin'] is double 
                ? (job['salaryMin'] as double).toInt() 
                : null)
        : null;
    final salaryMax = job['salaryMax'] != null
        ? (job['salaryMax'] is int 
            ? job['salaryMax'] as int 
            : job['salaryMax'] is double 
                ? (job['salaryMax'] as double).toInt() 
                : null)
        : null;
    final salaryText = _formatSalary(salaryMin, salaryMax, languageCode);
    final dateText = _formatDate(job['createdAt'], languageCode);
    final companyLogoUrl = job['companyLogoUrl'] as String?;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo
                    CompanyLogoWidget(
                      logoUrl: companyLogoUrl,
                      companyName: company,
                      size: 48,
                      borderRadius: 12,
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
