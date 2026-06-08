// lib/features/bids/screens/my_bids_screen.dart
//
// The "Bids" tab — shows all bids placed by the user with status badges,
// flight route, bid amount, expiry, and a cancel option for pending bids.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/bid_controller.dart';

class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(userBidsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Bids')),
      body: bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Could not load bids', style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(userBidsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bids) {
          if (bids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No bids yet', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Browse flights and place your first bid',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userBidsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bids.length,
              itemBuilder: (context, index) {
                final bid = bids[index];
                return _BidCard(bid: bid, onCancel: () async {
                  await ref.read(bidRepositoryProvider).cancelBid(
                    bid.id, 'Cancelled by user');
                  ref.invalidate(userBidsProvider);
                });
              },
            ),
          );
        },
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final bid;
  final VoidCallback onCancel;

  const _BidCard({required this.bid, required this.onCancel});

  Color get _statusColor {
    switch (bid.status) {
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'cancelled': return AppColors.textTertiary;
      case 'expired': return AppColors.warning;
      default: return AppColors.primary; // pending
    }
  }

  Color get _statusBg {
    switch (bid.status) {
      case 'accepted': return AppColors.successLight;
      case 'rejected': return AppColors.errorLight;
      case 'cancelled': return AppColors.surfaceAlt;
      case 'expired': return AppColors.warningLight;
      default: return AppColors.primaryLight;
    }
  }

  String get _statusLabel {
    switch (bid.status) {
      case 'accepted': return 'Accepted ✓';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      case 'expired': return 'Expired';
      default: return 'Pending';
    }
  }

  String _formatPrice(double price) =>
      NumberFormat('#,##,###', 'en_IN').format(price);

  @override
  Widget build(BuildContext context) {
    final flight = bid.flight;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: route + status badge
            Row(
              children: [
                if (flight != null) ...[
                  Text(
                    '${flight.fromCode} → ${flight.toCode}',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flight.aircraft?.airline ?? '',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: _statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bid amount + charter option
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Bid', style: AppTextStyles.caption),
                    Text(
                      '₹${_formatPrice(bid.bidAmount)}',
                      style: AppTextStyles.priceMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Charter', style: AppTextStyles.caption),
                    Text(bid.charterOption,
                        style: AppTextStyles.labelMedium),
                  ],
                ),
                const Spacer(),
                // Expiry
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Expires', style: AppTextStyles.caption),
                    Text(
                      timeago.format(bid.expiresAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: bid.hasExpired
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Cancel button — only shown for pending bids
            if (bid.isPending) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showCancelDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Cancel Bid',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Bid?'),
        content: const Text(
          'Are you sure you want to cancel this bid? '
          'The advance paid may not be refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Bid'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
