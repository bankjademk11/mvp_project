import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  languageState.languageCode == 'lo' ? 'ພາສາ' : 'Language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      'ລາວ (ພາສາລາວ)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    leading: Radio<AppLanguage>(
                      value: AppLanguage.lao,
                      groupValue: languageState.language,
                      onChanged: (value) {
                        if (value != null) {
                          _switchLanguageWithLoading(context, ref, value);
                        }
                      },
                    ),
                    onTap: () {
                      _switchLanguageWithLoading(context, ref, AppLanguage.lao);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(
                      'English (ພາສາອັງກິດ)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    leading: Radio<AppLanguage>(
                      value: AppLanguage.english,
                      groupValue: languageState.language,
                      onChanged: (value) {
                        if (value != null) {
                          _switchLanguageWithLoading(context, ref, value);
                        }
                      },
                    ),
                    onTap: () {
                      _switchLanguageWithLoading(context, ref, AppLanguage.english);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _switchLanguageWithLoading(BuildContext context, WidgetRef ref, AppLanguage language) {
    // Show loading indicator
    final loadingText = language == AppLanguage.lao ? 'ກຳລັງໂຫຼດພາສາລາວ...' : 'Loading English...';
    
    // Show a temporary snackbar with loading indicator
    final snackBar = SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(width: 16),
          Text(loadingText),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      duration: const Duration(seconds: 1),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // Switch language
    switchLanguage(ref, language);
    
    // Refresh the current route to apply changes immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force rebuild by going to the same location
      final route = GoRouter.of(context).routeInformationProvider.value.uri.toString();
      GoRouter.of(context).go(route);
    });
  }
}