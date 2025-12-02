import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/router/auth_state_notifier.dart';
import 'package:real/core/services/route_persistence_service.dart';
import 'package:real/splash_screen.dart';
import 'package:real/feature_web/auth/presentation/web_login_screen.dart';
import 'package:real/feature_web/auth/presentation/web_signup_screen.dart';
import 'package:real/feature_web/auth/presentation/web_forgot_password_screen.dart';
import 'package:real/feature_web/navigation/web_main_screen.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';
import 'package:real/feature_web/compound/presentation/web_compound_detail_screen.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';
import 'package:real/feature_web/subscription/presentation/web_subscription_plans_screen.dart';
import 'package:real/feature/auth/presentation/screen/device_management_screen.dart';
import 'package:real/feature/auth/presentation/screen/email_verification_screen.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/ai_chat/presentation/screen/unified_ai_chat_screen.dart';
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';
import 'package:real/feature/sales_assistant/presentation/screen/sales_assistant_screen_OLD.dart';

class AppRouter {
  static final _authStateNotifier = AuthStateNotifier();
  static String? _initialSavedRoute;

  /// Set the initial saved route (called from main.dart)
  static void setInitialSavedRoute(String route) {
    _initialSavedRoute = route;
    print('[ROUTER] Initial saved route set to: $route');
  }

  static final GoRouter router = GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _authStateNotifier,
    observers: [RouteObserver<ModalRoute<void>>(), _RouteObserver()],

    routes: [
      // Splash Screen Route (unified for web and mobile)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => WebLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => WebSignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const WebForgotPasswordScreen(),
      ),

      // Email Verification Route
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Main App Route (with tabs)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => WebMainScreen(),
      ),

      // Company Detail
      GoRoute(
        path: '/company/:id',
        name: 'company-detail',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;
          final extra = state.extra;

          // Handle both Company object and Map<String, dynamic>
          Company? company;
          if (extra is Company) {
            company = extra;
          } else if (extra is Map<String, dynamic>) {
            company = Company.fromJson(extra);
          }

          // Pass company data if available, otherwise just pass ID
          // The screen will fetch data if needed
          return WebCompanyDetailScreen(
            companyId: companyId,
            company: company,
          );
        },
      ),

      // Compound Detail
      GoRoute(
        path: '/compound/:id',
        name: 'compound-detail',
        builder: (context, state) {
          final compoundId = state.pathParameters['id']!;
          return WebCompoundDetailScreen(compoundId: compoundId);
        },
      ),

      // Unit Detail
      GoRoute(
        path: '/unit/:id',
        name: 'unit-detail',
        builder: (context, state) {
          final unitId = state.pathParameters['id']!;
          final unitData = state.extra as Map<String, dynamic>?;

          // Pass unit data if available, otherwise just pass ID
          // The screen will fetch data if needed
          return WebUnitDetailScreen(
            unitId: unitId,
            unit: unitData != null ? Unit.fromJson(unitData) : null,
          );
        },
      ),

      // Subscription Plans
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => WebSubscriptionPlansScreen(),
      ),

      // Device Management
      GoRoute(
        path: '/device-management',
        name: 'device-management',
        builder: (context, state) => DeviceManagementScreen(),
      ),

      // AI Chat Route (with optional comparison items)
      GoRoute(
        path: '/ai-chat',
        name: 'ai-chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final comparisonItems = extra?['comparison_items'] as List<ComparisonItem>?;
          return UnifiedAIChatScreen(comparisonItems: comparisonItems);
        },
      ),

      // Sales Assistant (NEW - Unified with BLoC)
      GoRoute(
        path: '/sales-assistant',
        name: 'sales-assistant',
        builder: (context, state) => const UnifiedAIChatScreen(),
      ),

      // Sales Assistant (OLD - Algorithm 2 Only) - FOR TESTING
      GoRoute(
        path: '/sales-assistant-test',
        name: 'sales-assistant-test',
        builder: (context, state) => const SalesAssistantScreenOLD(),
      ),
    ],

    // Redirect logic for authentication
    redirect: (context, state) {
      final isLoggedIn = token != null && token != "";
      final currentPath = state.matchedLocation;
      final fullPath = state.uri.toString();
      final pathParams = state.pathParameters;
      final isSplashRoute = currentPath == '/splash';
      final isAuthRoute = currentPath == '/login' ||
          currentPath == '/signup' ||
          currentPath == '/forgot-password' ||
          currentPath == '/verify-email';

      print('[ROUTER] ==========================================');
      print('[ROUTER] Redirect check');
      print('[ROUTER] Full URI: $fullPath');
      print('[ROUTER] Matched location: $currentPath');
      print('[ROUTER] Path parameters: $pathParams');
      print('[ROUTER] Token value: $token');
      print('[ROUTER] Token != null: ${token != null}');
      print('[ROUTER] Token != "": ${token != ""}');
      print('[ROUTER] isLoggedIn: $isLoggedIn');
      print('[ROUTER] isSplashRoute: $isSplashRoute');
      print('[ROUTER] isAuthRoute: $isAuthRoute');
      print('[ROUTER] Should save route: ${RoutePersistenceService.shouldSaveRoute(currentPath)}');
      print('[ROUTER] ==========================================');

      // Redirect splash screen immediately - we don't need it on web
      if (isSplashRoute) {
        print('[ROUTER] ✅ Splash screen - redirecting based on auth');
        if (isLoggedIn) {
          final route = _initialSavedRoute ?? '/';
          print('[ROUTER] Redirecting logged in user to: $route');
          return route;
        } else {
          print('[ROUTER] Redirecting to login');
          return '/login';
        }
      }

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        // Store the original location to redirect back after login
        print('[ROUTER] ❌ NOT LOGGED IN - Redirecting to login with from=$currentPath');
        return '/login?from=${Uri.encodeComponent(currentPath)}';
      }

      // If logged in and trying to access login/signup routes (but NOT verification)
      // Allow verification screen even when logged in (user needs to verify email)
      final isLoginOrSignupRoute = currentPath == '/login' || currentPath == '/signup';
      if (isLoggedIn && isLoginOrSignupRoute) {
        // Check if there's a 'from' parameter to redirect back
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          final destination = Uri.decodeComponent(from);
          print('[ROUTER] ✅ Logged in, redirecting from login to: $destination');
          return destination;
        }
        print('[ROUTER] ✅ Logged in on auth route, redirecting to home');
        return '/';
      }

      // DISABLED: Route persistence - users requested to always start on home screen
      // if (isLoggedIn && !isLoginRoute && RoutePersistenceService.shouldSaveRoute(currentPath)) {
      //   _saveCurrentRoute(state);
      // }

      print('[ROUTER] ✅ No redirect needed - allowing navigation to $currentPath');
      return null; // No redirect needed
    },

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static String _getInitialRoute() {
    print('[ROUTER] _getInitialRoute called');
    final isLoggedIn = token != null && token != "";

    if (!isLoggedIn) {
      print('[ROUTER] Not logged in, initial route: /login');
      return '/login';
    }

    // If logged in and there's a saved route, use it
    if (_initialSavedRoute != null) {
      print('[ROUTER] Using saved route: $_initialSavedRoute');
      return _initialSavedRoute!;
    }

    // Otherwise, go to home
    print('[ROUTER] No saved route, initial route: /');
    return '/';
  }

  /// Get the initial location including saved route restoration
  static Future<String> _getInitialLocation() async {
    print('[ROUTER] _getInitialLocation called');
    final isLoggedIn = token != null && token != "";

    if (!isLoggedIn) {
      print('[ROUTER] Not logged in, returning /login');
      return '/login';
    }

    // Try to restore saved route
    final savedRoute = await RoutePersistenceService.getFullSavedRoute();
    print('[ROUTER] Saved route found: $savedRoute');

    if (savedRoute != null && savedRoute != '/' && savedRoute != '/login') {
      print('[ROUTER] Restoring saved route: $savedRoute');
      return savedRoute;
    }

    print('[ROUTER] No saved route, returning /');
    return '/';
  }

  /// Save the current route to persistence
  static void _saveCurrentRoute(GoRouterState state) {
    // Use the full URI path which has actual values, not placeholders
    final fullPath = state.uri.path;

    print('[ROUTER] Saving route: $fullPath');
    print('[ROUTER] URI: ${state.uri}');
    print('[ROUTER] Matched location: ${state.matchedLocation}');

    // Save the full path directly (it already has the actual parameter values)
    RoutePersistenceService.saveRoute(fullPath);
  }

  /// Restore saved route if available
  static Future<void> restoreSavedRoute(BuildContext context) async {
    print('[ROUTER RESTORE] ========================================');
    print('[ROUTER RESTORE] Attempting to restore saved route...');

    final isLoggedIn = token != null && token != "";
    print('[ROUTER RESTORE] Is logged in: $isLoggedIn');

    if (!isLoggedIn) {
      print('[ROUTER RESTORE] Not logged in, skipping route restoration');
      print('[ROUTER RESTORE] ========================================');
      return;
    }

    final savedRoute = await RoutePersistenceService.getSavedRoute();
    final savedParams = await RoutePersistenceService.getSavedRouteParams();
    final fullRoute = await RoutePersistenceService.getFullSavedRoute();

    print('[ROUTER RESTORE] Saved route: $savedRoute');
    print('[ROUTER RESTORE] Saved params: $savedParams');
    print('[ROUTER RESTORE] Full reconstructed route: $fullRoute');

    if (fullRoute != null && fullRoute != '/') {
      print('[ROUTER RESTORE] Restoring to: $fullRoute');
      if (context.mounted) {
        context.go(fullRoute);
        print('[ROUTER RESTORE] Navigation executed');
      } else {
        print('[ROUTER RESTORE] Context not mounted, cannot navigate');
      }
    } else {
      print('[ROUTER RESTORE] No saved route to restore or already on home');
    }
    print('[ROUTER RESTORE] ========================================');
  }
}

/// Route observer to save routes on navigation
class _RouteObserver extends NavigatorObserver {
  // Route saving is handled in the redirect function
  // This observer is kept for future use if needed
}
