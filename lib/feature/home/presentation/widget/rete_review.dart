import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

/// ⭐ Clickable star rating widget
class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final Function(int) onChanged;

  StarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: isFilled ? 1.2 : 1.0,
              duration: Duration(milliseconds: 150),
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: size,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// ⭐ Static stars (non-interactive)
class StaticStars extends StatelessWidget {
  final int rating;
  final double size;

  StaticStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

/// 💬 Review Card
class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.mainColor,
                  child: CustomText16(
                    review['userName'][0].toUpperCase(),
                    color: AppColors.white,
                    bold: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText16(
                        review['userName'],
                        bold: true,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          StaticStars(rating: review['rating']),
                          SizedBox(width: 6),
                          CustomText16(
                            review['date'],
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            CustomText16(
              review['comment'],
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 Rating Distribution Bar
class RatingBar extends StatelessWidget {
  final String stars;
  final double percentage;

  RatingBar({
    super.key,
    required this.stars,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CustomText16(stars, bold: true),
          SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: AppColors.grey),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(width: 8),
          CustomText16(
            '${(percentage * 100).toInt()}%',
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}
