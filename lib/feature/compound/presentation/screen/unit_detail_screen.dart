import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import '../../data/models/unit_model.dart';

class UnitDetailScreen extends StatefulWidget {
  static const String routeName = '/unit-detail';
  final Unit unit;

  const UnitDetailScreen({Key? key, required this.unit}) : super(key: key);

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  int _currentImageIndex = 0;

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

  @override
  Widget build(BuildContext context) {
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
            flexibleSpace: FlexibleSpaceBar(
              title: CustomText18(
                'Unit ${widget.unit.unitNumber ?? widget.unit.id}',
                bold: true,
                color: hasImages ? AppColors.white : AppColors.black,
              ),
              background: hasImages
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        RobustNetworkImage(
                          imageUrl: displayImage!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context) => Container(
                            color: AppColors.grey,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          errorBuilder: (context, url) {
                            return Container(
                              color: AppColors.grey,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: AppColors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: AppColors.grey,
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery (if multiple images)
                  if (hasImages && widget.unit.images.length > 1) ...[
                    CustomText20(
                      "Gallery",
                      bold: true,
                      color: AppColors.black,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.unit.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: index == _currentImageIndex
                                      ? AppColors.mainColor
                                      : AppColors.grey,
                                  width: index == _currentImageIndex ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: RobustNetworkImage(
                                  imageUrl: widget.unit.images[index],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context) => Container(
                                    color: AppColors.grey,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorBuilder: (context, url) {
                                    return Container(
                                      color: AppColors.grey,
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 30,
                                        color: AppColors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Company Info Card
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
                                    'Developer',
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
                              'Unit Type',
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
                                'Price',
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 4),
                              CustomText24(
                                'EGP ${_formatPrice(widget.unit.price)}',
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
                                    'Finishing',
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
                    "Unit Details",
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 12),

                  // Unit ID
                  _buildInfoRow('Unit ID', widget.unit.id),

                  // Unit Number/Code
                  if (widget.unit.unitNumber != null && widget.unit.unitNumber!.isNotEmpty)
                    _buildInfoRow('Unit Number', widget.unit.unitNumber!),

                  // Compound ID
                  _buildInfoRow('Compound ID', widget.unit.compoundId),

                  const Divider(height: 24),

                  // Building Name
                  if (widget.unit.buildingName != null && widget.unit.buildingName!.isNotEmpty)
                    _buildInfoRow('Building', widget.unit.buildingName!),

                  // Floor
                  _buildInfoRow('Floor', widget.unit.floor),

                  // Total Area
                  _buildInfoRow('Total Area', '${widget.unit.area} m²'),

                  // Garden Area
                  if (widget.unit.gardenArea != null && widget.unit.gardenArea!.isNotEmpty && widget.unit.gardenArea != '0')
                    _buildInfoRow('Garden Area', '${widget.unit.gardenArea} m²'),

                  // Roof Area
                  if (widget.unit.roofArea != null && widget.unit.roofArea!.isNotEmpty && widget.unit.roofArea != '0')
                    _buildInfoRow('Roof Area', '${widget.unit.roofArea} m²'),

                  const Divider(height: 24),

                  // Bedrooms
                  if (widget.unit.bedrooms != '0')
                    _buildInfoRow('Bedrooms', widget.unit.bedrooms),

                  // Bathrooms
                  if (widget.unit.bathrooms != '0')
                    _buildInfoRow('Bathrooms', widget.unit.bathrooms),

                  // View
                  if (widget.unit.view != null && widget.unit.view!.isNotEmpty)
                    _buildInfoRow('View', widget.unit.view!),

                  // Delivery Date
                  if (widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty)
                    _buildInfoRow('Delivery Date', _formatDate(widget.unit.deliveryDate!)),

                  const Divider(height: 24),

                  // Created At
                  if (widget.unit.createdAt.isNotEmpty)
                    _buildInfoRow('Listed On', _formatDate(widget.unit.createdAt)),

                  // Updated At
                  if (widget.unit.updatedAt.isNotEmpty)
                    _buildInfoRow('Last Updated', _formatDate(widget.unit.updatedAt)),

                  const SizedBox(height: 24),

                  // Sales Contact
                  if (widget.unit.salesNumber != null && widget.unit.salesNumber!.isNotEmpty) ...[
                    CustomText20(
                      "Contact Sales",
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
                                    'Sales Contact',
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
                                    content: CustomText16('Calling ${widget.unit.salesNumber}...', color: AppColors.white),
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
