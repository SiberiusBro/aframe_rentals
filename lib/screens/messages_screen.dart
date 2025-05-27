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
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Filter chats that belong to the current user
          final userChats = docs.where((doc) => doc.id.contains(currentUser!.uid)).toList();

          if (userChats.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          return ListView.builder(
            itemCount: userChats.length,
            itemBuilder: (context, index) {
              final chatId = userChats[index].id;
              final parts = chatId.split('_');
              final otherUserId = parts.firstWhere((id) => id != currentUser!.uid);
              final placeId = parts.last;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("Chat with $otherUserId"),
                subtitle: Text("Tap to continue chat"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: otherUserId,
                        placeId: placeId,
                      ),
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
