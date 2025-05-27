class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['senderId'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
