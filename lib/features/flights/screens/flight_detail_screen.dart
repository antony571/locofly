// lib/features/flights/screens/flight_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/flight_controller.dart';

// Tracks which charter option is selected on this screen
final _selectedCharterProvider = StateProvider<int>((ref) => 0);

class FlightDetailScreen extends ConsumerWidget {
  final int flightId;
  const FlightDetailScreen({super.key, required this.flightId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightAsync = ref.watch(flightDetailProvider(flightId));
    final selectedCharter = ref.watch(_selectedCharterProvider);

    return flightAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading flight: $e')),
      ),
      data: (flight) {
        if (flight == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Flight not found')),
          );
        }

        final aircraft = flight.aircraft;
        final charterOptions = ['Full Plane', '+ Catering', 'VIP Setup'];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Flight Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ── Airline info card ────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Airline row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flight,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  aircraft?.airline ?? 'Airline',
                                  style: AppTextStyles.labelLarge,
                                ),
                                Text(
                                  '${aircraft?.flightNumber ?? ''} · ${aircraft?.type ?? ''}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Charter',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Times row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Departure
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(flight.departureTime),
                                style: AppTextStyles.displayMedium,
                              ),
                              Text(flight.fromCode,
                                  style: AppTextStyles.labelMedium),
                              Text(flight.fromCity,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),

                          // Duration + non-stop
                          Column(
                            children: [
                              Text(flight.durationFormatted,
                                  style: AppTextStyles.bodySmall),
                              const Icon(Icons.airplanemode_active,
                                  color: AppColors.primary, size: 22),
                              Text('Non-stop',
                                  style: AppTextStyles.caption),
                            ],
                          ),

                          // Arrival
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(flight.arrivalTime),
                                style: AppTextStyles.displayMedium,
                              ),
                              Text(flight.toCode,
                                  style: AppTextStyles.labelMedium),
                              Text(flight.toCity,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Info chips row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoChip(Icons.calendar_today,
                              DateFormat('MMM d, yyyy').format(flight.departureTime)),
                          _infoChip(Icons.luggage, '1 Bag Included'),
                          _infoChip(Icons.check_circle_outline, 'On Time'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Charter options ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Charter Options', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: charterOptions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final label = entry.value;
                          final isSelected = selectedCharter == i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(_selectedCharterProvider.notifier)
                                  .state = i,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Price row
                      Row(
                        children: [
                          Text('Charter Price', style: AppTextStyles.bodySmall),
                          const Spacer(),
                          Text(
                            '₹${NumberFormat('#,##,###', 'en_IN').format(flight.marketPrice)}',
                            style: AppTextStyles.priceMedium,
                          ),
                          Text(' /flight', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── CTAs ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      LCOutlinedButton(
                        label: 'View Amenities →',
                        onPressed: () => context.go(
                          AppRoutes.amenitiesPath(flightId.toString()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LCPrimaryButton(
                        label: 'Place a Bid ✦',
                        onPressed: () => context.go(
                          AppRoutes.placeBidPath(flightId.toString()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
