import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/home/presentation/widget/location.dart';
import 'package:real/core/utils/url_helpers.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/utils/text_style.dart';
import '../CompoundScreen.dart';

class CompoundsName extends StatelessWidget {
  final Compound compound;
  final VoidCallback? onTap;

  const CompoundsName({Key? key, required this.compound, this.onTap})
    : super(key: key);

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

  Future<void> _showSalespeople(BuildContext context) async {
    final compoundWebServices = CompoundWebServices();
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await compoundWebServices.getSalespeopleByCompound(compound.project);

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
    // Get the first image from the compound's images array
    final bool hasImages = compound.images.isNotEmpty;
    final String? displayImage = hasImages ? compound.images.first : null;

    return InkWell(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompoundScreen(compound: compound),
              ),
            );
          },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (hasImages)
              Stack(
                children: [
                  RobustNetworkImage(
                    imageUrl: displayImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context) => Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColors.grey,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorBuilder: (context, url) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: AppColors.grey,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: AppColors.grey,
                        ),
                      );
                    },
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: compound.status == 'delivered'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText16(
                        compound.status.toUpperCase(),
                        color: AppColors.white,
                        bold: true,
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 12,
                    left: 12,
                    child:
                        BlocBuilder<
                          CompoundFavoriteBloc,
                          CompoundFavoriteState
                        >(
                          builder: (context, state) {
                            final bloc = context.read<CompoundFavoriteBloc>();
                            final isFavorite = bloc.isFavorite(compound);

                            return GestureDetector(
                              onTap: () => bloc.toggleFavorite(compound),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  // Phone Button
                  Positioned(
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
                  ),
                ],
              ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.mainColor.withOpacity(0.1),
                        backgroundImage:
                            compound.companyLogo != null &&
                                compound.companyLogo!.isNotEmpty
                            ? NetworkImage(UrlHelpers.fixImageUrl(compound.companyLogo!))
                            : null,
                        child:
                            compound.companyLogo == null ||
                                compound.companyLogo!.isEmpty
                            ? CustomText16(
                                compound.companyName.isNotEmpty
                                    ? compound.companyName[0].toUpperCase()
                                    : '?',
                                bold: true,
                                color: AppColors.mainColor,
                              )
                            : null,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: CustomText18(
                          compound.project,
                          bold: true,
                          color: AppColors.black,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location
                  Location(compound: compound),
                  const SizedBox(height: 12),

                  // Info Row
                  Row(
                    children: [
                      if (compound.completionProgress != null &&
                          compound.completionProgress != '0.00')
                        Expanded(
                          child: _buildInfoChipWithLabel(
                            icon: Icons.trending_up,
                            label: 'Progress',
                            value: '${compound.completionProgress}%',
                            color: Colors.green,
                          ),
                        ),
                      if (compound.plannedDeliveryDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.grey,
                                  ),
                                  SizedBox(width: 6),

                                  CustomText16(
                                    'Delivery Date:',
                                    color: AppColors.grey,
                                    bold: true,
                                  ),
                                ],
                              ),

                              CustomText16(
                                _formatDate(compound.plannedDeliveryDate!),
                                color: AppColors.black,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Delivery Date
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChipWithLabel({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              CustomText16(label, bold: true, color: color.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 4),
          CustomText16(
            value,
            bold: true,
            color: color,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
