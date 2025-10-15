import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import '../../data/models/unit_model.dart';
import '../screen/unit_detail_screen.dart';

class UnitCard extends StatelessWidget {
  final Unit unit;

  const UnitCard({Key? key, required this.unit}) : super(key: key);

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
      // Parse the date string
      final date = DateTime.parse(dateStr);
      // Format as day/month/year
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Color _getStatusColor() {
    switch (unit.status.toLowerCase()) {
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
    final hasImages = unit.images.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailScreen(unit: unit),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (hasImages)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: RobustNetworkImage(
                      imageUrl: unit.images.first,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context) => Container(
                        height: 200,
                        color: AppColors.grey,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorBuilder: (context, url) => Container(
                        height: 200,
                        color: AppColors.grey,
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText16(
                        unit.status.toUpperCase(),
                        bold: true,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unit.companyLogo != null && unit.companyLogo!.isNotEmpty)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              unit.companyLogo!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.business, size: 28, color: Colors.grey),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unit.companyName != null && unit.companyName!.isNotEmpty)
                              CustomText16(unit.companyName!, color: Colors.grey),
                            const SizedBox(height: 4),
                            CustomText20(
                              unit.usageType ?? unit.unitType.toUpperCase(),
                              bold: true,
                              color: AppColors.black,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unit #${unit.unitNumber ?? unit.id}',
                              style: TextStyle(
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(thickness: 0.5, color: Colors.grey),

                  // Quick Info Chips
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _infoChip(Icons.square_foot, '${unit.area} m²'),
                      if (unit.bedrooms != '0')
                        _infoChip(Icons.bed, '${unit.bedrooms} Bedrooms'),
                      if (unit.bathrooms != '0')
                        _infoChip(Icons.bathtub_outlined, '${unit.bathrooms} Bathrooms'),
                      if (unit.view != null && unit.view!.isNotEmpty)
                        _infoChip(Icons.landscape, unit.view!),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.mainColor.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText20(
                          'EGP ${_formatPrice(unit.price)}',
                          bold: true,
                          color: AppColors.mainColor,
                        ),
                        if (unit.finishing != null && unit.finishing!.isNotEmpty)
                          Chip(
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            label: CustomText16(
                              unit.finishing!,
                              bold: true,
                              color: Colors.teal,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (unit.deliveryDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        CustomText16('Delivery: ', color: Colors.grey),
                        CustomText16(_formatDate(unit.deliveryDate!), bold: true, color: Colors.black),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mainColor),
          const SizedBox(width: 6),
          CustomText16(label, color: AppColors.black),
        ],
      ),
    );
  }
}
