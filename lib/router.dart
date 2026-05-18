import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/main_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/books/screens/book_detail_screen.dart';
import 'features/books/screens/donate_book_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/transactions/screens/activity_screen.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final authRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !authRoute) return '/login';
      if (loggedIn && authRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Book detail — full screen tanpa bottom nav
      GoRoute(
        path: '/book/:id',
        builder: (_, state) => BookDetailScreen(
          bookId: state.pathParameters['id']!,
        ),
      ),

      // Main shell
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          GoRoute(
              path: '/donate', builder: (_, __) => const DonateBookScreen()),
          GoRoute(
              path: '/activity', builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
