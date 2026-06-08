// lib/features/bookings/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/booking_controller.dart';

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  String _formatPrice(double price) =>
      NumberFormat('#,##,###', 'en_IN').format(price);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return bookingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (booking) {
        if (booking == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Booking not found')));
        }
        final flight = booking.flight;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Booking Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── E-ticket card ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFFFCA6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.airplanemode_active,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('LocoFly',
                              style: AppTextStyles.headingSmall
                                  .copyWith(color: Colors.white)),
                          const Spacer(),
                          Text('E-TICKET',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 2)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Route
                      if (flight != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(flight.fromCode,
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                Text(flight.fromCity,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                            const Icon(Icons.airplanemode_active,
                                color: Colors.white, size: 28),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(flight.toCode,
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                Text(flight.toCity,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 12),

                      // Reference + date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BOOKING REF',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      letterSpacing: 1)),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: booking.bookingReference));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Reference copied!')),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(booking.bookingReference,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy,
                                        size: 14, color: Colors.white60),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (flight != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('DATE',
                                    style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        letterSpacing: 1)),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('d MMM yyyy')
                                      .format(flight.departureTime),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Booking breakdown ──────────────────────────────────
                _sectionCard(
                  title: 'Payment Breakdown',
                  children: [
                    _row('Charter Option', booking.charterOption),
                    _row('Subtotal',
                        '₹${_formatPrice(booking.totalAmount - booking.taxes + booking.discount)}'),
                    if (booking.discount > 0)
                      _row('Discount',
                          '- ₹${_formatPrice(booking.discount)}',
                          valueColor: AppColors.success),
                    _row('Taxes & Fees', '₹${_formatPrice(booking.taxes)}'),
                    const Divider(),
                    _row('Total Amount',
                        '₹${_formatPrice(booking.totalAmount)}',
                        bold: true),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Flight info ────────────────────────────────────────
                if (flight != null)
                  _sectionCard(
                    title: 'Flight Info',
                    children: [
                      _row('Aircraft',
                          flight.aircraft?.name ?? 'N/A'),
                      _row('Airline',
                          flight.aircraft?.airline ?? 'N/A'),
                      _row('Flight No.',
                          flight.aircraft?.flightNumber ?? 'N/A'),
                      _row('Duration', flight.durationFormatted),
                      _row('Distance', '${flight.distanceKm} km'),
                    ],
                  ),

                const SizedBox(height: 24),

                // ── E-ticket button ────────────────────────────────────
                if (booking.eticketUrl != null)
                  LCPrimaryButton(
                    label: 'Download E-Ticket',
                    icon: Icons.download,
                    onPressed: () async {
                      final uri = Uri.parse(booking.eticketUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                else
                  LCOutlinedButton(
                    label: 'E-Ticket being generated...',
                    onPressed: null,
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: bold
                ? AppTextStyles.labelLarge.copyWith(color: valueColor)
                : AppTextStyles.labelMedium.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
