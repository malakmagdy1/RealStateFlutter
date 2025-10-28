import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import '../../../core/utils/text_style.dart';
import '../../company/presentation/web_company_detail_screen.dart';
import '../../../feature/compound/presentation/bloc/compound_bloc.dart';
import '../../../feature/compound/presentation/bloc/compound_event.dart';
import '../../../feature/compound/presentation/bloc/compound_state.dart';
import '../../../feature/home/presentation/widget/company_name_scrol.dart';
import '../../widgets/web_compound_card.dart';
import '../../../feature/home/presentation/widget/sale_slider.dart';
import '../../../feature/auth/presentation/bloc/user_bloc.dart';
import '../../../feature/auth/presentation/bloc/user_state.dart';
import '../../../feature/sale/presentation/bloc/sale_bloc.dart';
import '../../../feature/sale/presentation/bloc/sale_state.dart';
import '../../../l10n/app_localizations.dart';

class WebHomeScreen extends StatefulWidget {
  static String routeName = '/web-home';

  const WebHomeScreen({Key? key}) : super(key: key);

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  bool _showAllAvailableCompounds = false;
  bool _showAllRecommendedCompounds = false;

  @override
  void initState() {
    super.initState();
    // Fetch companies and compounds when screen loads
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return CustomText20("${l10n.welcome} ${state.user.name}");
                    }
                    return CustomText20(l10n.welcome);
                  },
                ),
                SizedBox(height: 24),

                // Regular home content
                  // Companies section
                CustomText20(l10n.companiesName),
                SizedBox(height: 8),

                BlocBuilder<CompanyBloc, CompanyState>(
                  builder: (context, state) {
                    if (state is CompanyLoading) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompanySuccess) {
                      if (state.response.companies.isEmpty) {
                        return SizedBox(
                          height: 100,
                          child: Center(
                            child: CustomText16(l10n.noCompanies, color: AppColors.grey),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.response.companies.length,
                          itemBuilder: (context, index) {
                            final company = state.response.companies[index];
                            return CompanyName(
                              company: company,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebCompanyDetailScreen(company: company),
                                  ),
                                ).then((_) {
                                  context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
                                });
                              },
                            );
                          },
                        ),
                      );
                    } else if (state is CompanyError) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompanyBloc>().add(
                                    FetchCompaniesEvent(),
                                  );
                                },
                                child: CustomText16(l10n.retry, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(height: 100);
                  },
                ),

                // Sales Slider
                BlocBuilder<SaleBloc, SaleState>(
                  builder: (context, state) {
                    if (state is SaleLoading) {
                      return SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (state is SaleError) {
                      return SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  l10n.saleDataUnavailable,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (state is SaleSuccess) {
                      final activeSales = state.response.sales
                          .where((sale) => sale.isCurrentlyActive)
                          .toList();

                      if (activeSales.isNotEmpty) {
                        return SaleSlider(sales: activeSales);
                      }
                    }

                    return SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer, size: 40, color: AppColors.greyText),
                              SizedBox(height: 8),
                              Text(
                                l10n.noActiveSales,
                                style: TextStyle(color: AppColors.greyText),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                // Available Compounds section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    final compounds = (state is CompoundSuccess) ? state.response.data : [];
                    final hasMultipleCompounds = compounds.length > 6;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText20(l10n.availableCompounds),
                            if (hasMultipleCompounds && state is CompoundSuccess)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllAvailableCompounds = !_showAllAvailableCompounds;
                                  });
                                },
                                icon: Icon(
                                  _showAllAvailableCompounds ? Icons.expand_less : Icons.expand_more,
                                  size: 18,
                                  color: AppColors.mainColor,
                                ),
                                label: Text(
                                  _showAllAvailableCompounds ? l10n.showLess : l10n.showAll,
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompoundSuccess) {
                      if (state.response.data.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CustomText16(l10n.noCompounds, color: AppColors.grey),
                          ),
                        );
                      }

                      final compounds = [...state.response.data];
                      final displayCount = _showAllAvailableCompounds
                          ? compounds.length
                          : (compounds.length > 6 ? 6 : compounds.length);

                      // Horizontal scroll view
                      return SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = compounds[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 16),
                              child: WebCompoundCard(compound: compound),
                            );
                          },
                        ),
                      );
                    } else if (state is CompoundError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompoundBloc>().add(
                                    FetchCompoundsEvent(),
                                  );
                                },
                                child: CustomText16(l10n.retry, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(height: 200);
                  },
                ),

                SizedBox(height: 24),

                // Recommended Compounds Section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundSuccess) {
                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final hasMultipleRecommended = recommendedCompounds.length > 6;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText20(l10n.recommendedCompounds),
                              if (hasMultipleRecommended)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showAllRecommendedCompounds = !_showAllRecommendedCompounds;
                                    });
                                  },
                                  icon: Icon(
                                    _showAllRecommendedCompounds ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: AppColors.mainColor,
                                  ),
                                  label: Text(
                                    _showAllRecommendedCompounds ? l10n.showLess : l10n.showAll,
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText20(l10n.recommendedCompounds),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompoundSuccess) {
                      if (state.response.data.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CustomText16(l10n.noCompoundsAvailable, color: AppColors.grey),
                          ),
                        );
                      }

                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final displayCount = _showAllRecommendedCompounds
                          ? recommendedCompounds.length
                          : (recommendedCompounds.length > 9 ? 9 : recommendedCompounds.length);

                      // Horizontal scroll view
                      return SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = recommendedCompounds[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 16),
                              child: WebCompoundCard(compound: compound),
                            );
                          },
                        ),
                      );
                    } else if (state is CompoundError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompoundBloc>().add(
                                    FetchCompoundsEvent(),
                                  );
                                },
                                child: CustomText16(l10n.retry, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(height: 200);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
