// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/models.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/flights/controllers/flight_controller.dart';
import '../../../features/bookings/controllers/booking_controller.dart';
import '../../../features/flights/widgets/flight_card.dart';
import '../../../shared/widgets/loco_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _currentCity = 'Locating...';
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Get device GPS location and reverse geocode to city name
  Future<void> _detectLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _currentCity = 'India');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          _currentCity = placemarks.first.locality ??
              placemarks.first.administrativeArea ??
              'India';
        });
        // Save city to user profile for nearby search
        ref.read(authRepositoryProvider).updateCurrentCity(_currentCity);
      }
    } catch (_) {
      if (mounted) setState(() => _currentCity = 'India');
    }
  }

  void _handleSearch() {
    // Update the search params provider — the flight list screen reads this
    ref.read(flightSearchParamsProvider.notifier).state = FlightSearchParams(
      fromCity: _fromController.text.trim(),
      toCity: _toController.text.trim(),
      date: _selectedDate,
    );
    context.go(AppRoutes.flightList);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final nearbyAsync = ref.watch(nearbyFlightsProvider);
    final offersAsync = ref.watch(specialOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          // Pull down to refresh flights
          onRefresh: () async {
            ref.invalidate(nearbyFlightsProvider);
            ref.invalidate(specialOffersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header: avatar + LocoFly + city + notification bell ─────
                Row(
                  children: [
                    // User avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _initials(user?.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LocoFly', style: AppTextStyles.headingSmall),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(_currentCity, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Notification bell with unread count badge
                    Consumer(
                      builder: (context, ref, _) {
                        final countAsync = ref.watch(unreadNotificationCountProvider);
                        final count = countAsync.value ?? 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () => context.go(AppRoutes.notifications),
                            ),
                            if (count > 0)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  width: count > 9 ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: count > 9
                                      ? const Center(
                                          child: Text('9+',
                                            style: TextStyle(color: Colors.white, fontSize: 8),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Search card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // FROM / swap icon / TO
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fromController,
                              decoration: InputDecoration(
                                hintText: 'Mumbai',
                                labelText: 'FROM',
                                labelStyle: AppTextStyles.labelSmall,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          // Swap button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap: () {
                                final tmp = _fromController.text;
                                _fromController.text = _toController.text;
                                _toController.text = tmp;
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.swap_horiz,
                                    size: 18, color: AppColors.primary),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _toController,
                              decoration: InputDecoration(
                                hintText: 'Delhi',
                                labelText: 'TO',
                                labelStyle: AppTextStyles.labelSmall,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Date picker
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'DAY   ${DateFormat('d MMM, yyyy').format(_selectedDate)}',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search button
                      LCPrimaryButton(label: 'Search', onPressed: _handleSearch),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Special offer banner ────────────────────────────────────
                offersAsync.when(
                  loading: () => _offerShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (offers) {
                    if (offers.isEmpty) return const SizedBox.shrink();
                    return _buildOfferBanner(offers.first);
                  },
                ),

                const SizedBox(height: 20),

                // ── Flights Near You header ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Flights Near You', style: AppTextStyles.headingSmall),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.flightList),
                      child: Text(
                        'View All →',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Nearby flights list ─────────────────────────────────────
                nearbyAsync.when(
                  loading: () => _flightListShimmer(),
                  error: (e, _) => Center(
                    child: Text('Could not load flights: $e',
                        style: AppTextStyles.bodySmall),
                  ),
                  data: (flights) {
                    if (flights.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.airplanemode_inactive,
                                  size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('No flights available near you',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      // NeverScrollableScrollPhysics because we're inside
                      // a SingleChildScrollView — nested scrolling would conflict
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: flights.length > 5 ? 5 : flights.length,
                      itemBuilder: (context, index) {
                        final flight = flights[index];
                        return FlightCard(
                          flight: flight,
                          compact: true,
                          onTap: () => context.go(
                            AppRoutes.flightDetailPath(flight.id.toString()),
                          ),
                          onBidTap: () => context.go(
                            AppRoutes.placeBidPath(flight.id.toString()),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Special offer banner ──────────────────────────────────────────────────
  Widget _buildOfferBanner(SpecialOfferModel offer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Special Offer',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(offer.title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            'Bid now and save up to ${offer.discountPercent}% on charter flights ✦',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go(
              AppRoutes.flightDetailPath(offer.flightId.toString()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bid Now →',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer placeholders while loading ────────────────────────────────────
  Widget _offerShimmer() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _flightListShimmer() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 280,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'LF';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
