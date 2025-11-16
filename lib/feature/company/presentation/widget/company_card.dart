import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/core/animations/hover_scale_animation.dart';
import 'package:real/core/utils/card_dimensions.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback? onTap;
  final bool showMargin;

  const CompanyCard({
    Key? key,
    required this.company,
    this.onTap,
    this.showMargin = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: showMargin ? EdgeInsets.symmetric(horizontal: 12, vertical: 6) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company Logo Section - Fixed height
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                ),
                child: company.logo != null && company.logo!.isNotEmpty
                    ? RobustNetworkImage(
                        imageUrl: company.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Company Info Section - Compact
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Company Name
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: AppColors.mainColor),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),

                    // Email - Compact
                    if (company.email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 12, color: AppColors.greyText),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.greyText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    if (company.email.isNotEmpty) SizedBox(height: 6),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(height: 6),

                    // Stats Row - Compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.apartment,
                          company.numberOfCompounds,
                          'Compounds',
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          Icons.home_work,
                          company.numberOfAvailableUnits,
                          'Units',
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
    return Center(
      child: Icon(
        Icons.business,
        size: 60,
        color: AppColors.mainColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.mainColor),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.greyText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
