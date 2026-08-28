import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auditor/auditor_list_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/activation_notice_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/notifikasi/notifikasi_screen.dart';
import 'presentation/profil/profil_screen.dart';
import 'presentation/registration/registration_flow_screen.dart';
import 'presentation/dokumen/dokumen_screen.dart';
import 'presentation/shared/app_bottom_nav.dart';
import 'presentation/shared/pdf_viewer_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/auditor_provider.dart';
import 'providers/profile_menu_provider.dart';
import 'providers/registrasi_provider.dart';

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
    _router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
            path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: AppRoutes.register,
            builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: AppRoutes.activationNotice,
            builder: (_, __) => const ActivationNoticeScreen()),
        GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
            path: AppRoutes.registration,
            builder: (_, __) => const RegistrationFlowScreen()),
        GoRoute(
          path: AppRoutes.pdfViewer,
          builder: (context, state) {
            final ref = state.uri.queryParameters['ref']?.trim();
            final url = state.uri.queryParameters['url']?.trim();
            return PdfViewerScreen(
              invoiceRef: ref?.isNotEmpty == true ? ref : null,
              url: url?.isNotEmpty == true ? url : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.dokumen,
          builder: (_, __) => const DokumenScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.dashboard,
                  builder: (_, __) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.auditors,
                  builder: (_, __) => const AuditorListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.notifications,
                  builder: (_, __) => const NotifikasiScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.profile,
                  builder: (_, __) => const ProfilScreen()),
            ]),
          ],
        ),
      ],
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final location = state.matchedLocation;
        final publicRoutes = {
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.activationNotice,
          AppRoutes.forgotPassword,
        };

        if (!auth.isLoggedIn && !publicRoutes.contains(location)) {
          return AppRoutes.login;
        }
        if (auth.isLoggedIn &&
            (location == AppRoutes.login ||
                location == AppRoutes.register ||
                location == AppRoutes.forgotPassword)) {
          return AppRoutes.dashboard;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.user != next.user) {
        ref.invalidate(auditorListProvider);
        ref.invalidate(latikProfileProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(faqProfileProvider);
        ref.invalidate(registrasiBootstrapProvider);
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

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFF7FAFE),
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          selectedIndex: navigationShell.currentIndex,
          onItemTapped: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _bootstrapAuth();
  }

  Future<void> _bootstrapAuth() async {
    await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;
    _redirectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      context.go(isLoggedIn ? AppRoutes.dashboard : AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FAFE),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF003D7A),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Icon(Icons.account_balance_outlined,
                      color: Colors.white, size: 42),
                ),
              ),
              SizedBox(height: 22),
              Text(
                'SILATIK',
                style: TextStyle(
                  color: Color(0xFF003D7A),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Sistem Informasi LATIK - BBRIN',
                style: TextStyle(
                  color: Color(0xFF6E7B91),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 70),
              SizedBox(
                width: 74,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0xFFE4ECF7),
                  color: Color(0xFFFFB51B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
