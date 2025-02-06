import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/background_container.dart';

class ManageCabinsScreen extends StatefulWidget {
  const ManageCabinsScreen({super.key});

  @override
  ManageCabinsScreenState createState() => ManageCabinsScreenState();
}

class ManageCabinsScreenState extends State<ManageCabinsScreen> {
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
              return const Center(child: SpinKitFadingCube(color: Colors.indigo,size: 50.0,));
            }
            if (!snapshot.hasData ||
                snapshot.data?.snapshot.value == null ||
                (snapshot.data!.snapshot.value as Map).isEmpty) {
              return const Center(
                child: Text(
                  'No cabins found.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final Map<dynamic, dynamic> cabins =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            return ListView(
              children: cabins.entries.map((entry) {
                final Map cabinData = entry.value;

                // Sa nu existe nimic null pentru erori
                final String imageUrl =
                    (cabinData['imageUrl'] as String?) ?? '';
                final String title =
                    (cabinData['title'] as String?) ?? 'No Title';
                final double price = cabinData['price'] != null
                    ? double.tryParse(cabinData['price'].toString()) ?? 0.0
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey,
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
                    title: Text(title),
                    subtitle: Text("\$$price per night"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // De editat
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await dbRef.child(entry.key).remove();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Cabin deleted successfully')),
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
