//services/cloud_notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudNotificationService {
  static const String cloudFunctionUrl =
      'https://us-central1-afframe-rental.cloudfunctions.net/sendNotification';

  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent via Cloud Function!');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error calling Cloud Function: $e');
    }
  }
}
