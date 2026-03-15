import 'package:flutter/material.dart';

class MapSection extends StatelessWidget {
  const MapSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
