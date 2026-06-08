// lib/features/flights/screens/flight_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../controllers/flight_controller.dart';
import '../widgets/flight_card.dart';

class FlightListScreen extends ConsumerWidget {
  const FlightListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(flightSearchParamsProvider);
    final flightsAsync = ref.watch(flightsProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          params.fromCity.isNotEmpty && params.toCity.isNotEmpty
              ? 'From ${params.fromCity} (${params.fromCity.substring(0, 3).toUpperCase()})'
              : 'All Flights',
        ),
        actions: [
          // Sort icon — placeholder for now
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
        ],
      ),
      body: flightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Could not load flights', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(flightsProvider(params)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (flights) {
          if (flights.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplanemode_inactive,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No flights found', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Try different dates or cities',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Results count bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Text(
                      '${flights.length} Flights Found',
                      style: AppTextStyles.labelLarge,
                    ),
                    const Spacer(),
                    Text('Sort ↑', style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    )),
                  ],
                ),
              ),

              // Flight cards
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(flightsProvider(params)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: flights.length,
                    itemBuilder: (context, index) {
                      final flight = flights[index];
                      return FlightCard(
                        flight: flight,
                        compact: false,
                        onTap: () => context.go(
                          AppRoutes.flightDetailPath(flight.id.toString()),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
