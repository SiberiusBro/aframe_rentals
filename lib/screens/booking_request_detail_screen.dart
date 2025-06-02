import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/cloud_notification_service.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';


class BookingRequestDetailScreen extends StatefulWidget {
  final String reservationId;
  final String requesterId;
  final Map<String, dynamic> reservationData;

  const BookingRequestDetailScreen({
    super.key,
    required this.reservationId,
    required this.requesterId,
    required this.reservationData,
  });

  @override
  State<BookingRequestDetailScreen> createState() => _BookingRequestDetailScreenState();
}

class _BookingRequestDetailScreenState extends State<BookingRequestDetailScreen> {
  Map<String, dynamic>? requesterProfile;
  bool _accepting = false;
  bool _declining = false;

  @override
  void initState() {
    super.initState();
    _loadRequesterProfile();
  }

  Future<void> _loadRequesterProfile() async {
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.requesterId).get();
    if (userSnap.exists) {
      setState(() {
        requesterProfile = userSnap.data();
      });
    }
  }

  String _generateChatId(String hostId, String guestId, String placeId) {
    final ids = [hostId, guestId]..sort();
    return '${ids[0]}_${ids[1]}_$placeId';
  }

  Future<String> _ensureChatExists() async {
    final hostId = widget.reservationData['ownerId'];
    final guestId = widget.requesterId;
    final placeId = widget.reservationData['placeId'];
    final chatId = _generateChatId(hostId, guestId, placeId);

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      await chatRef.set({
        'participants': [hostId, guestId],
        'placeId': placeId,
        'lastMessage': '',
        'lastMessageTime': null,
        'unreadCount_$hostId': 0,
        'unreadCount_$guestId': 0,
      });
    }
    return chatId;
  }

  Future<void> _acceptReservationAndCreateChatAndOpen() async {
    setState(() => _accepting = true);

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.reservationId)
        .update({'status': 'accepted'});

    await _ensureChatExists();

    setState(() => _accepting = false);

    // Save values before pop
    final guestId = widget.requesterId;
    final placeId = widget.reservationData['placeId'];

    // 1. Pop and wait for navigation to finish
    if (mounted) Navigator.of(context).pop();

    // 2. Use a global navigator key or root context, or use a callback from parent

    // For simplicity: push to chat after pop using the root navigator context
    // (Assuming you're returning to a parent screen that can call push to ChatScreen.)
    // Otherwise, you can use a callback or pass a BuildContext down from the parent.

    // One safe workaround:
    Future.delayed(const Duration(milliseconds: 350), () {
      // Find a valid context (like using a globalKey), or just let parent handle push
      // Here's the quick workaround with root navigator:
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: guestId,
            placeId: placeId,
          ),
        ),
      );
    });

    // Optionally, also use a root context for Snackbar:
    // (or move the snackbar to the parent screen)
    // ScaffoldMessenger.of(context, rootNavigator: true).showSnackBar(...)
  }

  Future<void> _declineReservationWithReason() async {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedReason;
        TextEditingController descriptionController = TextEditingController();
        List<String> reasons = [
          "Double booking",
          "Dates unavailable",
          "Other"
        ];
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Decline Booking"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...reasons.map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  title: Text(reason),
                  onChanged: (value) => setState(() => selectedReason = value),
                )),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: "Add more details (optional)",
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Decline"),
                onPressed: () async {
                  if (selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pick a reason.")),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  await _doDecline(selectedReason!, descriptionController.text.trim());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doDecline(String reason, String description) async {
    setState(() => _declining = true);
    // 1. Update reservation in Firestore
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.reservationId)
        .update({
      'status': 'declined',
      'declineReason': reason,
      'declineDescription': description,
    });

    // 2. Get guest's device token
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.requesterId)
        .get();
    final guestToken = userSnap.data()?['deviceToken'];

    // 3. Send FCM notification
    if (guestToken != null && guestToken is String && guestToken.isNotEmpty) {
      await CloudNotificationService.sendNotification(
        token: guestToken,
        title: "Booking Declined",
        body: "Reason: $reason${description.isNotEmpty ? "\n$description" : ""}",
      );
    }

    setState(() => _declining = false);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation declined. Guest notified.')));
  }

  Future<void> _openChat() async {
    final hostId = widget.reservationData['ownerId'];
    final guestId = widget.requesterId;
    final placeId = widget.reservationData['placeId'];
    await _ensureChatExists();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: guestId,
          placeId: placeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservationData;
    final startDateFormatted = DateFormat('yMMMd').format(DateTime.parse(res['startDate']));
    final endDateFormatted = DateFormat('yMMMd').format(DateTime.parse(res['endDate']));
    final status = res['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              res['placeTitle'] ?? "",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

// "Booking request:" label
            const Text(
              "Booking request:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),

// The oval user chip (as in previous message)
            if (requesterProfile != null) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: widget.requesterId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (requesterProfile!['photoUrl'] != null &&
                            requesterProfile!['photoUrl'].toString().isNotEmpty)
                            ? NetworkImage(requesterProfile!['photoUrl'])
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: (requesterProfile!['photoUrl'] == null ||
                            requesterProfile!['photoUrl'].toString().isEmpty)
                            ? Text(
                          (requesterProfile!['name'] ?? '')
                              .toString()
                              .isNotEmpty
                              ? requesterProfile!['name'][0].toUpperCase()
                              : "?",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        requesterProfile!['name'] ?? "Unknown",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (requesterProfile != null) ...[
              Text("Payment Method: ${res['paymentMethod'] ?? '-'}"),
              const SizedBox(height: 8),
            ],
            Text("From: $startDateFormatted"),
            Text("To: $endDateFormatted"),
            Text(
              "Status: ${status[0].toUpperCase()}${status.substring(1)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == 'accepted'
                    ? Colors.green
                    : status == 'declined'
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            if (status == 'declined' && res['declineReason'] != null) ...[
              const SizedBox(height: 12),
              Text("Decline Reason: ${res['declineReason']}", style: const TextStyle(color: Colors.red)),
              if (res['declineDescription'] != null && res['declineDescription'].toString().isNotEmpty)
                Text("More info: ${res['declineDescription']}", style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat"),
                  onPressed: _openChat,
                ),
                const SizedBox(width: 12),
                if (status == 'pending') ...[
                  ElevatedButton(
                    child: _accepting
                        ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _accepting ? null : _acceptReservationAndCreateChatAndOpen,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    child: _declining
                        ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Decline"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _declining ? null : _declineReservationWithReason,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}