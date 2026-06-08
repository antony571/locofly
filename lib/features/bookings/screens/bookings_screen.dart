// lib/features/bookings/screens/bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/models.dart';
import '../controllers/booking_controller.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Could not load bookings',
                  style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(userBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_num_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No bookings yet',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Your confirmed bids will appear here',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userBookingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              itemBuilder: (context, index) => _BookingCard(
                booking: bookings[index],
                onTap: () => context.go(
                  AppRoutes.bookingDetailPath(bookings[index].id.toString()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'completed': return AppColors.textSecondary;
      default: return AppColors.primary;
    }
  }

  Color get _statusBg {
    switch (booking.status) {
      case 'confirmed': return AppColors.successLight;
      case 'cancelled': return AppColors.errorLight;
      default: return AppColors.surfaceAlt;
    }
  }

  String _formatPrice(double price) =>
      NumberFormat('#,##,###', 'en_IN').format(price);

  @override
  Widget build(BuildContext context) {
    final flight = booking.flight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            // Top: route + status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Flight icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flight,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (flight != null)
                          Text(
                            '${flight.fromCity} → ${flight.toCity}',
                            style: AppTextStyles.headingSmall,
                          ),
                        Text(
                          booking.bookingReference,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status[0].toUpperCase() +
                          booking.status.substring(1),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _statusColor),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Bottom: date + amount + charter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (flight != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: AppTextStyles.caption),
                        Text(
                          DateFormat('d MMM yyyy')
                              .format(flight.departureTime),
                          style: AppTextStyles.labelMedium,
                        ),
                      ],
                    ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Charter', style: AppTextStyles.caption),
                      Text(booking.charterOption,
                          style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: AppTextStyles.caption),
                      Text(
                        '₹${_formatPrice(booking.totalAmount)}',
                        style: AppTextStyles.priceMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
