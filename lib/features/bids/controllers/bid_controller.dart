// lib/features/bids/controllers/bid_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bid_repository.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../auth/controllers/auth_controller.dart';

final bidRepositoryProvider = Provider<BidRepository>((ref) {
  return BidRepository(ref.read(supabaseClientProvider));
});

// ── All bids for the current user ─────────────────────────────────────────────
final userBidsProvider = FutureProvider<List<BidModel>>((ref) async {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null) return [];
  return ref.read(bidRepositoryProvider).getUserBids(user.id);
});

// ── Price history for a specific flight ───────────────────────────────────────
final priceHistoryProvider = FutureProvider.family<List<double>, int>(
  (ref, flightId) async {
    return ref.read(bidRepositoryProvider).getPriceHistory(flightId);
  },
);

// ── Bid form state — tracks everything the user is filling in ─────────────────
class BidFormState {
  final double bidAmount;
  final int expiryHours;     // 1, 12, or 24
  final String charterOption;
  final bool isSubmitting;
  final String? error;

  const BidFormState({
    this.bidAmount = 0,
    this.expiryHours = 24,
    this.charterOption = 'Full Plane',
    this.isSubmitting = false,
    this.error,
  });

  BidFormState copyWith({
    double? bidAmount,
    int? expiryHours,
    String? charterOption,
    bool? isSubmitting,
    String? error,
  }) {
    return BidFormState(
      bidAmount: bidAmount ?? this.bidAmount,
      expiryHours: expiryHours ?? this.expiryHours,
      charterOption: charterOption ?? this.charterOption,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class BidFormNotifier extends StateNotifier<BidFormState> {
  BidFormNotifier() : super(const BidFormState());

  void setBidAmount(double amount) =>
      state = state.copyWith(bidAmount: amount);

  void setExpiry(int hours) =>
      state = state.copyWith(expiryHours: hours);

  void setCharterOption(String option) =>
      state = state.copyWith(charterOption: option);

  void reset() => state = const BidFormState();
}

final bidFormProvider =
    StateNotifierProvider<BidFormNotifier, BidFormState>((ref) {
  return BidFormNotifier();
});

// ── Place bid action ──────────────────────────────────────────────────────────
class PlaceBidNotifier extends AsyncNotifier<BidModel?> {
  @override
  Future<BidModel?> build() async => null;

  Future<BidModel?> placeBid({
    required int flightId,
    required double bidAmount,
    required String charterOption,
    required int expiryHours,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProfileProvider);
      if (user == null) throw Exception('Not logged in');

      final bid = await ref.read(bidRepositoryProvider).placeBid(
            userId: user.id,
            flightId: flightId,
            bidAmount: bidAmount,
            charterOption: charterOption,
            expiryHours: expiryHours,
          );

      // Refresh the bids list so My Bids tab updates immediately
      ref.invalidate(userBidsProvider);
      return bid;
    });
    return state.value;
  }
}

final placeBidProvider =
    AsyncNotifierProvider<PlaceBidNotifier, BidModel?>(() {
  return PlaceBidNotifier();
});
