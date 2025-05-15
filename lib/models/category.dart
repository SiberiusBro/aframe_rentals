class Category {
  final String id;
  final String title;
  final String image;

  Category({
    required this.id,
    required this.title,
    required this.image,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      title: data['title'] ?? '',
      image: data['image'] ?? '',
    );
  }
}
