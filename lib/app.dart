import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/constants/app_routes.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auditor_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dokumen_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/notifikasi_provider.dart';
import 'providers/profile_menu_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'id_ID';
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: SilatikApp()));
}

class SilatikApp extends ConsumerStatefulWidget {
  const SilatikApp({super.key});

  @override
  ConsumerState<SilatikApp> createState() => _SilatikAppState();
}

class _SilatikAppState extends ConsumerState<SilatikApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    onUnauthorized = () => ref.read(authProvider.notifier).logout();
    _router = createRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.user != next.user) {
        ref.invalidate(auditorListProvider);
        ref.invalidate(latikProfileProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(faqProfileProvider);
        ref.invalidate(notifikasiListProvider);
        ref.invalidate(unreadNotificationProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(dokumenListProvider);
        ref.invalidate(invoiceListProvider);
      }
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        _router.go(AppRoutes.login);
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SILATIK',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}