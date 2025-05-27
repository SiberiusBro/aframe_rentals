import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final void Function(double)? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  void _handleTap(int index) {
    final newRating = index + 1.0;
    if (widget.onChanged != null) {
      setState(() => _currentRating = newRating);
      widget.onChanged!(newRating);
    }
  }

  Widget buildStar(int index) {
    final isFilled = index < _currentRating.round();
    return GestureDetector(
      onTap: widget.onChanged != null ? () => _handleTap(index) : null,
      child: Icon(
        Icons.star,
        size: 22,
        color: isFilled ? Colors.black : Colors.black26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, buildStar),
    );
  }
}
