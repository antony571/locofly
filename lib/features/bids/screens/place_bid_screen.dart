// lib/features/bids/screens/place_bid_screen.dart
//
// The "Place a Bid" screen from Figma (Screen 06).
// Has: route header, market price, big bid amount display,
// savings badge, quick select chips, 7-day price history bar chart,
// expiry selector (1h / 12h / 24h), and Submit Bid button.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/loco_button.dart';
import '../../flights/controllers/flight_controller.dart';
import '../controllers/bid_controller.dart';

class PlaceBidScreen extends ConsumerStatefulWidget {
  final int flightId;
  const PlaceBidScreen({super.key, required this.flightId});

  @override
  ConsumerState<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends ConsumerState<PlaceBidScreen> {
  final _amountController = TextEditingController();
  double _bidAmount = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) =>
      NumberFormat('#,##,###', 'en_IN').format(price);

  // Called when user types in the bid field or taps a quick-select chip
  void _updateAmount(double amount) {
    setState(() => _bidAmount = amount);
    _amountController.text = _formatPrice(amount);
    ref.read(bidFormProvider.notifier).setBidAmount(amount);
  }

  Future<void> _handleSubmit(FlightModel flight) async {
    if (_bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bid amount')),
      );
      return;
    }

    final formState = ref.read(bidFormProvider);

    // Navigate to passenger details before actually placing the bid
    // Passenger details screen will call placeBid after collecting info
    context.go(
      '${AppRoutes.placeBidPath(widget.flightId.toString())}/passengers',
      extra: {
        'flightId': widget.flightId,
        'bidAmount': _bidAmount,
        'charterOption': formState.charterOption,
        'expiryHours': formState.expiryHours,
        'flight': flight,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightDetailProvider(widget.flightId));
    final formState = ref.watch(bidFormProvider);
    final historyAsync = ref.watch(priceHistoryProvider(widget.flightId));

    return flightAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (flight) {
        if (flight == null) return Scaffold(appBar: AppBar());

        final marketPrice = flight.marketPrice;
        final savings = _bidAmount > 0 && _bidAmount < marketPrice
            ? marketPrice - _bidAmount
            : 0.0;
        final savingsPct = marketPrice > 0 && savings > 0
            ? ((savings / marketPrice) * 100).round()
            : 0;

        // Quick select amounts relative to market price
        final quickAmounts = [
          (marketPrice * 0.90).roundToDouble(),
          (marketPrice * 0.95).roundToDouble(),
          (marketPrice * 1.0).roundToDouble(),
          (marketPrice * 1.05).roundToDouble(),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Place a Bid'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Route + market price header ────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${flight.fromCode} → ${flight.toCode}',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${flight.aircraft?.flightNumber ?? ''} · ${flight.aircraft?.airline ?? ''}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Market Price', style: AppTextStyles.caption),
                          Text(
                            '₹${_formatPrice(marketPrice)}',
                            style: AppTextStyles.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── "Your Bid Amount" label ────────────────────────────
                Center(
                  child: Text('Your Bid Amount',
                      style: AppTextStyles.labelMedium),
                ),
                const SizedBox(height: 8),

                // ── Big bid amount display ─────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('₹',
                            style: AppTextStyles.headingLarge),
                      ),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.priceDisplay,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: '0',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (v) {
                            final cleaned = v.replaceAll(',', '');
                            final amount = double.tryParse(cleaned) ?? 0;
                            setState(() => _bidAmount = amount);
                            ref
                                .read(bidFormProvider.notifier)
                                .setBidAmount(amount);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Savings badge ──────────────────────────────────────
                if (savings > 0)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'You save ₹${_formatPrice(savings)} ($savingsPct% off)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Quick select chips ─────────────────────────────────
                Text('Quick Select', style: AppTextStyles.labelMedium),
                const SizedBox(height: 10),
                Row(
                  children: quickAmounts.map((amount) {
                    final isSelected = _bidAmount == amount;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _updateAmount(amount),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '₹${_formatPrice(amount)}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
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

                const SizedBox(height: 24),

                // ── Price history chart ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price History (7 days)',
                        style: AppTextStyles.labelMedium),
                    historyAsync.whenData((data) {
                      if (data.isEmpty) return const SizedBox.shrink();
                      final lowest = data.reduce((a, b) => a < b ? a : b);
                      return Text(
                        'Lowest: ₹${_formatPrice(lowest)}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.success),
                      );
                    }).value ??
                        const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 10),

                // Bar chart using fl_chart
                SizedBox(
                  height: 100,
                  child: historyAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (history) {
                      // If no history yet, show placeholder bars
                      final bars = history.isEmpty
                          ? List.generate(7,
                              (i) => marketPrice * (0.85 + i * 0.02))
                          : history;

                      final maxY =
                          bars.reduce((a, b) => a > b ? a : b) * 1.2;

                      return BarChart(
                        BarChartData(
                          maxY: maxY,
                          barTouchData:
                              BarTouchData(enabled: false),
                          titlesData:
                              FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          barGroups: bars
                              .asMap()
                              .entries
                              .map((e) {
                            final isLast = e.key == bars.length - 1;
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: isLast
                                      ? AppColors.success
                                      : AppColors.primaryLight,
                                  width: 22,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ── Bid expiry selector ────────────────────────────────
                Row(
                  children: [
                    Text('Bid Expires In',
                        style: AppTextStyles.labelMedium),
                    const Spacer(),
                    ...AppConstants.bidExpiryOptions.map((hours) {
                      final isSelected = formState.expiryHours == hours;
                      return GestureDetector(
                        onTap: () => ref
                            .read(bidFormProvider.notifier)
                            .setExpiry(hours),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkButton
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.darkButton
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${hours}h',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Submit button ──────────────────────────────────────
                LCPrimaryButton(
                  label: 'Submit Bid →',
                  onPressed: () => _handleSubmit(flight),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'By bidding, you agree to our Terms & Conditions',
                    style: AppTextStyles.caption,
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
}
