import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({
    Key? key,
    required this.sale,
    this.onTap,
  }) : super(key: key);

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = sale.images.isNotEmpty ? sale.images[0] : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Container(
                height: 200,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? RobustNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Icon(
                                Icons.local_offer,
                                size: 50,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.red.shade100,
                        child: Center(
                          child: Icon(
                            Icons.local_offer,
                            size: 50,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
              ),

              // Gradient Overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Sale Badge (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${sale.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Company Logo (Top Left)
              if (sale.companyLogo != null && sale.companyLogo!.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: RobustNetworkImage(
                        imageUrl: sale.companyLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) {
                          return Icon(
                            Icons.business,
                            size: 24,
                            color: AppColors.mainColor,
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Sale Information (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sale Name
                      Text(
                        sale.saleName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),

                      // Description
                      if (sale.description.isNotEmpty)
                        Text(
                          sale.description,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 8),

                      // Prices Row
                      Row(
                        children: [
                          if (sale.oldPrice > 0) ...[
                            // Old Price (strikethrough)
                            Text(
                              'EGP ${_formatPrice(sale.oldPrice)}',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          if (sale.newPrice > 0) ...[
                            // New Price
                            Text(
                              'EGP ${_formatPrice(sale.newPrice)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          Spacer(),
                          // Savings Badge
                          if (sale.savings > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Save ${_formatPrice(sale.savings)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Days Remaining
                      if (sale.daysRemaining > 0) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${sale.daysRemaining.toInt()} days remaining',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
