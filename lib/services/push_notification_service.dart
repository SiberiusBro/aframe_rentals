// ✅ Step 1: Add this service to your services/ directory
// File: lib/services/push_notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    const String serverKey = 'eR-TYNsyTA28MObM-9KRc7:APA91bFSVpITkekSZVjdIvOSmA1iSHA1bip6f-QUQiUY7X1JCIAzzsSi5AkNgU-8VuiW46lQWlR5tSvZZW2Gr-nopAGxt5uq_Jj-E8jRcALaonHOejfXTLU'; // Replace with your FCM Server Key

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'priority': 'high',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }
}
