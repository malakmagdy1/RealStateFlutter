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
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
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
    // Fetch compounds for this company when screen loads
    context.read<CompoundBloc>().add(
          FetchCompoundsByCompanyEvent(companyId: widget.company.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

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
                      icon: Icon(Icons.share, color: AppColors.black),
                      onPressed: () async {
                        // Fetch compounds for this company to pass to advanced share
                        final compoundState = context.read<CompoundBloc>().state;
                        List<Map<String, dynamic>>? compounds;

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
                      },
                    ),
                  ),
                  SizedBox(width: 12),
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
                    widget.company.getLocalizedName(isArabic),
                    bold: true,
                    color: AppColors.black,
                    align: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  CustomText16(
                    l10n.cairoEgypt,
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
                l10n.companyAboutDescription(
                  widget.company.getLocalizedName(isArabic),
                  _getYearFromDate(widget.company.createdAt),
                ),
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
                          value: compoundsCount > 0 ? '$compoundsCount' : '-',
                          label: l10n.compounds,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          value: unitsDelivered > 0 ? '${_formatNumber(unitsDelivered)}' : '-',
                          label: l10n.unitsDelivered,
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
              padding: EdgeInsets.all(15),
              child: CustomText20(
                l10n.compounds,
                bold: true,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 16),

            // Compounds Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: BlocBuilder<CompoundBloc, CompoundState>(
                builder: (context, state) {
                  if (state is CompoundLoading) {
                    return SizedBox(
                      height: 120,
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
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
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
