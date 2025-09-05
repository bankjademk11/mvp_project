import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_router.dart';
import 'theme.dart';
import 'services/language_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final router = ref.watch(goRouterProvider);
    final textTheme = GoogleFonts.notoSansLaoTextTheme();
    final theme = buildAppTheme(textTheme);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'mvp package',
      theme: theme,
      locale: languageState.locale,
      supportedLocales: const [
        Locale('lo'), // Lao
        Locale('en'), // English
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}