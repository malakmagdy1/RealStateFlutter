import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/l10n/app_localizations.dart';

class CompanyDetailScreen extends StatefulWidget {
  static String routeName = '/company-detail';
  final Company company;

  CompanyDetailScreen({
    Key? key,
    required this.company,
  }) : super(key: key);

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {

  @override
  void initState() {
    super.initState();
    print('[CompanyDetailScreen] Opening company: ${widget.company.name} (ID: ${widget.company.id})');
    // Fetch compounds for this company when screen loads
    context.read<CompoundBloc>().add(
          FetchCompoundsByCompanyEvent(companyId: widget.company.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate years of experience
    final yearsOfExp = _calculateYearsOfExperience(widget.company.createdAt);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Back Button
            Container(
              padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.bookmark_border, color: AppColors.black),
                      onPressed: () {
                        // TODO: Implement bookmark functionality
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Company Logo
            Center(
              child: Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.greyText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.company.logo != null && widget.company.logo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RobustNetworkImage(
                          imageUrl: widget.company.logo!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, url) => Icon(
                            Icons.business,
                            size: 60,
                            color: AppColors.greyText,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business,
                        size: 60,
                        color: AppColors.greyText,
                      ),
              ),
            ),

            // Company Name and Location
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CustomText24(
                    widget.company.name,
                    bold: true,
                    color: AppColors.black,
                    align: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  CustomText16(
                    'Cairo, Egypt', // Default location
                    color: AppColors.greyText,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // About Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CustomText16(
                '${widget.company.name} is a leading developer of premium lifestyle destinations in Egypt. Since its inception in ${_getYearFromDate(widget.company.createdAt)}, it has been a key contributor to the country\'s real estate market, renowned for its large-scale, integrated communities.',
                color: AppColors.greyText,
                align: TextAlign.center,
              ),
            ),
            SizedBox(height: 30),

            // Stats Cards
            BlocBuilder<CompoundBloc, CompoundState>(
              builder: (context, state) {
                int compoundsCount = int.tryParse(widget.company.numberOfCompounds) ?? 0;
                int unitsDelivered = int.tryParse(widget.company.numberOfAvailableUnits) ?? 0;

                // If compounds are loaded from API, use those counts
                if (state is CompoundSuccess) {
                  compoundsCount = state.response.data.length;

                  // Calculate total units
                  unitsDelivered = 0;
                  for (var compound in state.response.data) {
                    unitsDelivered += int.tryParse(compound.totalUnits) ?? 0;
                  }
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          value: '$yearsOfExp+',
                          label: 'Years of Exp.',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          value: compoundsCount > 0 ? '$compoundsCount' : '5',
                          label: l10n.compounds,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          value: unitsDelivered > 0 ? '${_formatNumber(unitsDelivered)}+' : '1,200+',
                          label: 'Units Delivered',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 40),

            // Compounds Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CustomText20(
                l10n.compounds,
                bold: true,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 16),

            // Compounds Grid
            BlocBuilder<CompoundBloc, CompoundState>(
              builder: (context, state) {
                if (state is CompoundLoading) {
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.black),
                    ),
                  );
                } else if (state is CompoundSuccess) {
                  if (state.response.data.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.greyText.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apartment,
                                size: 48,
                                color: AppColors.greyText,
                              ),
                              SizedBox(height: 8),
                              CustomText16(
                                l10n.noCompoundsAvailable,
                                color: AppColors.greyText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final compounds = state.response.data;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: compounds.length,
                    itemBuilder: (context, index) {
                      final compound = compounds[index];
                      return CompoundsName(compound: compound);
                    },
                  );
                } else if (state is CompoundError) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.greyText.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.greyText,
                            ),
                            SizedBox(height: 8),
                            CustomText16(
                              l10n.error,
                              color: AppColors.greyText,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CompoundBloc>().add(
                                      FetchCompoundsByCompanyEvent(
                                        companyId: widget.company.id,
                                      ),
                                    );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                              ),
                              child: CustomText16(l10n.retry, color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(height: 220);
              },
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  int _calculateYearsOfExperience(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final years = now.year - date.year;
      return years > 0 ? years : 1;
    } catch (e) {
      return 15; // Default value
    }
  }

  String _getYearFromDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return date.year.toString();
    } catch (e) {
      return '2007';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  // Simple stat item widget
  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        CustomText24(
          value,
          bold: true,
          color: AppColors.black,
          align: TextAlign.center,
        ),
        SizedBox(height: 4),
        CustomText16(
          label,
          color: AppColors.greyText,
          align: TextAlign.center,
        ),
      ],
    );
  }
}
