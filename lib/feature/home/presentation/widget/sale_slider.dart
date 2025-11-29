import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';

class SaleSlider extends StatefulWidget {
  final List<Sale> sales;

  SaleSlider({super.key, required this.sales});

  @override
  State<SaleSlider> createState() => _SaleSliderState();
}

class _SaleSliderState extends State<SaleSlider> {
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Automatically change slide every 3 seconds
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (widget.sales.isEmpty) return;

      int nextPage = (_currentPage + 1) % widget.sales.length;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

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
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.sales.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final sale = widget.sales[index];
              final imageUrl = sale.images.isNotEmpty
                  ? sale.images[0]
                  : '';

              print('==================== SALE DEBUG ====================');
              print('[SALE SLIDER] Sale Name: ${sale.saleName}');
              return GestureDetector(
                onTap: () {
                  // Only navigate if this is a unit sale (not compound sale)
                  if (sale.unitId != null && sale.unitId!.isNotEmpty) {
                    // Create a Unit object from the sale data
                    final unit = Unit(
                      id: sale.unitId!,
                      compoundId: sale.compoundId ?? '',
                      unitType: sale.itemName,
                      area: '0', // Not available in sale data
                      price: sale.newPrice.toString(),
                      bedrooms: '0', // Not available in sale data
                      bathrooms: '0', // Not available in sale data
                      floor: '0', // Not available in sale data
                      status: 'available', // Assuming available if on sale
                      unitNumber: sale.itemName, // Use item name as unit number
                      createdAt: sale.createdAt,
                      updatedAt: sale.updatedAt,
                      images: sale.images,
                      usageType: sale.saleType,
                      companyName: sale.companyName,
                      companyLogo: sale.companyLogo,
                      compoundName: sale.compoundName,
                    );

                    // Navigate to Unit Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitDetailScreen(unit: unit),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      if (imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: RobustNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: AppColors.greyText,
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
                          ),
                        )
                      else
                        Container(color: Colors.grey.shade200),

                      // Gradient Overlay
                      Container(
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

                      // Sale Information
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sale Name with Discount Badge
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomText18(
                                      sale.saleName,
                                      color: Colors.white,
                                      bold: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${sale.discountPercentage.toStringAsFixed(0)}% OFF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              // Item Name & Compound
                              Text(
                                '${sale.itemName} • ${sale.compoundName}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              // Prices
                              Row(
                                children: [
                                  // Old Price (strikethrough)
                                  Text(
                                    'EGP ${_formatPrice(sale.oldPrice)}',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // New Price
                                  Text(
                                    'EGP ${_formatPrice(sale.newPrice)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  // Savings
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Save ${_formatPrice(sale.savings)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Company Logo (Top Left)
                      if (sale.companyLogo != null &&
                          sale.companyLogo!.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 40,
                            height: 40,
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
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, url) {
                                  return Center(
                                    child: Icon(
                                      Icons.business,
                                      size: 20,
                                      color: AppColors.mainColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Dot Indicator
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.sales.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 10 : 6,
                  height: _currentPage == index ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
