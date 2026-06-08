// lib/data/repositories/notification_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class NotificationRepository {
  final SupabaseClient _supabase;
  NotificationRepository(this._supabase);

  // Get all notifications for the user, newest first
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableNotifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  // Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    await _supabase
        .from(AppConstants.tableNotifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Count unread notifications — used for the bell badge on home screen
  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableNotifications)
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }
}
