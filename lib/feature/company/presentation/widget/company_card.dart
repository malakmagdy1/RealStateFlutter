import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/core/animations/hover_scale_animation.dart';
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';
import 'package:real/feature/ai_chat/data/services/comparison_list_service.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/l10n/app_localizations.dart';

class CompanyCard extends StatefulWidget {
  final Company company;
  final VoidCallback? onTap;
  final bool showMargin;

  const CompanyCard({
    Key? key,
    required this.company,
    this.onTap,
    this.showMargin = true,
  }) : super(key: key);

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n?.localeName == 'ar';
    final displayName = widget.company.getLocalizedName(isArabic);

    return HoverScaleAnimation(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: widget.showMargin ? EdgeInsets.symmetric(horizontal: 12, vertical: 6) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company Logo Section - Fixed height
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                    ),
                    child: widget.company.fullLogoUrl != null && widget.company.fullLogoUrl!.isNotEmpty
                        ? RobustNetworkImage(
                            imageUrl: widget.company.fullLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Action Buttons Row
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Share Button
                        GestureDetector(
                          onTap: () => _showShareSheet(context),
                          child: Container(
                            height: 28,
                            width: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        // Compare Button with Active State
                        StreamBuilder<List<ComparisonItem>>(
                          stream: ComparisonListService().comparisonStream,
                          builder: (context, snapshot) {
                            final items = snapshot.data ?? [];
                            final isInComparison = items.any((item) =>
                              item.id == widget.company.id && item.type == 'company'
                            );

                            return GestureDetector(
                              onTap: () => _showCompareDialog(context),
                              child: Container(
                                height: 28,
                                width: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isInComparison
                                      ? AppColors.mainColor.withOpacity(0.9)
                                      : Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isInComparison ? Icons.compare : Icons.compare_arrows,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Company Info Section - Compact
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Company Name
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: AppColors.mainColor),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),

                    // Email - Compact
                    if (widget.company.email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 12, color: AppColors.greyText),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.company.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.greyText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    if (widget.company.email.isNotEmpty) SizedBox(height: 6),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(height: 6),

                    // Stats Row - Compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.apartment,
                          widget.company.numberOfCompounds,
                          'Compounds',
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          Icons.home_work,
                          widget.company.numberOfAvailableUnits,
                          'Units',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompareDialog(BuildContext context) {
    final comparisonItem = ComparisonItem.fromCompany(widget.company);
    final comparisonService = ComparisonListService();
    final l10n = AppLocalizations.of(context)!;

    // Add to comparison list
    final added = comparisonService.addItem(comparisonItem);

    if (added) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.addedToComparison,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: l10n.undo,
            textColor: Colors.white,
            onPressed: () {
              comparisonService.removeItem(comparisonItem);
            },
          ),
        ),
      );
    } else {
      // Show error (already in list or list is full)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  comparisonService.isFull
                      ? l10n.comparisonListFull
                      : l10n.alreadyInComparison,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showShareSheet(BuildContext context) async {
    // Fetch compounds for this company to pass to advanced share
    try {
      context.read<CompoundBloc>().add(
        FetchCompoundsByCompanyEvent(companyId: widget.company.id),
      );
    } catch (e) {
      // CompoundBloc might not be available in search context
    }

    List<Map<String, dynamic>>? compounds;

    try {
      final compoundState = context.read<CompoundBloc>().state;
      if (compoundState is CompoundSuccess) {
        compounds = compoundState.response.data.map((compound) {
          return {
            'id': compound.id,
            'project': compound.project,
            'location': compound.location,
            'totalUnits': compound.totalUnits,
          };
        }).toList();
      }
    } catch (e) {
      // Ignore if bloc not available
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AdvancedShareBottomSheet(
          type: 'company',
          id: widget.company.id.toString(),
          compounds: compounds,
        ),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.business,
        size: 60,
        color: AppColors.mainColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.mainColor),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.greyText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
