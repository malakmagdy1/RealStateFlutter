import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import '../../data/models/unit_model.dart';
import '../screen/unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';

class UnitCard extends StatelessWidget {
  final Unit unit;

  const UnitCard({Key? key, required this.unit}) : super(key: key);

  String _formatPrice(String? price) {
    try {
      final numPrice = double.parse(price ?? '0');
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return price ?? '0';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      if (dateStr.contains('T')) return dateStr.split('T')[0];
      return dateStr;
    }
  }

  Color _getStatusColor() {
    final status = unit.status?.toLowerCase() ?? '';
    switch (status) {
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

  Future<void> _showSalespeople(BuildContext context) async {
    final compoundWebServices = CompoundWebServices();
    final l10n = AppLocalizations.of(context)!;

    try {
      // Use compound ID as the search parameter since we don't have compound name in Unit model
      final response = await compoundWebServices.getSalespeopleByCompound(unit.compoundId);

      if (response['success'] == true && response['salespeople'] != null) {
        final salespeople = (response['salespeople'] as List)
            .map((sp) => SalesPerson.fromJson(sp as Map<String, dynamic>))
            .toList();

        if (salespeople.isNotEmpty && context.mounted) {
          SalesPersonSelector.show(
            context,
            salesPersons: salespeople,
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noSalesPersonAvailable),
              backgroundColor: AppColors.mainColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = unit.images.isNotEmpty;

    // Default values if data is missing
    final companyName = unit.companyName?.isNotEmpty == true ? unit.companyName! : 'Badya';
    final companyLogo = unit.companyLogo?.isNotEmpty == true ? unit.companyLogo! : '';
    final unitType = (unit.usageType ?? unit.unitType ?? 'Villa Type W2').toUpperCase();
    final unitNumber = unit.unitNumber ?? '#D2V1A-VLV/2-177';
    final area = unit.area ?? '0';
    final price = unit.price ?? '52400000';
    final finishing = unit.finishing ?? 'N/A';
    final status = unit.status ?? 'available';
    final deliveryDate = unit.deliveryDate ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UnitDetailScreen(unit: unit)),
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
            // ---------- IMAGE ----------
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
                      errorBuilder: (context, url) => _defaultImage(),
                    ),
                  ),
                  _statusTag(status),
                  _shareButton(context),
                  _phoneButton(context),
                ],
              )
            else
              Stack(
                children: [
                  _defaultImage(),
                  _shareButton(context),
                  _phoneButton(context),
                ],
              ),

            // ---------- DETAILS ----------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _companyInfo(companyLogo, companyName, unitType, unitNumber),
                  const SizedBox(height: 14),
                  const Divider(thickness: 0.5, color: Colors.grey),
                  const SizedBox(height: 12),

                  // ---------- INFO CHIPS ----------
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _infoChip(Icons.square_foot, '$area ${l10n.sqm}'),
                      if ((unit.bedrooms ?? '0') != '0')
                        _infoChip(Icons.bed, '${unit.bedrooms ?? 'N/A'} ${l10n.bedrooms}'),
                      if ((unit.bathrooms ?? '0') != '0')
                        _infoChip(Icons.bathtub_outlined, '${unit.bathrooms ?? 'N/A'} ${l10n.bathrooms}'),
                      if ((unit.view ?? '').isNotEmpty)
                        _infoChip(Icons.landscape, unit.view!),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _priceAndFinishing(price, finishing),

                  if (deliveryDate.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        CustomText16('${l10n.delivery}: ', color: Colors.grey),
                        CustomText16(
                          _formatDate(deliveryDate),
                          bold: true,
                          color: Colors.black,
                        ),
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

  Widget _defaultImage() => Container(
    height: 200,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
    ),
  );

  Widget _statusTag(String status) => Positioned(
    top: 12,
    right: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText16(
        status.toUpperCase(),
        bold: true,
        color: Colors.white,
      ),
    ),
  );

  Widget _companyInfo(String logo, String name, String type, String number) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (logo.isNotEmpty)
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: RobustNetworkImage(
            imageUrl: logo,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, url) =>
            const Icon(Icons.business, size: 28, color: Colors.grey),
          ),
        )
      else
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.business, size: 28, color: Colors.grey),
        ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText16(name, color: Colors.grey),
            const SizedBox(height: 4),
            CustomText20(type, bold: true, color: AppColors.black),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  '${l10n.unit} $number',
                  style: TextStyle(
                color: AppColors.mainColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _priceAndFinishing(String price, String finishing) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: AppColors.mainColor.withOpacity(0.05),
      border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
    ),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText20(
              '${l10n.egp} ${_formatPrice(price)}',
              bold: true,
              color: AppColors.mainColor,
            ),
            Chip(
              backgroundColor: Colors.teal.withOpacity(0.1),
              label: CustomText16(
                finishing,
                bold: true,
                color: Colors.teal,
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _infoChip(IconData icon, String label) => Container(
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

  Widget _shareButton(BuildContext context) => Positioned(
    top: 12,
    left: 12,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.share,
          size: 20,
          color: AppColors.mainColor,
        ),
      ),
    ),
  );

  Widget _phoneButton(BuildContext context) => Positioned(
    bottom: 12,
    right: 12,
    child: GestureDetector(
      onTap: () => _showSalespeople(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.phone,
          color: AppColors.white,
          size: 20,
        ),
      ),
    ),
  );
}
