import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../data/models/unit_model.dart';
import '../../data/web_services/compound_web_services.dart';
import '../../../sale/data/models/sale_model.dart';
import '../../../sale/presentation/widgets/sales_person_selector.dart';

class UnitDetailScreen extends StatefulWidget {
  static const String routeName = '/unit-detail';
  final Unit unit;

  const UnitDetailScreen({Key? key, required this.unit}) : super(key: key);

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  int _currentImageIndex = 0;
  late PageController _imagePageController;
  Timer? _autoSlideTimer;
  final CompoundWebServices _compoundWebServices = CompoundWebServices();

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    // Only start auto-slide if there are multiple images
    if (widget.unit.images.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          final nextIndex = (_currentImageIndex + 1) % widget.unit.images.length;
          _imagePageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return price;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Color _getStatusColor() {
    switch (widget.unit.status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'sold':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showSalespeople() async {
    try {
      // Use compound ID as the search parameter since we don't have compound name in Unit model
      final response = await _compoundWebServices.getSalespeopleByCompound(widget.unit.compoundId);

      if (response['success'] == true && response['salespeople'] != null) {
        final salespeople = (response['salespeople'] as List)
            .map((sp) => SalesPerson.fromJson(sp as Map<String, dynamic>))
            .toList();

        if (salespeople.isNotEmpty && mounted) {
          SalesPersonSelector.show(
            context,
            salesPersons: salespeople,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noSalesPersonAvailable),
              backgroundColor: AppColors.mainColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = widget.unit.images.isNotEmpty;
    final displayImage = hasImages
        ? widget.unit.images[_currentImageIndex]
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: hasImages ? 300 : 120,
            pinned: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _showSalespeople,
                tooltip: l10n.contactSales,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Company Logo
                  if (widget.unit.companyLogo != null && widget.unit.companyLogo!.isNotEmpty)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: RobustNetworkImage(
                          imageUrl: widget.unit.companyLogo!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, url) => Icon(
                            Icons.business,
                            size: 20,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 20,
                        color: AppColors.mainColor,
                      ),
                    ),
                  // Unit Name
                  Flexible(
                    child: CustomText18(
                      '${l10n.unit} ${widget.unit.unitNumber ?? widget.unit.id}',
                      bold: true,
                      color: hasImages ? AppColors.white : AppColors.black,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              background: hasImages
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image Slider
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: widget.unit.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return RobustNetworkImage(
                              imageUrl: widget.unit.images[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorBuilder: (context, url) {
                                print(
                                  '[IMAGE ERROR] Failed to load image: $url',
                                );
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Gradient overlay
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
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Dot Indicators (only show if multiple images)
                        if (widget.unit.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.unit.images.length,
                                (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.shade200,
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.unit.companyName != null && widget.unit.companyName!.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (widget.unit.companyLogo != null && widget.unit.companyLogo!.isNotEmpty)
                              ClipOval(
                                child: RobustNetworkImage(
                                  imageUrl: widget.unit.companyLogo!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url) => Container(
                                    width: 50,
                                    height: 50,
                                    color: AppColors.grey,
                                    child: Icon(Icons.business, color: AppColors.white),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.business, color: AppColors.mainColor),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText16(
                                    l10n.developer,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText18(
                                    widget.unit.companyName!,
                                    bold: true,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Unit Type and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText16(
                              l10n.unitType,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 4),
                            CustomText24(
                              widget.unit.usageType ?? widget.unit.unitType.toUpperCase(),
                              bold: true,
                              color: AppColors.black,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText16(
                          widget.unit.status.toUpperCase(),
                          bold: true,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price Section
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText16(
                                l10n.price,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 4),
                              CustomText24(
                                '${l10n.egp} ${_formatPrice(widget.unit.price)}',
                                bold: true,
                                color: AppColors.mainColor,
                              ),
                            ],
                          ),
                          if (widget.unit.finishing != null && widget.unit.finishing!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CustomText16(
                                    l10n.finishing,
                                    color: AppColors.grey,
                                  ),
                                  CustomText16(
                                    widget.unit.finishing!,
                                    bold: true,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Unit Details
                  CustomText20(
                    l10n.unitDetails,
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 12),

                  // Unit ID
                  _buildInfoRow(l10n.unitId, widget.unit.id),

                  // Unit Number/Code
                  if (widget.unit.unitNumber != null && widget.unit.unitNumber!.isNotEmpty)
                    _buildInfoRow(l10n.unitNumber, widget.unit.unitNumber!),

                  // Compound ID
                  _buildInfoRow(l10n.compoundId, widget.unit.compoundId),

                  const Divider(height: 24),

                  // Building Name
                  if (widget.unit.buildingName != null && widget.unit.buildingName!.isNotEmpty)
                    _buildInfoRow(l10n.building, widget.unit.buildingName!),

                  // Floor
                  _buildInfoRow(l10n.floor, widget.unit.floor),

                  // Total Area
                  _buildInfoRow(l10n.totalArea, '${widget.unit.area} ${l10n.sqm}'),

                  // Garden Area
                  if (widget.unit.gardenArea != null && widget.unit.gardenArea!.isNotEmpty && widget.unit.gardenArea != '0')
                    _buildInfoRow(l10n.gardenArea, '${widget.unit.gardenArea} ${l10n.sqm}'),

                  // Roof Area
                  if (widget.unit.roofArea != null && widget.unit.roofArea!.isNotEmpty && widget.unit.roofArea != '0')
                    _buildInfoRow(l10n.roofArea, '${widget.unit.roofArea} ${l10n.sqm}'),

                  const Divider(height: 24),

                  // Bedrooms
                  if (widget.unit.bedrooms != '0')
                    _buildInfoRow(l10n.bedrooms, widget.unit.bedrooms),

                  // Bathrooms
                  if (widget.unit.bathrooms != '0')
                    _buildInfoRow(l10n.bathrooms, widget.unit.bathrooms),

                  // View
                  if (widget.unit.view != null && widget.unit.view!.isNotEmpty)
                    _buildInfoRow(l10n.view, widget.unit.view!),

                  // Delivery Date
                  if (widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty)
                    _buildInfoRow(l10n.deliveryDate, _formatDate(widget.unit.deliveryDate!)),

                  const Divider(height: 24),

                  // Created At
                  if (widget.unit.createdAt.isNotEmpty)
                    _buildInfoRow(l10n.listedOn, _formatDate(widget.unit.createdAt)),

                  // Updated At
                  if (widget.unit.updatedAt.isNotEmpty)
                    _buildInfoRow(l10n.lastUpdated, _formatDate(widget.unit.updatedAt)),

                  const SizedBox(height: 24),

                  // Sales Contact
                  if (widget.unit.salesNumber != null && widget.unit.salesNumber!.isNotEmpty) ...[
                    CustomText20(
                      l10n.contactSales,
                      bold: true,
                      color: AppColors.black,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: AppColors.mainColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText16(
                                    l10n.salesContact,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText18(
                                    widget.unit.salesNumber!,
                                    bold: true,
                                    color: AppColors.mainColor,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.phone,
                                color: AppColors.mainColor,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: CustomText16(l10n.calling(widget.unit.salesNumber!), color: AppColors.white),
                                    backgroundColor: AppColors.mainColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CustomText16(
              label,
              bold: true,
              color: AppColors.grey,
            ),
          ),
          Expanded(
            flex: 3,
            child: CustomText16(
              value,
              bold: true,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
