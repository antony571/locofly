// lib/features/flights/widgets/flight_card.dart
//
// The flight card shown in both the Home "Flights Near You" section
// and the Flight List screen. Shows airline, route, time, bid status.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/models.dart';

class FlightCard extends StatelessWidget {
  final FlightModel flight;
  final double? topBid;
  final VoidCallback? onTap;
  final VoidCallback? onBidTap;
  // compact = the horizontal card on home screen
  // full = the larger card on flight list screen
  final bool compact;

  const FlightCard({
    super.key,
    required this.flight,
    this.topBid,
    this.onTap,
    this.onBidTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompactCard(context) : _buildFullCard(context);
  }

  // ── Compact card (Home screen — image + route + bid button) ───────────────
  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aircraft image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  _buildAircraftImage(height: 140),
                  // Distance badge (top left)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${(flight.distanceKm / 100).toStringAsFixed(1)} km away',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aircraft name + airline
                  Text(
                    flight.aircraft?.name ?? 'Aircraft',
                    style: AppTextStyles.headingSmall,
                  ),
                  Text(
                    flight.aircraft?.airline ?? '',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // Route row
                  _buildRouteRow(),
                  const SizedBox(height: 12),

                  // Top bid + Place Bid button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top Bid', style: AppTextStyles.caption),
                          Text(
                            topBid != null
                                ? '₹${_formatPrice(topBid!)}'
                                : '₹${_formatPrice(flight.marketPrice)}',
                            style: AppTextStyles.priceMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onBidTap ?? onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text('Place Bid', style: AppTextStyles.labelLarge),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
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

  // ── Full card (Flight List screen) ────────────────────────────────────────
  Widget _buildFullCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Aircraft image on the left
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: _buildAircraftImage(width: 110, height: 110),
            ),

            // Flight info on the right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Airline + status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${flight.fromCode} → ${flight.toCode} · ${flight.aircraft?.airline ?? ''}',
                            style: AppTextStyles.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Times
                    _buildRouteRow(compact: true),
                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${_formatPrice(flight.marketPrice)}',
                          style: AppTextStyles.priceMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: AppColors.textTertiary, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared route row (BOM ✈ DEL with times) ──────────────────────────────
  Widget _buildRouteRow({bool compact = false}) {
    final timeFormat = DateFormat('HH:mm');
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flight.fromCode,
                style: compact
                    ? AppTextStyles.headingSmall
                    : AppTextStyles.headingMedium),
            Text(_formatTime(flight.departureTime),
                style: AppTextStyles.bodySmall),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.airplanemode_active,
                  size: 18, color: AppColors.primary),
              Text(flight.durationFormatted, style: AppTextStyles.caption),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(flight.toCode,
                style: compact
                    ? AppTextStyles.headingSmall
                    : AppTextStyles.headingMedium),
            Text(_formatTime(flight.arrivalTime),
                style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }

  // ── Aircraft image with fallback ──────────────────────────────────────────
  Widget _buildAircraftImage({double? width, double? height}) {
    final images = flight.aircraft?.images ?? [];
    if (images.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: images.first,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _imagePlaceholder(width: width, height: height),
        errorWidget: (_, __, ___) => _imagePlaceholder(width: width, height: height),
      );
    }
    return _imagePlaceholder(width: width, height: height);
  }

  Widget _imagePlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.airplanemode_active, size: 40, color: AppColors.primary),
      ),
    );
  }

  // ── Status badge (Available / Sold Out) ───────────────────────────────────
  Widget _buildStatusBadge() {
    final isAvailable = flight.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Sold Out',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isAvailable ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  String _formatPrice(double price) =>
      NumberFormat('#,##,###', 'en_IN').format(price);

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
}
