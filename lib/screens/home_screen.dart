import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/background_container.dart';
import 'aframes_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("cabins");

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String nickname =
        user?.displayName ?? (user?.email?.split('@')[0] ?? 'User');

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        title: Text('Welcome back, $nickname!'),
      ),
      body: BackgroundContainer(
        child: StreamBuilder<DatabaseEvent>(
          stream: _dbRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SpinKitFadingCube(color: Colors.indigo,size: 50.0,));
            }
            if (!snapshot.hasData ||
                snapshot.data?.snapshot.value == null ||
                (snapshot.data!.snapshot.value as Map).isEmpty) {
              return const Center(
                child: Text(
                  'No cabins added yet.\nStay tuned!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final Map<dynamic, dynamic> cabins =
            (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

            return ListView(
              children: cabins.entries.map((entry) {
                final cabinData = entry.value;
                // Sa nu existe null pentru erori
                final String imageUrl = (cabinData['imageUrl'] as String?) ?? '';
                final String title =
                    (cabinData['title'] as String?) ?? 'No Title';
                final double price = cabinData['price'] != null
                    ? double.tryParse(cabinData['price'].toString()) ?? 0.0
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Se executa navigarea catre pagina Cabanei
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CabinDetailScreen(cabinData: cabinData),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(
                              child: SpinKitFadingCube(color: Colors.indigo,size: 50.0,),
                            ),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          )
                              : Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey,
                            child: const Center(
                              child: Text(
                                'No Image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4),
                          child: Text(
                            '\$$price per night',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 12),
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
