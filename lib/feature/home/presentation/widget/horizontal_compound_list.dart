import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';

class HorizontalCompoundList extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<Compound> compounds;
  final bool isLoading;
  final String emptyMessage;
  final Color? badgeGradientStart;
  final Color? badgeGradientEnd;
  final Color? progressColor;
  final double height;
  final double itemWidth;

  const HorizontalCompoundList({
    Key? key,
    required this.title,
    this.icon,
    this.iconColor,
    required this.compounds,
    this.isLoading = false,
    this.emptyMessage = 'No compounds available',
    this.badgeGradientStart,
    this.badgeGradientEnd,
    this.progressColor,
    this.height = 280.0,
    this.itemWidth = 220.0,
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
              child: CustomText20(
                title,
                bold: true,
                color: AppColors.black,
              ),
            ),
            if (compounds.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      badgeGradientStart ?? AppColors.mainColor,
                      badgeGradientEnd ?? AppColors.mainColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${compounds.length}',
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
            : compounds.isEmpty
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
                    height: height,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: compounds.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: itemWidth,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          child: AnimatedListItem(
                            index: index,
                            delay: Duration(milliseconds: 100),
                            child: CompoundsName(compound: compounds[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
