import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aframe_rentals/screens/add_place_screen.dart';
import 'package:aframe_rentals/screens/account_details_screen.dart';
import 'package:aframe_rentals/screens/account_details_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    _reloadUser();
  }

  Future<void> _reloadUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profile",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    Icon(Icons.notifications_outlined, size: 35),
                  ],
                ),
                const SizedBox(height: 25),

                /// Entire row is tappable now
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountDetailsScreen()),
                    );
                    _reloadUser(); // reload in case of updates
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.black54,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ),
                      SizedBox(width: size.width * 0.06),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'No Name',
                              style: const TextStyle(fontSize: 20, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Show profile",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),


                const SizedBox(height: 10),
                const Divider(color: Colors.black12),
                const SizedBox(height: 10),

                Card(
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text.rich(
                          TextSpan(
                            text: "Stay Finder!\n",
                            style: TextStyle(
                              height: 2.5,
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: "Having a rental place? \nPublish it here!.",
                                style: TextStyle(
                                  height: 1.2,
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Image.network(
                          "https://static.vecteezy.com/system/resources/previews/034/950/530/non_2x/ai-generated-small-house-with-flowers-on-transparent-background-image-png.png",
                          height: 140,
                          width: 135,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.black12),
                const SizedBox(height: 15),
                const Text("Settings", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountDetailsScreen(),
                      ),
                    );
                  },

                  child: profileInfo(Icons.person_2_outlined, "Personal information"),
                ),
                profileInfo(Icons.security, "Login & security"),
                profileInfo(Icons.payments_outlined, "Payments and payouts"),
                profileInfo(Icons.settings_outlined, "Accessibility"),
                profileInfo(Icons.note_outlined, "Taxes"),
                profileInfo(Icons.translate, "Translation"),
                profileInfo(Icons.notifications_outlined, "Notifications"),
                profileInfo(Icons.lock_outline, "Privacy and sharing"),
                profileInfo(Icons.card_travel, "Travel for work"),

                const SizedBox(height: 15),
                const Text("Hosting", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25)),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPlaceScreen()));
                  },
                  child: profileInfo(Icons.add_home_outlined, "List your space"),
                ),
                profileInfo(Icons.home_outlined, "Learn about hosting"),

                const SizedBox(height: 15),
                const Text("Support", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25)),
                const SizedBox(height: 25),
                profileInfo(Icons.help_outline, "Visit the Help Center"),
                profileInfo(Icons.health_and_safety_outlined, "Get help with a safety issue"),
                profileInfo(Icons.ac_unit, "How StayFinder works"),
                profileInfo(Icons.edit_outlined, "Give us feedback"),

                const SizedBox(height: 15),
                const Text("Legal", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25)),
                const SizedBox(height: 25),
                profileInfo(Icons.menu_book_outlined, "Terms of Service"),
                profileInfo(Icons.menu_book_outlined, "Privacy Policy"),
                profileInfo(Icons.menu_book_outlined, "Open source licenses"),

                const SizedBox(height: 10),
                const Text(
                  "Log out",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.black12),
                const SizedBox(height: 20),
                const Text("Version 24.34 (28004615)", style: TextStyle(fontSize: 10)),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding profileInfo(IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 35, color: Colors.black.withOpacity(0.7)),
              const SizedBox(width: 20),
              Text(name, style: const TextStyle(fontSize: 17)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12),
        ],
      ),
    );
  }
}