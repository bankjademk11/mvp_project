import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../common/widgets/language_switcher.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ອອກຈາກລະບົບ'),
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ອອກຈາກລະບົບ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    // If user is not loaded, show loading indicator
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ໂປຣໄຟລ໌'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ແກ້ໄຂໂປຣໄຟລ໌',
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'ອອກຈາກລະບົບ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user.displayName)
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name and Email
                  Text(
                    user.displayName ?? 'ບໍ່ລະບຸຊື່',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      user.role == 'seeker' 
                          ? '💼 ຜູ້ຫາວຽກງານ' 
                          : '🏢 ນາຍຈ້າງ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Profile Information Cards
            _buildInfoSection(
              context,
              title: 'ຂໍ້ມູນສ່ວນຕົວ',
              icon: Icons.person_outline,
              children: [
                _buildInfoItem(
                  context,
                  Icons.phone,
                  'ເບີໂທລະສັບ',
                  user.phone ?? 'ບໍ່ໄດ້ລະບຸ',
                ),
                _buildInfoItem(
                  context,
                  Icons.location_on_outlined,
                  'ແຂວງ/ເມືອງ',
                  user.province ?? 'ບໍ່ໄດ້ລະບຸ',
                ),
              ],
            ),
            
            // Skills Section
            if ((user.skills)?.isNotEmpty ?? false)
              _buildInfoSection(
                context,
                title: 'ທັກສະ ແລະ ຄວາມສາມາດ',
                icon: Icons.psychology_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (user.skills ?? []).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            skill.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            
            // Bio Section
            if (user.bio != null && user.bio.toString().isNotEmpty)
              _buildInfoSection(
                context,
                title: 'ກ່ຽວກັບຕົນເອງ',
                icon: Icons.description_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      user.bio.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Resume Section
            _buildInfoSection(
              context,
              title: 'ເອກະສານ ແລະ ເລຊູເມ',
              icon: Icons.description,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.file_present_outlined,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.resumeUrl != null && user.resumeUrl.toString().isNotEmpty
                                  ? 'ມີໄຟລ໌ເລຊູເມແລ້ວ'
                                  : 'ຍັງບໍ່ໄດ້ອັບໂຫລດເລຊູເມ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ຟີເຈີອັບໂຫລດໄຟລ໌ຈະຖືກເພີ່ມໃນເວີຊັນຕໍ່ໄປ'),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  user.resumeUrl != null && user.resumeUrl.toString().isNotEmpty
                                      ? Icons.refresh
                                      : Icons.upload_file,
                                ),
                                label: Text(
                                  user.resumeUrl != null && user.resumeUrl.toString().isNotEmpty
                                      ? 'ອັບເດດເລຊູເມ'
                                      : 'ອັບໂຫລດເລຊູເມ',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Language Switcher
            const LanguageSwitcher(),
            
            // Bottom spacing
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
