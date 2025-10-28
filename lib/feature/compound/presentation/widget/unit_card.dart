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

class UnitCard extends StatefulWidget {
  final Unit unit;

  UnitCard({Key? key, required this.unit}) : super(key: key);

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty || price == '0') {
      return 'Contact for Price';
    }
    try {
      final numPrice = double.parse(price);
      if (numPrice == 0) {
        return 'Contact for Price';
      }
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return 'Contact for Price';
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
    final status = widget.unit.status?.toLowerCase() ?? '';
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
      final response = await compoundWebServices.getSalespeopleByCompound(widget.unit.compoundId);

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
    final hasImages = widget.unit.images.isNotEmpty;

    // Default values if data is missing - use reasonable defaults without hardcoded data
    final compoundName = widget.unit.compoundName?.isNotEmpty == true ? widget.unit.compoundName! : (widget.unit.companyName?.isNotEmpty == true ? widget.unit.companyName! : '');
    final companyLogo = widget.unit.companyLogo?.isNotEmpty == true ? widget.unit.companyLogo! : '';
    final unitType = (widget.unit.usageType ?? widget.unit.unitType ?? 'Unit').toUpperCase();
    final unitNumber = widget.unit.unitNumber ?? 'N/A';
    final area = widget.unit.area ?? '0';
    final price = widget.unit.price ?? '0';
    final finishing = widget.unit.finishing ?? 'N/A';
    final status = widget.unit.status ?? 'available';
    final deliveryDate = widget.unit.deliveryDate ?? '';

    // Hide sold units completely
    if (status.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: () {
          // Prevent navigation if unit is sold
          if (status.toLowerCase() == 'sold') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This unit is not available'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _scaleController.forward().then((_) => _scaleController.reverse());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UnitDetailScreen(unit: widget.unit)),
          );
        },
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    child: RobustNetworkImage(
                      imageUrl: widget.unit.images.first,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context) => Container(
                        height: 200,
                        color: AppColors.grey,
                        child: Center(child: CircularProgressIndicator()),
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _companyInfo(companyLogo, compoundName, unitType, unitNumber),
                  SizedBox(height: 14),
                  Divider(thickness: 0.5, color: AppColors.greyText),
                  SizedBox(height: 12),

                  // ---------- INFO CHIPS ----------
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (area != '0' && area.isNotEmpty)
                        _infoChip(Icons.square_foot, '$area ${l10n.sqm}'),
                      if ((widget.unit.bedrooms ?? '0') != '0' && (widget.unit.bedrooms ?? '').isNotEmpty)
                        _infoChip(Icons.bed, '${widget.unit.bedrooms} ${l10n.beds}'),
                      if ((widget.unit.bathrooms ?? '0') != '0' && (widget.unit.bathrooms ?? '').isNotEmpty)
                        _infoChip(Icons.bathtub_outlined, '${widget.unit.bathrooms} ${l10n.baths}'),
                      if ((widget.unit.view ?? '').isNotEmpty && widget.unit.view!.length < 20)
                        _infoChip(Icons.landscape, widget.unit.view!),
                    ],
                  ),

                  SizedBox(height: 16),
                  _priceAndFinishing(price, finishing),

                  if (deliveryDate.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.greyText),
                        SizedBox(width: 6),
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.delivery}: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.greyText,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatDate(deliveryDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      ),
    );
  }

  Widget _defaultImage() => Container(
    height: 200,
    color: Colors.grey[200],
    child: Center(
      child: Icon(Icons.image_not_supported, size: 60, color: AppColors.greyText),
    ),
  );

  Widget _statusTag(String status) => Positioned(
    top: 12,
    right: 12,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            Icon(Icons.business, size: 28, color: AppColors.greyText),
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
          child: Icon(Icons.business, size: 28, color: AppColors.greyText),
        ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText16(
              name,
              color: AppColors.greyText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            CustomText20(
              type,
              bold: true,
              color: AppColors.black,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  '${l10n.unit} $number',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    padding: EdgeInsets.all(14),
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
            Expanded(
              flex: 3,
              child: CustomText20(
                '${l10n.egp} ${_formatPrice(price)}',
                bold: true,
                color: AppColors.mainColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Chip(
                backgroundColor: Colors.teal.withOpacity(0.1),
                label: CustomText16(
                  finishing,
                  bold: true,
                  color: Colors.teal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _infoChip(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.mainColor),
        SizedBox(width: 6),
        Flexible(
          child: CustomText16(
            label,
            color: AppColors.black,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
            id: widget.unit.id,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 2),
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
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
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
