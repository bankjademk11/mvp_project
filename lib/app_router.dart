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
import 'features/employer/application_detail_page.dart';
import 'features/main/main_layout.dart';
import 'features/bookmarks/bookmarks_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/company/company_profile_page.dart';
import 'features/employer/setup_company_page.dart';
import 'features/employer/analytics_page.dart';
import 'services/auth_service.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.uri.path == '/splash' || 
                         state.uri.path == '/onboarding' || 
                         state.uri.path == '/login' || 
                         state.uri.path == '/register';
      final isSetupCompanyRoute = state.uri.path == '/employer/setup-company';
      
      print('Debug GoRouter - Path: ${state.uri.path}, Authenticated: $isAuthenticated, Role: ${user?.role}, Loading: $isLoading');
      
      // If still loading user data, don't redirect yet
      if (isLoading) {
        print('Debug GoRouter - Still loading user data, no redirect needed');
        return null;
      }
      
      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute) {
        print('Debug GoRouter - Not authenticated, redirecting to login');
        return '/login';
      }
      
      // If authenticated and on auth routes, redirect based on role
      if (isAuthenticated && isAuthRoute) {
        if (user?.role == 'employer') {
          // Check if user data is fully loaded (not just basic auth info)
          // A user with company info should have at least companyName and companyDescription
          final hasCompanyInfo = user?.companyName?.isNotEmpty == true && 
                                user?.companyDescription?.isNotEmpty == true;
          
          print('Debug GoRouter - Employer hasCompanyInfo: $hasCompanyInfo, companyName: ${user?.companyName}, companyDescription: ${user?.companyDescription}');
          
          // If user doesn't have company info and not on setup page, redirect to setup
          if (!hasCompanyInfo && !isSetupCompanyRoute) {
            print('Debug GoRouter - Employer missing company info, redirecting to setup');
            return '/employer/setup-company';
          } 
          // If user has company info and is on setup page, redirect to dashboard
          else if (hasCompanyInfo && isSetupCompanyRoute) {
            print('Debug GoRouter - Employer already has company info, redirecting to dashboard');
            return '/employer/dashboard';
          }
          // If user has company info and not on setup page, go to dashboard
          else if (hasCompanyInfo) {
            print('Debug GoRouter - Employer has company info, redirecting to dashboard');
            return '/employer/dashboard';
          }
          // If user doesn't have company info and is on setup page, stay on setup page
          else {
            print('Debug GoRouter - Employer on setup page, no redirect needed');
            return null;
          }
        } else {
          print('Debug GoRouter - Authenticated seeker, redirecting to jobs');
          return '/jobs';
        }
      }
      
      // Special handling for employer routes
      if (isAuthenticated && user?.role != 'employer' && 
          (state.uri.path.startsWith('/employer/') || state.uri.path == '/employer')) {
        print('Debug GoRouter - Non-employer trying to access employer routes, redirecting to jobs');
        return '/jobs'; // Redirect non-employers from employer routes
      }
      
      // Check if employer has company info when accessing employer routes
      if (isAuthenticated && user?.role == 'employer' && 
          state.uri.path.startsWith('/employer/') && 
          state.uri.path != '/employer/setup-company') {
        final hasCompanyInfo = user?.companyName?.isNotEmpty == true && 
                              user?.companyDescription?.isNotEmpty == true;
        
        if (!hasCompanyInfo) {
          print('Debug GoRouter - Employer missing company info, redirecting to setup');
          return '/employer/setup-company';
        }
      }
      
      print('Debug GoRouter - No redirect needed');
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
          // Add route for application detail page
          GoRoute(
            path: '/employer/application/:id',
            builder: (c, s) => ApplicationDetailPage(
              applicationId: s.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/employer/post-job',
            builder: (_, __) => const PostJobPage(),
          ),
          GoRoute(
            path: '/employer/job/:id',
            builder: (c, s) => JobDetailPage(jobId: s.pathParameters['id']!),
          ),
          // New route for analytics
          GoRoute(
            path: '/employer/analytics',
            builder: (_, __) => const EmployerAnalyticsPage(),
          ),
        ],
      ),
      // New route for setting up company information (moved outside ShellRoute)
      GoRoute(
        path: '/employer/setup-company',
        builder: (_, __) => const SetupCompanyPage(),
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
        builder: (c, s) => ChatRoomPage(
          chatId: s.pathParameters['id']!,
          otherUserId: s.uri.queryParameters['otherUserId']!,
        ),
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
      builder: (c, s) => ChatRoomPage(
        chatId: s.pathParameters['id']!,
        otherUserId: s.uri.queryParameters['otherUserId']!,
      ),
    ),
    GoRoute(
      path: '/company/:id',
      builder: (c, s) => CompanyProfilePage(companyId: s.pathParameters['id']!),
    ),
  ],
);