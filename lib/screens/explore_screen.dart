import 'package:aframe_rentals/screens/place_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aframe_rentals/components/display_place.dart';
import 'package:aframe_rentals/components/map_with_custom_info_windows.dart';
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
  String searchQuery = '';
  double minPrice = 0;
  double maxPrice = 2000;
  double minReview = 0;
  double maxReview = 5;
  bool filtersActive = false;

  double filterMinPrice = 0;
  double filterMaxPrice = 2000;
  double filterMinReview = 0;
  double filterMaxReview = 5;

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

  void openFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        double tempMinPrice = filterMinPrice;
        double tempMaxPrice = filterMaxPrice;
        double tempMinReview = filterMinReview;
        double tempMaxReview = filterMaxReview;
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 10),
                const Text("Price Range"),
                RangeSlider(
                  min: 0,
                  max: 2000,
                  divisions: 20,
                  labels: RangeLabels("${tempMinPrice.toInt()}", "${tempMaxPrice.toInt()}"),
                  values: RangeValues(tempMinPrice, tempMaxPrice),
                  onChanged: (v) => setState(() {
                    tempMinPrice = v.start;
                    tempMaxPrice = v.end;
                  }),
                ),
                const Text("Review Range"),
                RangeSlider(
                  min: 0,
                  max: 5,
                  divisions: 5,
                  labels: RangeLabels("${tempMinReview.toStringAsFixed(1)}", "${tempMaxReview.toStringAsFixed(1)}"),
                  values: RangeValues(tempMinReview, tempMaxReview),
                  onChanged: (v) => setState(() {
                    tempMinReview = v.start;
                    tempMaxReview = v.end;
                  }),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          filterMinPrice = 0;
                          filterMaxPrice = 2000;
                          filterMinReview = 0;
                          filterMaxReview = 5;
                          filtersActive = false;
                        });
                      },
                      child: const Text("Clear All"),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filterMinPrice = tempMinPrice;
                          filterMaxPrice = tempMaxPrice;
                          filterMinReview = tempMinReview;
                          filterMaxReview = tempMaxReview;
                          filtersActive = filterMinPrice != 0 || filterMaxPrice != 2000 || filterMinReview != 0 || filterMaxReview != 5;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Apply"),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: openFilterDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: filtersActive ? Colors.blueAccent : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.filter_list,
                            color: filtersActive ? Colors.white : Colors.black54, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // TAGS
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
                            const SizedBox(width: 5),
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
                  final allPlaces = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return Place.fromJson(data);
                  }).toList();

                  // Apply Search
                  List<Place> filtered = allPlaces.where((p) {
                    final matchesTag = selectedTag == 'All' || p.placeTag == selectedTag;
                    final matchesSearch = searchQuery.isEmpty
                        || p.title.toLowerCase().contains(searchQuery.toLowerCase())
                        || p.address.toLowerCase().contains(searchQuery.toLowerCase());
                    final matchesPrice = (p.price >= filterMinPrice && p.price <= filterMaxPrice);
                    final matchesReview = (p.rating >= filterMinReview && p.rating <= filterMaxReview);
                    return matchesTag && matchesSearch && matchesPrice && matchesReview;
                  }).toList();

                  // Prepare favorites list for horizontal display
                  final favoritePlaces = allPlaces.where((place) {
                    final isFavorite = provider.favorites.contains(place.id);
                    final matchesTag = selectedTag == 'All' || place.placeTag == selectedTag;
                    final matchesSearch = searchQuery.isEmpty
                        || place.title.toLowerCase().contains(searchQuery.toLowerCase())
                        || place.address.toLowerCase().contains(searchQuery.toLowerCase());
                    final matchesPrice = (place.price >= filterMinPrice && place.price <= filterMaxPrice);
                    final matchesReview = (place.rating >= filterMinReview && place.rating <= filterMaxReview);
                    return isFavorite && matchesTag && matchesSearch && matchesPrice && matchesReview;
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
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: Text("No places found for these filters.")),
                        )
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const MapWithCustomInfoWindows(),
    );
  }
}
