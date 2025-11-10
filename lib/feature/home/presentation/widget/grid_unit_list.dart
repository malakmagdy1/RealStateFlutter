import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';

class GridUnitList extends StatelessWidget {
  final List<Unit> units;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final int crossAxisCount;
  final double childAspectRatio;

  const GridUnitList({
    Key? key,
    required this.units,
    this.isLoading = false,
    this.emptyTitle = 'No units',
    this.emptySubtitle = 'Start adding units!',
    this.emptyIcon = Icons.home,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 20,
                color: AppColors.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        return UnitCard(unit: units[index]);
      },
    );
  }
}
