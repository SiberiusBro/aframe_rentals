import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aframe_rentals/components/display_place.dart';
import 'package:aframe_rentals/components/display_total_price.dart';
import 'package:aframe_rentals/components/map_with_custom_info_windows.dart';
import 'package:aframe_rentals/components/search_bar_and_filter.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/models/category.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SearchBarAndFilter(),
            categorySelector(size),
            const DisplayTotalPrice(),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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

                  final all = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Place.fromJson(data);
                  }).toList();

                  final filtered = selectedCategoryId == 'all'
                      ? all
                      : all.where((p) => p.categoryId == selectedCategoryId).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return DisplayPlace(place: filtered[index]);
                    },
                  );
                },
              ),
            ),
          ],
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
