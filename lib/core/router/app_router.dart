// lib/core/router/app_router.dart — Phase 5 (final)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/screens/main_shell_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/flights/screens/flight_list_screen.dart';
import '../../features/flights/screens/flight_detail_screen.dart';
import '../../features/flights/screens/amenities_screen.dart';
import '../../features/bids/screens/place_bid_screen.dart';
import '../../features/bids/screens/passenger_details_screen.dart';
import '../../features/bids/screens/my_bids_screen.dart';
import '../../features/bookings/screens/bookings_screen.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../data/models/models.dart';
import '../constants/app_constants.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash         = '/';
  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String signup         = '/signup';
  static const String otpVerify      = '/otp-verify';
  static const String home           = '/home';
  static const String flightList     = '/flights';
  static const String bids           = '/bids';
  static const String bookings       = '/bookings';
  static const String profile        = '/profile';
  static const String notifications  = '/notifications';

  static String flightDetailPath(String id)   => '/flights/$id';
  static String amenitiesPath(String id)      => '/flights/$id/amenities';
  static String placeBidPath(String id)       => '/flights/$id/bid';
  static String passengersPath(String id)     => '/flights/$id/bid/passengers';
  static String bidDetailPath(String id)      => '/bids/$id';
  static String bookingDetailPath(String id)  => '/bookings/$id';
}

const _protectedRoutes = ['/home', '/flights', '/bids', '/bookings', '/profile', '/notifications'];
const _authRoutes      = ['/login', '/signup', '/onboarding', '/otp-verify'];

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isLoggedIn = ref.read(authRepositoryProvider).isLoggedIn;

      if (path == '/') {
        if (isLoggedIn) return AppRoutes.home;
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;
        return seen ? AppRoutes.login : AppRoutes.onboarding;
      }

      final isProtected = _protectedRoutes.any((r) => path.startsWith(r));
      if (isProtected && !isLoggedIn) return AppRoutes.login;

      final isAuthRoute = _authRoutes.any((r) => path.startsWith(r));
      if (isAuthRoute && isLoggedIn) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,     builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login,      builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup,     builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // Notifications — outside shell (full screen, no bottom nav)
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.flightList,
            builder: (_, __) => const FlightListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return FlightDetailScreen(flightId: id);
                },
                routes: [
                  GoRoute(
                    path: 'amenities',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return AmenitiesScreen(flightId: id);
                    },
                  ),
                  GoRoute(
                    path: 'bid',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return PlaceBidScreen(flightId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'passengers',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return PassengerDetailsScreen(
                            flightId: extra?['flightId'] as int? ?? 0,
                            bidAmount: (extra?['bidAmount'] as num?)?.toDouble() ?? 0,
                            charterOption: extra?['charterOption'] as String? ?? 'Full Plane',
                            expiryHours: extra?['expiryHours'] as int? ?? 24,
                            flight: extra?['flight'] as FlightModel?,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.bids,
            builder: (_, __) => const MyBidsScreen(),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            builder: (_, __) => const BookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return BookingDetailScreen(bookingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5A623),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airplanemode_active, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text('LOCO',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4)),
            SizedBox(height: 8),
            Text('FLY',
                style: TextStyle(
                    fontSize: 14, color: Colors.white70, letterSpacing: 6)),
          ],
        ),
      ),
    );
  }
}
