import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';

class GridCompoundList extends StatelessWidget {
  final List<Compound> compounds;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final int crossAxisCount;
  final double childAspectRatio;

  const GridCompoundList({
    Key? key,
    required this.compounds,
    this.isLoading = false,
    this.emptyTitle = 'No compounds',
    this.emptySubtitle = 'Start adding compounds!',
    this.emptyIcon = Icons.apartment,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (compounds.isEmpty) {
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
      itemCount: compounds.length,
      itemBuilder: (context, index) {
        return SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: CompoundsName(compound: compounds[index]),
        );
      },
    );
  }
}
