import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/jobs/job_list_page.dart';
import 'features/jobs/job_detail_page.dart';
import 'features/jobs/job_filters.dart';
import 'features/applications/my_applications_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/chat/chat_list_page.dart';
import 'features/chat/chat_room_page.dart';
import 'features/employer/post_job_page.dart';
import 'features/employer/employer_dashboard_page.dart';
import 'features/employer/employer_jobs_page.dart';
import 'features/employer/employer_applications_page.dart';
import 'features/employer/employer_company_page.dart';
import 'features/main/main_layout.dart';
import 'features/bookmarks/bookmarks_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/company/company_profile_page.dart';
import 'services/auth_service.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final isAuthRoute = state.uri.path == '/splash' || 
                         state.uri.path == '/onboarding' || 
                         state.uri.path == '/login' || 
                         state.uri.path == '/register';
      
      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      
      // If authenticated and on auth routes, redirect based on role
      if (isAuthenticated && isAuthRoute) {
        if (user?.role == 'employer') {
          return '/employer/dashboard';
        } else {
          return '/jobs';
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/jobs',
            builder: (_, __) => const JobListPage(),
          ),
          GoRoute(
            path: '/applications',
            builder: (_, __) => const MyApplicationsPage(),
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (_, __) => const BookmarksPage(),
          ),
          GoRoute(
            path: '/chats',
            builder: (_, __) => const ChatListPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsPage(),
          ),
          // Employer routes
          GoRoute(
            path: '/employer/dashboard',
            builder: (_, __) => const EmployerDashboardPage(),
          ),
          GoRoute(
            path: '/employer/jobs',
            builder: (_, __) => const EmployerJobsPage(),
          ),
          GoRoute(
            path: '/employer/applications',
            builder: (c, s) => EmployerApplicationsPage(
              jobId: s.uri.queryParameters['jobId'],
            ),
          ),
          GoRoute(
            path: '/employer/company',
            builder: (_, __) => const EmployerCompanyPage(),
          ),
          GoRoute(
            path: '/employer/post-job',
            builder: (_, __) => const PostJobPage(),
          ),
          GoRoute(
            path: '/employer/job/:id',
            builder: (c, s) => JobDetailPage(jobId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (c, s) => JobDetailPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/filters',
        builder: (_, __) => const JobFiltersPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (c, s) => ChatRoomPage(chatId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/company/:id',
        builder: (c, s) => CompanyProfilePage(companyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post-job',
        builder: (_, __) => const PostJobPage(),
      ),
    ],
  );
});

// For backward compatibility
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/jobs',
          builder: (_, __) => const JobListPage(),
        ),
        GoRoute(
          path: '/applications',
          builder: (_, __) => const MyApplicationsPage(),
        ),
        GoRoute(
          path: '/chats',
          builder: (_, __) => const ChatListPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: '/bookmarks',
          builder: (_, __) => const BookmarksPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/jobs/:id',
      builder: (c, s) => JobDetailPage(jobId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/filters',
      builder: (_, __) => const JobFiltersPage(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (_, __) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/chats/:id',
      builder: (c, s) => ChatRoomPage(chatId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/company/:id',
      builder: (c, s) => CompanyProfilePage(companyId: s.pathParameters['id']!),
    ),
  ],
);