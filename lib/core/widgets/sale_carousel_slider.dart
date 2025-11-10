import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature_web/compound/presentation/web_compound_detail_screen.dart';
import 'package:go_router/go_router.dart';

class SaleCarouselSlider extends StatefulWidget {
  final List<Sale> sales;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final bool isWeb;

  const SaleCarouselSlider({
    Key? key,
    required this.sales,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(seconds: 2),
    this.isWeb = false,
  }) : super(key: key);

  @override
  State<SaleCarouselSlider> createState() => _SaleCarouselSliderState();
}

class _SaleCarouselSliderState extends State<SaleCarouselSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  void _navigateToDetails(BuildContext context, Sale sale) {
    if (widget.isWeb) {
      // Web navigation using GoRouter
      if (sale.unitId != null && sale.unitId!.isNotEmpty) {
        // Navigate to web unit detail screen
        context.push('/unit/${sale.unitId}');
      } else if (sale.compoundId != null && sale.compoundId!.isNotEmpty) {
        // Navigate to web compound detail screen
        context.push('/compound/${sale.compoundId}');
      }
    } else {
      // Mobile navigation using Navigator
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
          unitNumber: sale.itemName,
          createdAt: sale.createdAt,
          updatedAt: sale.updatedAt,
          images: sale.images,
          usageType: sale.saleType,
          companyName: sale.companyName,
          companyLogo: sale.companyLogo,
          compoundName: sale.compoundName,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailScreen(unit: unit),
          ),
        );
      } else if (sale.compoundId != null && sale.compoundId!.isNotEmpty) {
        // Navigate to compound detail if it's a compound sale
        context.push('/compound-detail/${sale.compoundId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sales.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer,
                size: 40,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 8),
              Text(
                'No active sales',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carousel Slider
        CarouselSlider.builder(
          itemCount: widget.sales.length,
          carouselController: _controller,
          options: CarouselOptions(
            autoPlay: widget.autoPlay,
            height: widget.height,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            autoPlayAnimationDuration: widget.autoPlayAnimationDuration,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayCurve: Curves.easeInOutSine,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
            scrollPhysics: const BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index, realIdx) {
            final sale = widget.sales[index];
            final isActive = index == _currentIndex;
            final imageUrl = sale.images.isNotEmpty ? sale.images[0] : '';

            return Padding(
              padding: EdgeInsets.only(top: isActive ? 0 : 15),
              child: GestureDetector(
                onTap: () => _navigateToDetails(context, sale),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        if (imageUrl.isNotEmpty)
                          RobustNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: widget.height,
                            errorBuilder: (context, url) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
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
                                      child: Text(
                                        sale.saleName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                  sale.compoundName != null && sale.compoundName!.isNotEmpty
                                      ? '${sale.itemName} • ${sale.compoundName}'
                                      : sale.itemName,
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
                                    if (sale.oldPrice > 0) ...[
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
                                    ],
                                    if (sale.newPrice > 0) ...[
                                      // New Price
                                      Text(
                                        'EGP ${_formatPrice(sale.newPrice)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    Spacer(),
                                    // Savings
                                    if (sale.savings > 0)
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
                        if (sale.companyLogo != null && sale.companyLogo!.isNotEmpty)
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
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url) {
                                    return Icon(
                                      Icons.business,
                                      size: 20,
                                      color: AppColors.mainColor,
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
              ),
            );
          },
        ),

        // Dot Indicator - positioned below the carousel
        SizedBox(height: 12),
        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: widget.sales.length,
            effect: ExpandingDotsEffect(
              radius: 10,
              dotWidth: 10,
              dotHeight: 10,
              activeDotColor: AppColors.mainColor,
              expansionFactor: 4,
              dotColor: AppColors.mainColor.withOpacity(0.3),
            ),
            onDotClicked: (index) {
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
          ),
        ),
      ],
    );
  }
}
