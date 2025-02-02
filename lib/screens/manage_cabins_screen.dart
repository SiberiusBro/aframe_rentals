import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/background_container.dart';

class ManageCabinsScreen extends StatefulWidget {
  const ManageCabinsScreen({super.key});

  @override
  _ManageCabinsScreenState createState() => _ManageCabinsScreenState();
}

class _ManageCabinsScreenState extends State<ManageCabinsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("cabins");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Cabins')),
      body: BackgroundContainer(
        child: StreamBuilder<DatabaseEvent>(
          stream: dbRef.orderByChild("userId").equalTo(user?.uid).onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(
                child: Text(
                  'No cabins found.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final Map<dynamic, dynamic> cabins =
            (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

            return ListView(
              children: cabins.entries.map((entry) {
                final Map cabinData = entry.value;
                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Image.network(
                      cabinData['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(cabinData['title']),
                    subtitle: Text("\$${cabinData['price']} per night"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await dbRef.child(entry.key).remove();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cabin deleted successfully')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
