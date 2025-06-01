//screens/chat_screen.dart
import 'package:aframe_rentals/models/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_profile_screen.dart';

const Color kMyChatBubbleColor = Color(0xFF0084FF); // Messenger-like blue
const Color kOtherChatBubbleColor = Color(0xFFEFEFEF); // Light grey for others
const TextStyle kMyMessageTextStyle = TextStyle(color: Colors.white, fontSize: 16);
const TextStyle kOtherMessageTextStyle = TextStyle(color: Colors.black87, fontSize: 16);
const TextStyle kMyMessageTimeStyle = TextStyle(fontSize: 10, color: Colors.white70);
const TextStyle kOtherMessageTimeStyle = TextStyle(fontSize: 10, color: Colors.black54);

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String placeId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.placeId,
  }) : assert(otherUserId != '' && placeId != '');

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _controller = TextEditingController();
  late final String chatId;
  String? otherUserName;
  String? otherUserPhoto;

  @override
  void initState() {
    super.initState();
    chatId = _generateChatId();
    // Mark messages as read for current user
    FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser!.uid, widget.otherUserId],
      'placeId': widget.placeId,
      'unreadCount_${currentUser!.uid}': 0,
    }, SetOptions(merge: true));
    // Load other user profile for display
    _loadOtherUserProfile();
    // Load current user's name if needed for participant names
    _updateParticipantNames();
  }

  String _generateChatId() {
    final ids = [currentUser!.uid, widget.otherUserId]..sort();
    return "${ids[0]}_${ids[1]}_${widget.placeId}";
  }

  Future<void> _loadOtherUserProfile() async {
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
    if (userSnap.exists) {
      final data = userSnap.data()!;
      setState(() {
        otherUserName = data['name'] ?? widget.otherUserId;
        otherUserPhoto = data['photoUrl'];
      });
    } else {
      setState(() {
        otherUserName = widget.otherUserId;
        otherUserPhoto = null;
      });
    }
  }

  Future<void> _updateParticipantNames() async {
    try {
      final otherSnap = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
      final currentSnap = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      String name1 = currentSnap.data()?['name'] ?? currentUser!.displayName ?? 'Unknown';
      String name2 = otherSnap.data()?['name'] ?? otherUserName ?? 'Unknown';
      FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participantNames': {
          currentUser!.uid: name1,
          widget.otherUserId: name2,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle errors (e.g., if user docs don't exist)
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final message = ChatMessage(
      senderId: currentUser!.uid,
      text: text,
      timestamp: DateTime.now(),
    );
    // Add message to Firestore
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());
    // Update chat thread metadata (last message, unread count for recipient, timestamp)
    FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastMessageSender': currentUser!.uid,
      'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      'unreadCount_${currentUser!.uid}': 0, // current user has seen their own message
      'participants': [currentUser!.uid, widget.otherUserId], // ensure participants field is present
      'placeId': widget.placeId,
    }, SetOptions(merge: true));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navigate to other user's public profile
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.otherUserId)),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black26,
                backgroundImage: (otherUserPhoto != null && otherUserPhoto!.isNotEmpty)
                    ? NetworkImage(otherUserPhoto!)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 8),
              Text(
                otherUserName ?? "Chat",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Say hello!"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;
                    // Parse timestamp
                    DateTime timestamp;
                    try {
                      timestamp = DateTime.parse(data['timestamp']);
                    } catch (e) {
                      if (data['timestamp'] is Timestamp) {
                        timestamp = (data['timestamp'] as Timestamp).toDate();
                      } else {
                        timestamp = DateTime.now();
                      }
                    }
                    final timeStr = DateFormat('HH:mm').format(timestamp);
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? kMyChatBubbleColor : kOtherChatBubbleColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(data['text'], style: isMe ? kMyMessageTextStyle : kOtherMessageTextStyle),
                            const SizedBox(height: 4),
                            Text(timeStr, style: isMe ? kMyMessageTimeStyle : kOtherMessageTimeStyle),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      fillColor: Colors.grey[100],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
