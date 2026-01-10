import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseService.initialize();

  // Inicializar locale español para intl
  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: EvioAdminApp()));
}

class EvioAdminApp extends ConsumerWidget {
  const EvioAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Evio Admin',
      debugShowCheckedModeBanner: false,
      theme: EvioTheme.light,
      darkTheme: EvioTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
