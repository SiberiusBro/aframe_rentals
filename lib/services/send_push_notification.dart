import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static const String serverKey = 'eR-TYNsyTA28MObM-9KRc7:APA91bFSVpITkekSZVjdIvOSmA1iSHA1bip6f-QUQiUY7X1JCIAzzsSi5AkNgU-8VuiW46lQWlR5tSvZZW2Gr-nopAGxt5uq_Jj-E8jRcALaonHOejfXTLU';
  static const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent');
      } else {
        print('❌ Failed to send push notification: ${response.body}');
      }
    } catch (e) {
      print('🔥 Error sending push notification: $e');
    }
  }
}
