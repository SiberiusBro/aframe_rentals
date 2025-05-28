import 'package:aframe_rentals/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser!.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userChats = snapshot.data!.docs;

          if (userChats.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          return ListView.separated(
            itemCount: userChats.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.black12,
              indent: 72,
              endIndent: 16,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final chatDoc = userChats[index];
              final data = chatDoc.data() as Map<String, dynamic>;
              // Determine other participant
              final chatId = chatDoc.id;
              final parts = chatId.split('_');
              final otherUserId = parts.firstWhere((id) => id != currentUser!.uid);
              final placeId = parts.last;
              // Retrieve chat metadata
              final lastMessageText = (data['lastMessage'] ?? '') as String;
              final hasUnread = data['unreadCount_${currentUser!.uid}'] != null &&
                  (data['unreadCount_${currentUser!.uid}'] as int) > 0;
              // Format last message time if available
              String timeDisplay = '';
              if (data['lastMessageTime'] != null) {
                try {
                  final DateTime messageTime = DateTime.parse(data['lastMessageTime']);
                  final now = DateTime.now();
                  if (now.difference(messageTime).inDays == 0) {
                    // same day, show HH:mm
                    timeDisplay = MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(messageTime),
                      alwaysUse24HourFormat: false,
                    );
                  } else {
                    // older, show date
                    timeDisplay =
                        MaterialLocalizations.of(context).formatShortDate(messageTime);
                  }
                } catch (e) {
                  // If parsing fails or stored as Timestamp, handle accordingly
                  if (data['lastMessageTime'] is Timestamp) {
                    final ts = data['lastMessageTime'] as Timestamp;
                    final messageTime = ts.toDate();
                    final now = DateTime.now();
                    if (now.difference(messageTime).inDays == 0) {
                      timeDisplay = MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(messageTime),
                        alwaysUse24HourFormat: false,
                      );
                    } else {
                      timeDisplay =
                          MaterialLocalizations.of(context).formatShortDate(messageTime);
                    }
                  }
                }
              }

              // Build list item with user info, wrapped in Dismissible to enable deletion
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String otherName = otherUserId;
                  String? otherPhoto;
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    otherName = userData['name'] ?? otherName;
                    otherPhoto = userData['photoUrl'] as String?;
                  }
                  return Dismissible(
                    key: ValueKey(chatId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      // Delete all messages in this chat from Firestore
                      final messagesRef = FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages');
                      final messagesSnap = await messagesRef.get();
                      for (var msgDoc in messagesSnap.docs) {
                        await msgDoc.reference.delete();
                      }
                      // Delete the chat document itself
                      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
                      // Show feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Conversation deleted")),
                      );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.black26,
                        backgroundImage: (otherPhoto != null && otherPhoto.isNotEmpty)
                            ? NetworkImage(otherPhoto)
                            : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
                      ),
                      title: Text(
                        otherName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        lastMessageText.isEmpty ? "No messages yet" : lastMessageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: (lastMessageText.isNotEmpty)
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (timeDisplay.isNotEmpty)
                            Text(
                              timeDisplay,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          if (hasUnread) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.circle, color: Colors.red, size: 10),
                          ],
                        ],
                      )
                          : null,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      onTap: () {
                        // Open the chat conversation
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(otherUserId: otherUserId, placeId: placeId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
