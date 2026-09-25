import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auditor_model.dart';
import '../../data/models/latik_profile.dart';
import '../../presentation/auditor/auditor_list_screen.dart';
import '../../presentation/auditor/penambahan_confirm_screen.dart';
import '../../presentation/auth/activation_notice_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/dokumen/dokumen_screen.dart';
import '../../presentation/notifikasi/notifikasi_screen.dart';
import '../../presentation/perpanjangan/auditor_perpanjangan_screen.dart';
import '../../presentation/perpanjangan/latik_perpanjangan_screen.dart';
import '../../presentation/perpanjangan/perpanjangan_entry_screen.dart';
import '../../presentation/profil/data_pengguna_screen.dart';
import '../../presentation/profil/dokumen_berkas_edit_screen.dart';
import '../../presentation/profil/dokumen_berkas_screen.dart';
import '../../presentation/profil/profil_lembaga_edit_screen.dart';
import '../../presentation/profil/profil_lembaga_screen.dart';
import '../../presentation/profil/profil_screen.dart';
import '../../presentation/shared/pdf_viewer_screen.dart';
import '../../presentation/shared/scaffold_with_nav_bar.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/transaksi/transaksi_screen.dart';
import '../../presentation/verifikasi/latik_verifikasi_screen.dart';
import '../../providers/auth_provider.dart';
import '../auth/access_control.dart';
import '../constants/app_routes.dart';

/// Builds the app-wide [GoRouter], including the auth/permission redirect.
GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
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
      GoRoute(
        path: AppRoutes.profilLembaga,
        builder: (_, __) => const ProfilLembagaScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilLembagaEdit,
        builder: (_, state) => ProfilLembagaEditScreen(
          profile: state.extra as LatikProfile,
        ),
      ),
      GoRoute(
        path: AppRoutes.dataPengguna,
        builder: (_, __) => const DataPenggunaScreen(),
      ),
      GoRoute(
        path: AppRoutes.dokumenBerkas,
        builder: (_, __) => const DokumenBerkasScreen(),
      ),
      GoRoute(
        path: AppRoutes.dokumenBerkasEdit,
        builder: (_, __) => const DokumenBerkasEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.transaksi,
        builder: (_, __) => const TransaksiScreen(),
      ),
      GoRoute(
        path: AppRoutes.perpanjangan,
        builder: (_, __) => const PerpanjanganEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.perpanjanganLatik,
        builder: (_, state) =>
            LatikPerpanjanganScreen(refExt: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.perpanjanganAuditor,
        builder: (_, state) =>
            AuditorPerpanjanganScreen(refExt: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.penambahanAuditor,
        builder: (_, state) =>
            PenambahanConfirmScreen(auditor: state.extra as AuditorModel),
      ),
      GoRoute(
        path: AppRoutes.verifikasiLatik,
        builder: (_, state) =>
            LatikVerifikasiScreen(profile: state.extra as LatikProfile),
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
      if (auth.isLoggedIn && !AccessControl.canUseMobile(auth.user)) {
        return AppRoutes.login;
      }
      final requiredPermission = _requiredPermission(location);
      if (auth.isLoggedIn &&
          requiredPermission != null &&
          !AccessControl.hasPermission(auth.user, requiredPermission)) {
        return AppRoutes.dashboard;
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

String? _requiredPermission(String location) {
  if (location == AppRoutes.dashboard) return AccessControl.dashboardView;
  if (location == AppRoutes.dokumen ||
      location == AppRoutes.profilLembaga ||
      location == AppRoutes.profilLembagaEdit ||
      location == AppRoutes.dokumenBerkas ||
      location == AppRoutes.dokumenBerkasEdit ||
      location == AppRoutes.transaksi ||
      location == AppRoutes.verifikasiLatik ||
      location == AppRoutes.auditors) {
    return AccessControl.latikProfile;
  }
  return null;
}