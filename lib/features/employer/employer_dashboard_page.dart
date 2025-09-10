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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t('welcome')}, ${authState.user?.companyName ?? authState.user?.displayName ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.add,
                    title: t('post_new_job'),
                    subtitle: t('post_and_manage_jobs'),
                    onTap: () => context.push('/employer/post-job'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.work,
                    title: t('manage_jobs'),
                    subtitle: t('post_and_manage_jobs'),
                    onTap: () => context.push('/employer/jobs'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.people,
                    title: t('manage_applications'),
                    subtitle: t('review_job_applications'),
                    onTap: () => context.push('/employer/applications'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.business,
                    title: t('company_profile'),
                    subtitle: t('update_company_info'),
                    onTap: () => context.push('/company/${authState.user!.uid}'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.analytics,
                    title: t('analytics'),
                    subtitle: t('view_company_insights'),
                    onTap: () => context.push('/employer/analytics'),
                  ),
                ],
              ),
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
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
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
