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

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
    final user = authState.user;
    
    // ตรวจสอบว่าเป็นนายจ้างหรือไม่
    final isEmployer = user?.role == 'employer';
    
    // Debug: ตรวจสอบข้อมูลผู้ใช้
    print('Debug MainLayout - User: ${user?.email}, Role: ${user?.role}, IsEmployer: $isEmployer');
    
    // เมนูสำหรับนายจ้าง
    final List<NavigationDestination> _employerDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: 'แดชบอร์ด',
      ),
      NavigationDestination(
        icon: const Icon(Icons.work_outline),
        selectedIcon: const Icon(Icons.work),
        label: 'จัดการงาน',
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: 'ผู้สมัคร',
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
        label: 'บุ๊กมาร์ก',
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

    // Update selected index based on current route
    final location = GoRouterState.of(context).uri.path;
    
    if (isEmployer) {
      if (location.startsWith('/employer/dashboard')) {
        _selectedIndex = 0;
      } else if (location.startsWith('/employer/jobs')) {
        _selectedIndex = 1;
      } else if (location.startsWith('/employer/applications')) {
        _selectedIndex = 2;
      } else if (location.startsWith('/chats')) {
        _selectedIndex = 3;
      } else if (location.startsWith('/profile')) {
        _selectedIndex = 4;
      }
    } else {
      if (location.startsWith('/jobs')) {
        _selectedIndex = 0;
      } else if (location.startsWith('/applications')) {
        _selectedIndex = 1;
      } else if (location.startsWith('/bookmarks')) {
        _selectedIndex = 2;
      } else if (location.startsWith('/chats')) {
        _selectedIndex = 3;
      } else if (location.startsWith('/profile')) {
        _selectedIndex = 4;
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
      floatingActionButton: (!isEmployer && _selectedIndex == 0) ? FloatingActionButton.extended(
        onPressed: () => context.push('/post-job'),
        icon: const Icon(Icons.add),
        label: Text(t('post_job')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ) : (isEmployer && _selectedIndex == 1) ? FloatingActionButton.extended(
        onPressed: () => context.push('/post-job'),
        icon: const Icon(Icons.add),
        label: const Text('โพสต์งานใหม่'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}