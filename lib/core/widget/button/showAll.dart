import 'package:flutter/material.dart';

class ShowAllButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback pressed;

  const ShowAllButton({
    super.key,
    this.label = 'Show All',
    this.icon = Icons.grid_view,
    required this.pressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: pressed, // ✅ fixed
         child:Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      ),
    );
  }
}
