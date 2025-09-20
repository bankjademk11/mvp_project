import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/language_service.dart';

class EmployerAnalyticsPage extends ConsumerWidget {
  const EmployerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('analytics')),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            t('job_performance'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAnalyticsCard(
                context: context,
                icon: Icons.visibility,
                value: '1,234',
                label: t('total_views'),
                color: theme.colorScheme.primary, // Updated from Colors.blue
              ),
              _buildAnalyticsCard(
                context: context,
                icon: Icons.description,
                value: '56',
                label: t('total_applications'),
                color: Colors.orange,
              ),
              _buildAnalyticsCard(
                context: context,
                icon: Icons.rate_review,
                value: '4.5%',
                label: t('conversion_rate'),
                color: Colors.green,
              ),
              _buildAnalyticsCard(
                context: context,
                icon: Icons.work,
                value: '5',
                label: t('active_jobs'),
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t('applicant_stats'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatListItem(
            context: context,
            icon: Icons.pending_actions,
            label: t('pending_review'),
            value: '12',
          ),
          _buildStatListItem(
            context: context,
            icon: Icons.check_circle_outline,
            label: t('shortlisted'),
            value: '8',
          ),
          _buildStatListItem(
            context: context,
            icon: Icons.cancel_outlined,
            label: t('rejected_applications'),
            value: '36',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatListItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        title: Text(label, style: theme.textTheme.titleMedium),
        trailing: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
