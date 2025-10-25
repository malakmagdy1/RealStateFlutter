import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_compound_detail_screen.dart';

class WebCompoundCard extends StatelessWidget {
  final Compound compound;

  WebCompoundCard({Key? key, required this.compound}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFFE6E6E6),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebCompoundDetailScreen(compoundId: compound.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.mainColor.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: compound.images != null && compound.images!.isNotEmpty
                    ? RobustNetworkImage(
                        imageUrl: 
                        compound.images!.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (compound.companyLogo != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 36,
                              height: 36,
                              color: Color(0xFFF8F9FA),
                              padding: EdgeInsets.all(4),
                              child: RobustNetworkImage(
                        imageUrl: 
                                compound.companyLogo!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (context, url) =>
                                    SizedBox.shrink(),
                              ),
                            ),
                          ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                compound.project,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                compound.companyName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF666666),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF666666),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            compound.location,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: compound.status == 'delivered'
                                ? Color(0x264CAF50)
                                : Color(0x26FF9800),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            compound.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: compound.status == 'delivered'
                                  ? Color(0xFF388E3C)
                                  : Color(0xFFF57C00),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.phone,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Handle phone call
                            },
                            padding: EdgeInsets.zero,
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
      height: 180,
      width: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Text(
          '🏘️',
          style: TextStyle(fontSize: 64),
        ),
      ),
    );
  }
}
