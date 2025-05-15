class Place {
  final String? id;
  final String title;
  final String categoryId; // ✅ NEW
  bool isActive;
  final String image;
  final double rating;
  final String date;
  final int price;
  final String address;
  final String vendor;
  final String vendorProfession;
  final String vendorProfile;
  final int review;
  final String bedAndBathroom;
  final int yearOfHostin;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;

  Place({
    this.id,
    required this.title,
    required this.categoryId, // ✅ NEW
    required this.isActive,
    required this.image,
    required this.rating,
    required this.date,
    required this.price,
    required this.address,
    required this.vendor,
    required this.vendorProfession,
    required this.vendorProfile,
    required this.review,
    required this.bedAndBathroom,
    required this.yearOfHostin,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      title: json['title'],
      categoryId: json['categoryId'] ?? '', // ✅ NEW
      isActive: json['isActive'],
      image: json['image'],
      rating: (json['rating'] ?? 0).toDouble(),
      date: json['date'],
      price: json['price'],
      address: json['address'],
      vendor: json['vendor'],
      vendorProfession: json['vendorProfession'],
      vendorProfile: json['vendorProfile'],
      review: json['review'],
      bedAndBathroom: json['bedAndBathroom'],
      yearOfHostin: json['yearOfHostin'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'categoryId': categoryId, // ✅ NEW
      'isActive': isActive,
      'image': image,
      'rating': rating,
      'date': date,
      'price': price,
      'address': address,
      'vendor': vendor,
      'vendorProfession': vendorProfession,
      'vendorProfile': vendorProfile,
      'review': review,
      'bedAndBathroom': bedAndBathroom,
      'yearOfHostin': yearOfHostin,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
    };
  }
}
