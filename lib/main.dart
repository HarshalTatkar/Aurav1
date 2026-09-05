import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(const ProviderScope(child: AuraApp()));
}

class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'AURA',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.lightTheme,
      darkTheme: AuraTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
