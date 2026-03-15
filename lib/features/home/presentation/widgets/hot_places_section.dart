import 'package:flutter/material.dart';

class HotPlacesSection extends StatelessWidget {
  const HotPlacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
