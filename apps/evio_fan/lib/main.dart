import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await SupabaseService.initialize();
  await initializeDateFormatting('es', null);
  
  // Configurar timeago en español
  timeago.setLocaleMessages('es', timeago.EsMessages());
  
  runApp(const ProviderScope(child: EvioFanApp()));
}

class EvioFanApp extends ConsumerWidget {
  const EvioFanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Evio Club',
      debugShowCheckedModeBanner: false,
      theme: EvioTheme.dark,
      routerConfig: ref.watch(fanRouterProvider),
    );
  }
}
