import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';

/// Web-specific sale slider widget
/// Navigates to web unit detail screen instead of mobile version
class WebSaleSlider extends StatefulWidget {
  final List<Sale> sales;

  const WebSaleSlider({Key? key, required this.sales}) : super(key: key);

  @override
  State<WebSaleSlider> createState() => _WebSaleSliderState();
}

class _WebSaleSliderState extends State<WebSaleSlider> {
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Automatically change slide every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (widget.sales.isEmpty) return;

      int nextPage = (_currentPage + 1) % widget.sales.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
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
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              final imageUrl = sale.images.isNotEmpty ? sale.images[0] : '';

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Only navigate if this is a unit sale (not compound sale)
                    if (sale.unitId != null && sale.unitId!.isNotEmpty) {
                      // Create a Unit object from the sale data
                      final unit = Unit(
                        id: sale.unitId!,
                        compoundId: sale.compoundId ?? '',
                        unitType: sale.itemName,
                        area: '0',
                        price: sale.newPrice.toString(),
                        bedrooms: '0',
                        bathrooms: '0',
                        floor: '0',
                        status: 'available',
                        createdAt: DateTime.now().toIso8601String(),
                        updatedAt: DateTime.now().toIso8601String(),
                        images: sale.images,
                        companyId: sale.companyId,
                        companyLogo: sale.companyLogo,
                        companyName: sale.companyName ?? '',
                        compoundName: sale.compoundName,
                        gardenArea: '',
                        roofArea: '',
                        usageType: '',
                        buildingName: '',
                        unitNumber: '',
                        deliveryDate: '',
                        view: '',
                      );

                      // Navigate to WEB unit detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebUnitDetailScreen(
                            unitId: unit.id,
                            unit: unit,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mainColor.withOpacity(0.9),
                          AppColors.mainColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background Image with overlay
                        if (imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: RobustNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, url) => Container(
                                  color: AppColors.mainColor.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),

                        // Dark overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.black.withOpacity(0.3),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Discount Badge
                                if (sale.discountPercentage > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${sale.discountPercentage.toStringAsFixed(0)}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Sale Name
                                Text(
                                  sale.saleName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // Price Row
                                Row(
                                  children: [
                                    // Old Price
                                    if (sale.oldPrice > 0)
                                      Text(
                                        'EGP ${_formatPrice(sale.oldPrice)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),

                                    const SizedBox(width: 12),

                                    // New Price
                                    Text(
                                      'EGP ${_formatPrice(sale.newPrice)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Company Logo
                                if (sale.companyLogo != null &&
                                    sale.companyLogo!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: RobustNetworkImage(
                                      imageUrl: sale.companyLogo!,
                                      height: 30,
                                      width: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, url) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                              ],
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

          // Page Indicator
          if (widget.sales.length > 1)
            Positioned(
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.sales.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
