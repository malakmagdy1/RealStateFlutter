import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/share_bottom_sheet.dart';

class WebUnitCard extends StatelessWidget {
  final Unit unit;

  WebUnitCard({Key? key, required this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasImages = unit.images != null && unit.images!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebUnitDetailScreen(unit: unit),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.mainColor.withOpacity(0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              if (hasImages)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      RobustNetworkImage(
                        imageUrl: unit.images!.first,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) => _buildPlaceholder(),
                      ),
                      // Share Button
                      Positioned(
                        top: 10,
                        left: 10,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ShareBottomSheet(
                                  type: 'unit',
                                  id: unit.id,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.share,
                                size: 18,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Status Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: unit.status == 'available'
                                ? Color(0xFF4CAF50)
                                : Color(0xFFF44336),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            unit.status == 'available' ? 'Available' : 'Sold',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content section
              Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Type Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.mainColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        unit.unitType,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Unit Details
                    _buildDetailRow(
                      Icons.bed_outlined,
                      '${unit.bedrooms} Beds',
                      Icons.bathtub_outlined,
                      '${unit.bathrooms} Baths',
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.square_foot_outlined,
                          size: 18,
                          color: AppColors.mainColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${unit.area} m²',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),

                    // Divider
                    Container(
                      height: 1,
                      color: Color(0xFFE6E6E6),
                    ),
                    SizedBox(height: 18),

                    // Price and Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatPrice(unit.price)} EGP',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mainColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mainColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Icon(
          Icons.home_outlined,
          size: 50,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon1, String label1, IconData icon2, String label2) {
    return Row(
      children: [
        Icon(icon1, size: 18, color: AppColors.mainColor),
        SizedBox(width: 6),
        Text(
          label1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(width: 20),
        Icon(icon2, size: 18, color: AppColors.mainColor),
        SizedBox(width: 6),
        Text(
          label2,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  String _formatPrice(String price) {
    try {
      final value = double.parse(price);
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}K';
      }
      return value.toStringAsFixed(0);
    } catch (e) {
      return price;
    }
  }
}
