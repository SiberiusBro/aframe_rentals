class Place {
  final String? id;
  final String title;
  final String categoryId;
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
  final String? description;
  final int? guests;
  final int? beds;
  final int? bathrooms;

  Place({
    this.id,
    required this.title,
    required this.categoryId,
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
    required this.description,
    required this.guests,
    required this.beds,
    required this.bathrooms,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      title: json['title'] ?? '',
      categoryId: json['categoryId'] ?? '',
      isActive: json['isActive'] ?? true,
      image: json['image'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      price: json['price'] ?? 0,
      address: json['address'] ?? '',
      vendor: json['vendor'] ?? json['userId'] ?? '',
      vendorProfession: json['vendorProfession'] ?? '',
      vendorProfile: json['vendorProfile'] ?? '',
      review: json['review'] ?? 0,
      bedAndBathroom: json['bedAndBathroom'] ?? '',
      yearOfHostin: json['yearOfHostin'] ?? 0,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      description: json['description'] ?? '',
      guests: json['guests'],
      beds: json['beds'],
      bathrooms: json['bathrooms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'categoryId': categoryId,
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
      'description': description,
      'guests': guests,
      'beds': beds,
      'bathrooms': bathrooms,
    };
  }
}
