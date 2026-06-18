import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gestione Mezzi',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // C4: dark() è ancora uno stub (Phase 6). Forziamo light finché
      // il tema scuro non è completo, per evitare UI rotta su OS in dark mode.
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
