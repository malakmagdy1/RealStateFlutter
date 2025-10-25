import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/feature/share/presentation/widgets/share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_compound_detail_screen.dart';

class WebCompoundCard extends StatelessWidget {
  final Compound compound;
  final bool showFavoriteButton;

  WebCompoundCard({
    Key? key,
    required this.compound,
    this.showFavoriteButton = true,
  }) : super(key: key);
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

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        type: 'compound',
        id: compound.id.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebCompoundDetailScreen(compoundId: compound.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.mainColor.withOpacity(0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image with overlay buttons
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: compound.images != null && compound.images!.isNotEmpty
                        ? RobustNetworkImage(
                            imageUrl: compound.images!.first,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Favorite Button
                  if (showFavoriteButton)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                        builder: (context, state) {
                          final bloc = context.read<CompoundFavoriteBloc>();
                          final isFavorite = bloc.isFavorite(compound);

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => bloc.toggleFavorite(compound),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Share Button
                  Positioned(
                    top: 8,
                    left: showFavoriteButton ? 40 : 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showShareSheet(context),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.share,
                            color: AppColors.mainColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: compound.status == 'delivered'
                            ? Color(0xFF4CAF50)
                            : Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        compound.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Phone Button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showSalespeople(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mainColor.withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Container(
                padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (compound.companyLogo != null && compound.companyLogo!.isNotEmpty)
                          Container(
                            width: 24,
                            height: 24,
                            margin: EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: RobustNetworkImage(
                                imageUrl: compound.companyLogo!,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, url) => Icon(
                                  Icons.business,
                                  size: 12,
                                  color: AppColors.mainColor,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                compound.project,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 1),
                              Text(
                                compound.companyName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF999999),
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.mainColor,
                        ),
                        SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            compound.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (compound.totalUnits != '0' || compound.availableUnits != '0') ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          if (compound.totalUnits != '0') ...[
                            _buildInfoBadge(
                              Icons.apartment,
                              '${compound.totalUnits}',
                              AppColors.mainColor,
                            ),
                            SizedBox(width: 4),
                          ],
                          if (compound.availableUnits != '0')
                            _buildInfoBadge(
                              Icons.check_circle_outline,
                              '${compound.availableUnits}',
                              Color(0xFF4CAF50),
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

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Icon(
          Icons.apartment,
          size: 50,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
