//models/booking_notification_model.dart
class BookingNotification {
  final String title;
  final String body;
  final DateTime timestamp;

  BookingNotification({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory BookingNotification.fromJson(Map<String, dynamic> json) {
    return BookingNotification(
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
