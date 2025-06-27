import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://localhost/EcommerceClothingApp/API';

  // Get notifications with pagination and filters
  static Future<Map<String, dynamic>> getNotifications({
    required int userId,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (type != null) queryParams['type'] = type;
      if (isRead != null) queryParams['is_read'] = isRead ? '1' : '0';

      final uri = Uri.parse('$baseUrl/notifications/get_notifications.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Get unread notification count
  static Future<Map<String, dynamic>> getUnreadCount({
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/get_unread_count.php')
          .replace(queryParameters: {'user_id': userId.toString()});

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markAsRead({
    required int userId,
    int? notificationId,
    bool markAll = false,
  }) async {
    try {
      final body = {
        'user_id': userId,
      };

      if (markAll) {
        body['mark_all'] = 1;
      } else if (notificationId != null) {
        body['notification_id'] = notificationId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark_read.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Add notification (for admin use)
  static Future<Map<String, dynamic>> addNotification({
    required int userId,
    required String title,
    String? content,
    String type = 'other',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/add_notification.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'title': title,
          'content': content,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
} 