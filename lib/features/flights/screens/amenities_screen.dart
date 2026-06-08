// lib/features/flights/screens/amenities_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/flight_controller.dart';

class AmenitiesScreen extends ConsumerStatefulWidget {
  final int flightId;
  const AmenitiesScreen({super.key, required this.flightId});

  @override
  ConsumerState<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends ConsumerState<AmenitiesScreen> {
  // Controls the image carousel (smooth_page_indicator reads this)
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightDetailProvider(widget.flightId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flight Amenities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: flightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (flight) {
          if (flight == null) return const Center(child: Text('Not found'));
          final aircraft = flight.aircraft;
          final images = aircraft?.images ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Airline info bar ─────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        aircraft?.airline ?? 'Airline',
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        ' · ${aircraft?.flightNumber ?? ''} · ${aircraft?.type ?? ''}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '${flight.fromCode} → ${flight.toCode}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ),

                // ── Aircraft image carousel ──────────────────────────────
                if (images.isNotEmpty) ...[
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.primaryLight,
                                child: const Center(
                                  child: Icon(Icons.airplanemode_active,
                                      size: 48, color: AppColors.primary),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primaryLight,
                                child: const Center(
                                  child: Icon(Icons.airplanemode_active,
                                      size: 48, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Page dots indicator
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: images.length,
                      effect: ExpandingDotsEffect(
                        dotColor: AppColors.border,
                        activeDotColor: AppColors.primary,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                  ),
                ] else
                  // Fallback if no images
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.airplanemode_active,
                          size: 64, color: AppColors.primary),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Aircraft details grid ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AIRCRAFT DETAILS',
                          style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: [
                          _specCard(
                            aircraft?.type ?? 'Aircraft Type',
                            'Aircraft Type',
                          ),
                          _specCard(
                            '${aircraft?.passengersCapacity ?? '-'} Passengers',
                            'Full Capacity',
                          ),
                          _specCard(
                            flight.durationFormatted,
                            'Flight Duration',
                          ),
                          _specCard(
                            '${flight.distanceKm.toString()} km',
                            'Route Distance',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Cabin amenities ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CABIN AMENITIES',
                          style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      if (aircraft != null && aircraft.amenities.isNotEmpty)
                        Wrap(
                          spacing: 16,
                          runSpacing: 20,
                          children: aircraft.amenities.map((amenity) {
                            return _amenityItem(
                              _amenityIcon(amenity),
                              amenity,
                            );
                          }).toList(),
                        )
                      else
                        Text('No amenity details available',
                            style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),

                // ── Charter benefits ─────────────────────────────────────
                if (aircraft != null &&
                    aircraft.charterBenefits.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHARTER BENEFITS',
                            style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        ...aircraft.charterBenefits.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Text(b, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _specCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.labelLarge, overflow: TextOverflow.ellipsis),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _amenityItem(IconData icon, String label) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Map amenity strings to icons
  IconData _amenityIcon(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('wifi')) return Icons.wifi;
    if (a.contains('power') || a.contains('outlet')) return Icons.power;
    if (a.contains('entertainment')) return Icons.tv;
    if (a.contains('climate')) return Icons.ac_unit;
    if (a.contains('catering') || a.contains('food')) return Icons.restaurant;
    if (a.contains('bar') || a.contains('beverage')) return Icons.local_bar;
    if (a.contains('lounge')) return Icons.weekend;
    if (a.contains('crew')) return Icons.people;
    return Icons.star_outline;
  }
}
