// lib/features/bookings/controllers/booking_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../auth/controllers/auth_controller.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(supabaseClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(supabaseClientProvider));
});

// All bookings for the current user
final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null) return [];
  return ref.read(bookingRepositoryProvider).getUserBookings(user.id);
});

// Single booking detail
final bookingDetailProvider =
    FutureProvider.family<BookingModel?, int>((ref, id) async {
  return ref.read(bookingRepositoryProvider).getBookingById(id);
});

// All notifications for the current user
final userNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null) return [];
  return ref
      .read(notificationRepositoryProvider)
      .getUserNotifications(user.id);
});

// Unread count — drives the bell badge on home screen
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null) return 0;
  return ref.read(notificationRepositoryProvider).getUnreadCount(user.id);
});
