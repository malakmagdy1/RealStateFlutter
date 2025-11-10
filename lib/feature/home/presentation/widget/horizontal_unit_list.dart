import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';

class HorizontalUnitList extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<Unit> units;
  final bool isLoading;
  final String emptyMessage;
  final Color? badgeGradientStart;
  final Color? badgeGradientEnd;
  final Color? progressColor;

  const HorizontalUnitList({
    Key? key,
    required this.title,
    this.icon,
    this.iconColor,
    required this.units,
    this.isLoading = false,
    this.emptyMessage = 'No units available',
    this.badgeGradientStart,
    this.badgeGradientEnd,
    this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.mainColor, size: 24),
              SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            if (units.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      badgeGradientStart ?? Color(0xFFFF3B30),
                      badgeGradientEnd ?? Color(0xFFFF6B6B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${units.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),

        // Content
        isLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: progressColor ?? AppColors.mainColor,
                  ),
                ),
              )
            : units.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text(
                            emptyMessage,
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: units.length,
                      itemBuilder: (context, index) {
                        return AnimatedListItem(
                          index: index,
                          delay: Duration(milliseconds: 100),
                          child: Container(
                            width: 180,
                            margin: EdgeInsets.only(right: 12),
                            child: UnitCard(unit: units[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
