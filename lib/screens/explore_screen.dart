//screens/explore_screen.dart
import 'package:aframe_rentals/screens/place_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aframe_rentals/components/display_place.dart';
import 'package:aframe_rentals/components/map_with_custom_info_windows.dart';
import 'package:aframe_rentals/components/search_bar_and_filter.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/models/category.dart';
import 'package:aframe_rentals/services/the_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Map<String, dynamic>> tags = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Beach', 'icon': Icons.beach_access},
    {'name': 'Mountain', 'icon': Icons.terrain},
    {'name': 'Rural', 'icon': Icons.grass},
    {'name': 'Urban', 'icon': Icons.location_city},
  ];
  String? selectedTag = 'All';
  List<Category> categories = [];
  String? selectedCategoryId;
  List<Place> allPlaces = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final loaded = snapshot.docs.map((doc) {
      return Category.fromFirestore(doc.id, doc.data());
    }).toList();

    setState(() {
      categories = [
        Category(id: 'all', title: 'All', image: 'https://cdn-icons-png.flaticon.com/512/709/709496.png'),
        ...loaded
      ];
      selectedCategoryId = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final provider = TheProvider.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SearchBarAndFilter(),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tag['icon'], size: 16),
                            SizedBox(width: 5),
                            Text(tag['name']),
                          ],
                        ),
                        selected: selectedTag == tag['name'],
                        onSelected: (_) {
                          setState(() => selectedTag = tag['name']);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No places available."));
                  }
                  // Map all active places into Place objects
                  final allPlaces = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return Place.fromJson(data);
                  }).toList();
                  // Filter places by selected category
                  final filtered = allPlaces.where((p) {
                    // filter by category
                    final matchesCategory = true;
                    final matchesTag = selectedTag == 'All' || p.placeTag == selectedTag;
                    return matchesCategory && matchesTag;
                  }).toList();

                  // Prepare favorites list for horizontal display
                  final favoritePlaces = allPlaces.where((place) {
                    final isFavorite = provider.favorites.contains(place.id);
                    final matchesTag = selectedTag == 'All' || place.placeTag == selectedTag;
                    return isFavorite && matchesTag;
                  }).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (favoritePlaces.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(
                            "Your Favorites",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: size.height * 0.25,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: favoritePlaces.length,
                            itemBuilder: (context, index) {
                              final favPlace = favoritePlaces[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 15 : 10,
                                  right: index == favoritePlaces.length - 1 ? 15 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: favPlace)),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: size.width * 0.6,
                                          child: Image.network(
                                            favPlace.image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Icon(Icons.favorite, color: Colors.red),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Container(
                                            color: Colors.black.withOpacity(0.6),
                                            padding: const EdgeInsets.all(4),
                                            child: Text(
                                              favPlace.title,
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (filtered.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 6),
                          child: Text(
                            "Explore",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],

                      // Category selector and places list
                      //categorySelector(size),
                      const SizedBox(height: 10),
                      ...filtered.map((place) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                            );
                          },
                          child: DisplayPlace(place: place),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const MapWithCustomInfoWindows(), // map only
    );
  }

  Widget categorySelector(Size size) {
    return SizedBox(
      height: size.height * 0.12,
      child: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategoryId == cat.id;

          return GestureDetector(
            onTap: () {
              setState(() => selectedCategoryId = cat.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Image.network(
                    cat.image,
                    height: 32,
                    width: 32,
                    color: isSelected ? Colors.black : Colors.black45,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.black : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 40,
                    color: isSelected ? Colors.black : Colors.transparent,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
