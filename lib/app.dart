import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/l10n/app_localizations.dart';

import 'shared/constants/app_theme.dart';
import 'shared/constants/app_colors.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/firebase_provider.dart';
import 'auth/screens/login_screen.dart';
import 'auth/providers/auth_provider.dart';
import 'dashboard/screens/dashboard_screen.dart';
import 'shared/widgets/loading_overlay.dart';

/// Main App widget
class IBuzzApp extends ConsumerWidget {
  const IBuzzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final firebaseError = ref.watch(firebaseInitErrorProvider);

    return MaterialApp(
      title: 'I-Buzz BD Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('bn')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: firebaseError != null
          ? FirebaseErrorScreen(message: firebaseError)
          : const AuthWrapper(),
    );
  }
}

/// Shown when Firebase fails to initialize.
class FirebaseErrorScreen extends StatelessWidget {
  final String message;

  const FirebaseErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to connect',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Firebase could not be initialized. Check your internet connection and Firebase configuration, then restart the app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auth wrapper to handle authentication state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
      loading: () => const AppLoadingScreen(message: 'Loading...'),
      error: (error, stack) {
        debugPrint('Auth error: $error');
        return const LoginScreen();
      },
    );
  }
}
