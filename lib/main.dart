import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:real/core/network/api_service.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/core/locale/language_service.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/core/network/token_manager.dart';
import 'package:real/core/router/app_router.dart';
import 'package:real/core/router/auth_state_notifier.dart';
import 'package:real/core/services/route_persistence_service.dart';
import 'dart:async';
import 'package:real/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/bloc/verification_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/unit/unit_bloc.dart';
import 'package:real/feature/sale/presentation/bloc/sale_bloc.dart';
import 'package:real/feature/sale/presentation/bloc/sale_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/auth/presentation/screen/forgetPasswordScreen.dart';
import 'package:real/feature/auth/presentation/screen/forgot_password_flow_screen.dart';
import 'package:real/feature/auth/presentation/screen/changePasswordScreen.dart';
import 'package:real/feature/auth/presentation/screen/editNameScreen.dart';
import 'package:real/feature/auth/presentation/screen/editPhoneScreen.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/home/presentation/homeScreen.dart';
import 'package:real/feature/onboarding/onboardingScreen.dart';
import 'package:real/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:real/services/fcm_service.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature_web/navigation/web_main_screen.dart';
import 'package:real/feature_web/auth/presentation/web_login_screen.dart';
import 'package:real/feature_web/auth/presentation/web_signup_screen.dart';
import 'package:real/feature_web/auth/presentation/web_forgot_password_screen.dart';
import 'package:real/feature/subscription/presentation/screens/subscription_plans_screen.dart';
import 'package:real/feature_web/subscription/presentation/web_subscription_plans_screen.dart';

import 'feature/auth/presentation/screen/SignupScreen.dart';
import 'feature/company/data/models/company_model.dart';
import 'feature/company/presentation/screen/company_detail_screen.dart';
import 'feature/home/presentation/CompoundScreen.dart';
import 'feature/home/presentation/CustomNav.dart';
import 'feature/compound/presentation/screen/favorite_compounds_screen.dart';
import 'feature/notifications/presentation/screens/notifications_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable clean URLs for web (remove # from URL)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('✅ Background message handler registered');

  // Initialize cache
  await CasheNetwork.casheInitialization();
  token = await CasheNetwork.getCasheDataAsync(key: 'token');
  userId = await CasheNetwork.getCasheDataAsync(key: 'user_id');

  // Notify router if token exists
  if (token != null && token != "") {
    AuthStateNotifier().notifyAuthChanged();
    print('✅ Notified router of existing token on app startup');
  }

  // Load saved route for restoration on refresh (web only)
  if (kIsWeb && token != null && token != "") {
    final savedRoute = await RoutePersistenceService.getFullSavedRoute();
    if (savedRoute != null && savedRoute != '/login') {
      AppRouter.setInitialSavedRoute(savedRoute);
      print('✅ Loaded saved route for restoration: $savedRoute');
    }
  }

  // Initialize LanguageService
  await LanguageService.initialize();
  print('✅ Language service initialized: ${LanguageService.currentLanguage}');

  print('');
  print('═══════════════════════════════════════════════════════');
  print('📱 Auth Token Status');
  print('═══════════════════════════════════════════════════════');
  print('Token exists: ${token != null && token != ""}');
  if (token != null && token != "") {
    print('Token: ${token!.substring(0, 20)}...');
  }
  print('═══════════════════════════════════════════════════════');
  print('');

  // Initialize FCM Service
  await FCMService().initialize();

  // Setup FCM message listeners
  FCMService().setupMessageListeners();

  // Check if app was opened from notification (terminated state)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('🚀 App opened from notification (terminated state)');
    FCMService().handleNotificationTap(initialMessage);
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<bool>? _tokenExpiredSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for token expiration events
    _tokenExpiredSubscription = TokenManager().onTokenExpired.listen((_) {
      print('[MyApp] Token expired event received - navigating to login');

      if (kIsWeb) {
        // Use go_router for web
        AppRouter.router.go('/login');
      } else {
        // Use traditional navigation for mobile
        final context = TokenManager.navigatorKey.currentContext;
        if (context != null) {
          MessageHelper.showMessage(
            context: context,
            message: 'Session expired. Please login again.',
            isSuccess: false,
          );

          Navigator.of(context).pushNamedAndRemoveUntil(
            LoginScreen.routeName,
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tokenExpiredSubscription?.cancel();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LocaleCubit(),
        ),
        BlocProvider(
          create: (context) =>
              RegisterBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) => LoginBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) =>
              ForgotPasswordBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) =>
              UpdateNameBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) =>
              UpdatePhoneBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) =>
              VerificationBloc(repository: apiService.authRepository),
        ),
        BlocProvider(
          create: (context) =>
              UserBloc(repository: apiService.authRepository)
                ..add(FetchUserEvent()),
        ),
        BlocProvider(
          create: (context) =>
              CompanyBloc(repository: apiService.companyRepository),
        ),
        BlocProvider(
          create: (context) =>
              CompoundBloc(repository: apiService.compoundRepository),
        ),
        BlocProvider(
          create: (context) => CompoundFavoriteBloc(),
        ),
        BlocProvider(
          create: (context) => UnitFavoriteBloc(),
        ),
        BlocProvider(
          create: (context) =>
              UnitBloc(repository: apiService.unitRepository),
        ),
        BlocProvider(
          create: (context) =>
              SaleBloc(repository: apiService.saleRepository)
                ..add(FetchSalesEvent()),
        ),
        BlocProvider(
          create: (context) =>
              SubscriptionBloc(repository: apiService.subscriptionRepository),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          // Use router for web, traditional navigation for mobile
          if (kIsWeb) {
            return MaterialApp.router(
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,

              // Localization delegates
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Supported locales
              supportedLocales: [
                Locale('en'), // English
                Locale('ar'), // Arabic
              ],

              // Current locale from LocaleCubit
              locale: locale,

              theme: ThemeData(
                scaffoldBackgroundColor: Colors.white,
                brightness: Brightness.light,
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.black87),
                  bodyMedium: TextStyle(color: Colors.black87),
                  bodySmall: TextStyle(color: Colors.black87),
                ),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
              ),
            );
          }

          // Mobile app uses traditional routing
          return MaterialApp(
            navigatorKey: TokenManager.navigatorKey,
            debugShowCheckedModeBanner: false,

            // Localization delegates
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Supported locales
            supportedLocales: [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],

            // Current locale from LocaleCubit
            locale: locale,

            initialRoute: token != null && token != ""
                ? CustomNav.routeName
                : LoginScreen.routeName,

            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              brightness: Brightness.light,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black87),
                bodySmall: TextStyle(color: Colors.black87),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
            ),

            routes: {
              SplashScreen.routeName: (context) => SplashScreen(),
              CustomNav.routeName: (context) => CustomNav(),
              LoginScreen.routeName: (context) => LoginScreen(),
              OnboardingScreen.routeName: (context) => OnboardingScreen(),
              SignUpScreen.routeName: (context) => SignUpScreen(),
              ForgetPasswordScreen.routeName: (context) => ForgetPasswordScreen(),
              ForgotPasswordFlowScreen.routeName: (context) => const ForgotPasswordFlowScreen(),
              ChangePasswordScreen.routeName: (context) => ChangePasswordScreen(),
              EditNameScreen.routeName: (context) => EditNameScreen(),
              EditPhoneScreen.routeName: (context) => EditPhoneScreen(),
              HomeScreen.routeName: (context) => HomeScreen(),
              FavoriteCompoundsScreen.routeName: (context) => FavoriteCompoundsScreen(),
              NotificationsScreen.routeName: (context) => NotificationsScreen(),
              SubscriptionPlansScreen.routeName: (context) => SubscriptionPlansScreen(),
              CompanyDetailScreen.routeName: (context) {
                final company = ModalRoute.of(context)!.settings.arguments as Company;
                return CompanyDetailScreen(company: company);
              }
            },
          );
        },
      ),
    );
  }
}
