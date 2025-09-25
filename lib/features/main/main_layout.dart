import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;
  String? _lastUserEmail;
  String? _lastUserRole;
  int _lastSelectedIndex = -1; // Cache the last selected index
  int _navigationCount = 0; // Track navigation attempts
  DateTime? _lastNavigationTime; // Track last navigation time

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
    final user = authState.user;
    
    // ตรวจสอบว่าเป็นนายจ้างหรือไม่
    final isEmployer = user?.role == 'employer';
    
    // Debug: ตรวจสอบข้อมูลผู้ใช้ (แต่ไม่แสดงบ่อยเกินไป)
    if (user?.email != _lastUserEmail || user?.role != _lastUserRole) {
      _lastUserEmail = user?.email;
      _lastUserRole = user?.role;
      print('Debug MainLayout - User: ${user?.email}, Role: ${user?.role}, IsEmployer: $isEmployer');
    }
    
    // Prevent excessive navigation
    final now = DateTime.now();
    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);
      if (timeSinceLastNav < const Duration(seconds: 1)) {
        _navigationCount++;
        if (_navigationCount > 5) {
          print('Debug MainLayout - Too many navigation attempts, pausing');
          // Reset counter after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            _navigationCount = 0;
          });
        }
      } else {
        _navigationCount = 0; // Reset counter if enough time has passed
      }
    }
    _lastNavigationTime = now;
    
    // เมนูสำหรับนายจ้าง
    final List<NavigationDestination> _employerDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: t('dashboard'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.work_outline),
        selectedIcon: const Icon(Icons.work),
        label: t('manage_jobs'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: t('applicants'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: t('chat'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: t('profile'),
      ),
    ];
    
    // เมนูสำหรับผู้หางาน
    final List<NavigationDestination> _seekerDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.work_outline),
        selectedIcon: const Icon(Icons.work),
        label: t('jobs'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.assignment_outlined),
        selectedIcon: const Icon(Icons.assignment),
        label: t('applied'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.bookmark_outline),
        selectedIcon: const Icon(Icons.bookmark),
        label: t('bookmarks'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: t('chat'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: t('profile'),
      ),
    ];
    
    final destinations = isEmployer ? _employerDestinations : _seekerDestinations;

    final List<String> _employerRoutes = [
      '/employer/dashboard',
      '/employer/jobs', 
      '/employer/applications',
      '/chats',
      '/profile',
    ];
    
    final List<String> _seekerRoutes = [
      '/jobs',
      '/applications', 
      '/bookmarks',
      '/chats',
      '/profile',
    ];
    
    final routes = isEmployer ? _employerRoutes : _seekerRoutes;

    void _onTap(int index) {
      if (index != _selectedIndex) {
        setState(() {
          _selectedIndex = index;
        });
        context.go(routes[index]);
      }
    }

    // Update selected index based on current route (only when needed)
    final location = GoRouterState.of(context).uri.path;
    int newSelectedIndex = _selectedIndex;
    
    if (isEmployer) {
      if (location.startsWith('/employer/dashboard')) {
        newSelectedIndex = 0;
      } else if (location.startsWith('/employer/jobs')) {
        newSelectedIndex = 1;
      } else if (location.startsWith('/employer/applications')) {
        newSelectedIndex = 2;
      } else if (location.startsWith('/chats')) {
        newSelectedIndex = 3;
      } else if (location.startsWith('/profile')) {
        newSelectedIndex = 4;
      }
    } else {
      if (location.startsWith('/jobs')) {
        newSelectedIndex = 0;
      } else if (location.startsWith('/applications')) {
        newSelectedIndex = 1;
      } else if (location.startsWith('/bookmarks')) {
        newSelectedIndex = 2;
      } else if (location.startsWith('/chats')) {
        newSelectedIndex = 3;
      } else if (location.startsWith('/profile')) {
        newSelectedIndex = 4;
      }
    }
    
    // Only update state if index actually changed
    if (newSelectedIndex != _lastSelectedIndex) {
      _lastSelectedIndex = newSelectedIndex;
      if (newSelectedIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = newSelectedIndex;
        });
      }
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTap,
        destinations: destinations,
        elevation: 8,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButton: (isEmployer && _selectedIndex == 1) ? FloatingActionButton.extended(
        onPressed: () => context.push('/employer/post-job'), // Use correct guarded route
        icon: const Icon(Icons.add),
        label: Text(t('post_new_job')), // Use translation key
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}