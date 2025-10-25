import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/home/presentation/widget/location.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/feature/share/presentation/widgets/share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/utils/text_style.dart';
import '../CompoundScreen.dart';

class CompoundsName extends StatelessWidget {
  final Compound compound;
  final VoidCallback? onTap;

  CompoundsName({Key? key, required this.compound, this.onTap})
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

    // Debug company logo
    print('========================================');
    print('[COMPOUND CARD] Compound: ${compound.project}');
    print('[COMPOUND CARD] Company: ${compound.companyName}');
    print('[COMPOUND CARD] Company Logo URL: ${compound.companyLogo ?? "NULL"}');
    print('[COMPOUND CARD] Has Logo: ${compound.companyLogo != null && compound.companyLogo!.isNotEmpty}');
    print('========================================');

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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
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
                    height: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context) => Container(
                      width: double.infinity,
                      height: 120,
                      color: AppColors.grey,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorBuilder: (context, url) {
                      return Container(
                        width: double.infinity,
                        height: 120,
                        color: AppColors.grey,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: AppColors.grey,
                        ),
                      );
                    },
                  ),
                  // Status Badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: compound.status == 'delivered'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        compound.status.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 4,
                    left: 4,
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
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  // Share Button
                  Positioned(
                    top: 4,
                    left: 32,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ShareBottomSheet(
                            type: 'compound',
                            id: compound.id.toString(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.share,
                          color: AppColors.mainColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Phone Button
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showSalespeople(context),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.phone,
                          color: AppColors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _CompanyLogo(
                        companyId: compound.companyId,
                        companyName: compound.companyName,
                        companyLogo: compound.companyLogo,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: CustomText14(
                          compound.project,
                          bold: true,
                          color: AppColors.black,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Location
                  Location(compound: compound),
                  SizedBox(height: 4),

                  // Additional Info Chips - Show only top 2 most important
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      // Total Units
                      if (compound.totalUnits != '0')
                        _buildInfoChip(
                          icon: Icons.apartment,
                          label: '${compound.totalUnits} Units',
                        ),

                      // Available Units
                      if (compound.availableUnits != '0')
                        _buildInfoChip(
                          icon: Icons.check_circle_outline,
                          label: '${compound.availableUnits} Available',
                        ),

                      // Completion Progress
                      if (compound.completionProgress != null && compound.completionProgress != '0.00')
                        _buildInfoChip(
                          icon: Icons.trending_up,
                          label: '${compound.completionProgress}%',
                          color: Colors.green,
                        ),
                    ].take(2).toList(), // Only show first 2 chips
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.mainColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: chipColor),
          SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Company Logo Widget with fallback to API fetch
class _CompanyLogo extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String? companyLogo;

  _CompanyLogo({
    required this.companyId,
    required this.companyName,
    this.companyLogo,
  });

  @override
  State<_CompanyLogo> createState() => _CompanyLogoState();
}

class _CompanyLogoState extends State<_CompanyLogo> {
  String? _fetchedLogo;
  bool _isLoading = false;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    // If no logo provided, fetch it from API
    if ((widget.companyLogo == null || widget.companyLogo!.isEmpty) && !_hasFetched) {
      _fetchCompanyLogo();
    }
  }

  Future<void> _fetchCompanyLogo() async {
    if (_isLoading || _hasFetched) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final companyWebServices = CompanyWebServices();
      final companyData = await companyWebServices.getCompanyById(widget.companyId);

      print('[COMPANY LOGO] Fetched company data: $companyData');

      if (mounted) {
        setState(() {
          _fetchedLogo = companyData['logo']?.toString();
          _isLoading = false;
          _hasFetched = true;
          print('[COMPANY LOGO] Logo URL: $_fetchedLogo');
        });
      }
    } catch (e) {
      print('[COMPANY LOGO] Error fetching company: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFetched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.companyLogo ?? _fetchedLogo;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: hasLogo
          ? ClipOval(
              child: RobustNetworkImage(
                imageUrl: logoUrl,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                loadingBuilder: (context) => Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ),
                errorBuilder: (context, url) {
                  print('[COMPANY LOGO ERROR] Failed to load logo: $url');
                  return Container(
                    color: AppColors.mainColor.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        widget.companyName.isNotEmpty
                            ? widget.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(
              color: _isLoading ? Colors.grey.shade100 : AppColors.mainColor.withOpacity(0.1),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.mainColor,
                        ),
                      )
                    : Text(
                        widget.companyName.isNotEmpty
                            ? widget.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
              ),
            ),
    );
  }
}
