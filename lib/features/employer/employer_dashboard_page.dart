import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class EmployerDashboardPage extends ConsumerStatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  ConsumerState<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends ConsumerState<EmployerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    final theme = Theme.of(context);

    // Check if user is authenticated and is an employer
    if (!authState.isAuthenticated || authState.user?.role != 'employer') {
      // Redirect to login if not authenticated or not an employer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('employer_dashboard')),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: t('logout'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t('welcome')}, ${authState.user?.companyName ?? authState.user?.displayName ?? ''}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              t('dashboard_overview_subtitle'),
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(theme, label: t('active_jobs'), value: '5', icon: Icons.work_outline, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(theme, label: t('new_applicants_today'), value: '3', icon: Icons.person_add_alt_1_outlined, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Action Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.add_circle_outline,
                  title: t('post_new_job'),
                  subtitle: t('create_new_job_listing'),
                  onTap: () => context.push('/employer/post-job'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.cases_outlined,
                  title: t('manage_jobs'),
                  subtitle: t('edit_your_job_posts'),
                  onTap: () => context.push('/employer/jobs'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.people_outline,
                  title: t('manage_applications'),
                  subtitle: t('review_job_applications'),
                  onTap: () => context.push('/employer/applications'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.business_outlined,
                  title: t('company_profile'),
                  subtitle: t('update_company_info'),
                  onTap: () => context.push('/company/${authState.user!.uid}'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.analytics_outlined,
                  title: t('analytics'),
                  subtitle: t('view_company_insights'),
                  onTap: () => context.push('/employer/analytics'),
                ),
                 _buildDashboardCard(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: t('messages'),
                  subtitle: t('communicate_with_candidates'),
                  onTap: () => context.push('/chats'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, {required String label, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
