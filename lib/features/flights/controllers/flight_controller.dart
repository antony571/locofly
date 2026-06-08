// lib/features/flights/controllers/flight_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/flight_repository.dart';
import '../../../data/supabase/supabase_client.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  return FlightRepository(ref.read(supabaseClientProvider));
});

// ── Search params — what the user typed in the search form ───────────────────
class FlightSearchParams {
  final String fromCity;
  final String toCity;
  final DateTime? date;
  const FlightSearchParams({
    this.fromCity = '',
    this.toCity = '',
    this.date,
  });
}

final flightSearchParamsProvider = StateProvider<FlightSearchParams>((ref) {
  return const FlightSearchParams();
});

// ── All flights (with optional filters) ──────────────────────────────────────
// FutureProvider.family lets us pass params to an async provider
final flightsProvider = FutureProvider.family<List<FlightModel>, FlightSearchParams>(
  (ref, params) async {
    return ref.read(flightRepositoryProvider).getFlights(
          fromCity: params.fromCity,
          toCity: params.toCity,
          date: params.date,
        );
  },
);

// ── Single flight detail ──────────────────────────────────────────────────────
final flightDetailProvider = FutureProvider.family<FlightModel?, int>(
  (ref, id) async {
    return ref.read(flightRepositoryProvider).getFlightById(id);
  },
);

// ── Nearby flights (uses device location) ────────────────────────────────────
final nearbyFlightsProvider = FutureProvider<List<FlightModel>>((ref) async {
  // We'll get location from the home screen controller
  // For now fall back to all flights
  return ref.read(flightRepositoryProvider).getFlights();
});

// ── Special offers ────────────────────────────────────────────────────────────
final specialOffersProvider = FutureProvider<List<SpecialOfferModel>>((ref) async {
  return ref.read(flightRepositoryProvider).getSpecialOffers();
});

// ── Top bid for a flight ──────────────────────────────────────────────────────
final topBidProvider = FutureProvider.family<double?, int>((ref, flightId) async {
  return ref.read(flightRepositoryProvider).getTopBid(flightId);
});
