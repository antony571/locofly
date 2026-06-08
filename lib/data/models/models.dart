// lib/data/models/flight_model.dart
//
// A "model" is a Dart class that represents one row from a database table.
// When Supabase returns JSON like {"id": 1, "from_city": "Mumbai", ...},
// we parse it into a FlightModel object so Dart knows all the field types.
//
// fromJson()  → converts Supabase JSON response → Dart object
// toJson()    → converts Dart object → JSON (for creating/updating records)

class FlightModel {
  final int id;
  final int aircraftId;
  final String fromCity;
  final String fromCode;          // Airport code e.g. BOM
  final String toCity;
  final String toCode;            // Airport code e.g. DEL
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMins;
  final int distanceKm;
  final double marketPrice;       // Base charter price shown to users
  final String status;            // 'available' | 'closed' | 'completed'
  final DateTime createdAt;

  // Joined data (when we fetch flights with aircraft details)
  // nullable because sometimes we fetch flights without joining aircraft
  final AircraftModel? aircraft;

  const FlightModel({
    required this.id,
    required this.aircraftId,
    required this.fromCity,
    required this.fromCode,
    required this.toCity,
    required this.toCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMins,
    required this.distanceKm,
    required this.marketPrice,
    required this.status,
    required this.createdAt,
    this.aircraft,
  });

  // Parse from Supabase JSON.
  // The Map<String, dynamic> type means: a map with String keys and any value type.
  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id'] as int,
      aircraftId: json['aircraft_id'] as int,
      fromCity: json['from_city'] as String,
      fromCode: json['from_code'] as String,
      toCity: json['to_city'] as String,
      toCode: json['to_code'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      durationMins: json['duration_mins'] as int,
      distanceKm: json['distance_km'] as int,
      marketPrice: (json['market_price'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // If 'aircraft' key exists in the response (from a join), parse it
      aircraft: json['aircraft'] != null
          ? AircraftModel.fromJson(json['aircraft'] as Map<String, dynamic>)
          : null,
    );
  }

  // Computed helpers — logic derived from the model data
  bool get isAvailable => status == 'available';
  bool get isSoldOut => status == 'closed';

  // Format duration as "2h 30m"
  String get durationFormatted {
    final hours = durationMins ~/ 60;   // ~/ is integer division
    final mins = durationMins % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

// ─── Aircraft model ───────────────────────────────────────────────────────────
class AircraftModel {
  final int id;
  final String name;              // e.g. Bombardier
  final String type;              // e.g. Airbus A320neo
  final String airline;           // e.g. IndiGo
  final String flightNumber;      // e.g. 6E-206
  final int passengersCapacity;
  final int rangeKm;
  final List<String> amenities;   // ['WiFi', 'Catering', 'Bar', ...]
  final List<String> charterBenefits;
  final List<String> images;      // URLs to images in Supabase Storage
  final DateTime createdAt;

  const AircraftModel({
    required this.id,
    required this.name,
    required this.type,
    required this.airline,
    required this.flightNumber,
    required this.passengersCapacity,
    required this.rangeKm,
    required this.amenities,
    required this.charterBenefits,
    required this.images,
    required this.createdAt,
  });

  factory AircraftModel.fromJson(Map<String, dynamic> json) {
    // jsonb fields from Supabase come as List<dynamic> — we cast each item to String
    final amenitiesRaw = json['amenities'] as List<dynamic>? ?? [];
    final benefitsRaw = json['charter_benefits'] as List<dynamic>? ?? [];
    final imagesRaw = json['images'] as List<dynamic>? ?? [];

    return AircraftModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      airline: json['airline'] as String,
      flightNumber: json['flight_number'] as String,
      passengersCapacity: json['passengers_capacity'] as int,
      rangeKm: json['range_km'] as int,
      amenities: amenitiesRaw.map((e) => e.toString()).toList(),
      charterBenefits: benefitsRaw.map((e) => e.toString()).toList(),
      images: imagesRaw.map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Bid model ────────────────────────────────────────────────────────────────
class BidModel {
  final int id;
  final String userId;
  final int flightId;
  final double bidAmount;
  final double advancePaid;
  final String charterOption;   // 'Full Plane' | '+ Catering' | 'VIP Setup'
  final String status;          // 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'expired'
  final DateTime expiresAt;
  final String? cancelReason;
  final DateTime createdAt;

  // Joined data
  final FlightModel? flight;

  const BidModel({
    required this.id,
    required this.userId,
    required this.flightId,
    required this.bidAmount,
    required this.advancePaid,
    required this.charterOption,
    required this.status,
    required this.expiresAt,
    this.cancelReason,
    required this.createdAt,
    this.flight,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      flightId: json['flight_id'] as int,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      advancePaid: (json['advance_paid'] as num).toDouble(),
      charterOption: json['charter_option'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      flight: json['flights'] != null
          ? FlightModel.fromJson(json['flights'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  // Is the bid still active (can be cancelled by user)?
  bool get isActive => status == 'pending';

  // Has the bid expired?
  bool get hasExpired => DateTime.now().isAfter(expiresAt);
}

// ─── Booking model ────────────────────────────────────────────────────────────
class BookingModel {
  final int id;
  final int bidId;
  final String userId;
  final int flightId;
  final String bookingReference;  // e.g. LF-2024-8847
  final String charterOption;
  final double totalAmount;
  final double taxes;
  final double discount;
  final String? eticketUrl;       // null until PDF is generated
  final String status;            // 'confirmed' | 'cancelled' | 'completed'
  final DateTime createdAt;

  // Joined data
  final FlightModel? flight;

  const BookingModel({
    required this.id,
    required this.bidId,
    required this.userId,
    required this.flightId,
    required this.bookingReference,
    required this.charterOption,
    required this.totalAmount,
    required this.taxes,
    required this.discount,
    this.eticketUrl,
    required this.status,
    required this.createdAt,
    this.flight,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      bidId: json['bid_id'] as int,
      userId: json['user_id'] as String,
      flightId: json['flight_id'] as int,
      bookingReference: json['booking_reference'] as String,
      charterOption: json['charter_option'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      taxes: (json['taxes'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      eticketUrl: json['eticket_url'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      flight: json['flights'] != null
          ? FlightModel.fromJson(json['flights'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── User model ───────────────────────────────────────────────────────────────
class UserModel {
  final String id;              // uuid from Supabase Auth
  final String? fullName;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? currentCity;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.fullName,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.currentCity,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      currentCity: json['current_city'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Special offer model ──────────────────────────────────────────────────────
class SpecialOfferModel {
  final int id;
  final int flightId;
  final String title;
  final String description;
  final double offerPrice;
  final int discountPercent;
  final DateTime validUntil;

  const SpecialOfferModel({
    required this.id,
    required this.flightId,
    required this.title,
    required this.description,
    required this.offerPrice,
    required this.discountPercent,
    required this.validUntil,
  });

  factory SpecialOfferModel.fromJson(Map<String, dynamic> json) {
    return SpecialOfferModel(
      id: json['id'] as int,
      flightId: json['flight_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      offerPrice: (json['offer_price'] as num).toDouble(),
      discountPercent: json['discount_percent'] as int,
      validUntil: DateTime.parse(json['valid_until'] as String),
    );
  }

  bool get isActive => DateTime.now().isBefore(validUntil);
}

// ─── Notification model ───────────────────────────────────────────────────────
class NotificationModel {
  final int id;
  final String userId;
  final int? bookingId;
  final String type;      // 'bid_accepted' | 'bid_rejected' | 'outbid' | 'booking_confirmed'
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as int?,
      type: json['type'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
