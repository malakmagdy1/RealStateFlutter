import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/button/showAll.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../../home/presentation/widget/compunds_name.dart';

class CompanyDetailScreen extends StatefulWidget {
  static const String routeName = '/company-detail';
  final Company company;

  const CompanyDetailScreen({
    Key? key,
    required this.company,
  }) : super(key: key);

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool _showAllCompounds = false;

  @override
  void initState() {
    super.initState();
    print('[CompanyDetailScreen] Opening company: ${widget.company.name} (ID: ${widget.company.id})');
    // Fetch compounds for this company when screen loads
    context.read<CompoundBloc>().add(
          FetchCompoundsByCompanyEvent(companyId: widget.company.id),
        );
  }

  void _showSalespeople() {
    final l10n = AppLocalizations.of(context)!;

    // Convert company sales to SalesPerson list
    final salespeople = widget.company.sales.map((sale) {
      return SalesPerson(
        id: sale.id?.toString() ?? '0',
        name: sale.name,
        email: sale.email,
        phone: sale.phone,
        image: sale.image,
      );
    }).toList();

    if (salespeople.isNotEmpty) {
      SalesPersonSelector.show(
        context,
        salesPersons: salespeople,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noSalesPersonAvailable),
          backgroundColor: AppColors.mainColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Replace with actual rating from API when available
    final double rating = 4.5;
    final int reviewCount = 128;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo/Banner with back button
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.mainColor.withOpacity(0.15),
                        AppColors.mainColor.withOpacity(0.08),
                        AppColors.mainColor.withOpacity(0.03),
                      ],
                    ),
                  ),
                  child: widget.company.logo != null && widget.company.logo!.isNotEmpty
                      ? RobustNetworkImage(
                          imageUrl: widget.company.logo!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, url) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 100,
                                  color: AppColors.mainColor,
                                ),
                                const SizedBox(height: 8),
                                CustomText16(
                                  l10n.noResults,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.business,
                            size: 100,
                            color: AppColors.mainColor,
                          ),
                        ),
                ),
                // Back button
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // Phone icon button
                if (widget.company.salesCount > 0)
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.phone, color: AppColors.white),
                        onPressed: _showSalespeople,
                        tooltip: l10n.contactSales,
                      ),
                    ),
                  ),
              ],
            ),

            // Company Info Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Name
                  CustomText20(widget.company.name, bold: true, color: AppColors.black),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      _buildStarRating(rating),
                      const SizedBox(width: 8),
                      CustomText16(
                        '$rating',
                        bold: true,
                        color: AppColors.black,
                      ),
                      CustomText16(
                        ' ($reviewCount ${l10n.reviews})',
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.apartment,
                          title: l10n.compounds,
                          value: widget.company.numberOfCompounds,
                          color: AppColors.mainColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.home_work,
                          title: l10n.availableUnits,
                          value: widget.company.numberOfAvailableUnits,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About Section
                  CustomText18(l10n.aboutCompany, bold: true, color: AppColors.black),
                  const SizedBox(height: 8),
                  CustomText16(
                    'One of the leading real estate companies in Egypt, specializing in residential and commercial developments with a strong commitment to quality and customer satisfaction.',
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 20),

                  // Contact Info
                  if (widget.company.email.isNotEmpty) ...[
                    _buildContactInfo(
                      icon: Icons.email_outlined,
                      title: l10n.email,
                      value: widget.company.email,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildContactInfo(
                    icon: Icons.calendar_today_outlined,
                    title: l10n.memberSince,
                    value: _formatDate(widget.company.createdAt),
                  ),
                  const SizedBox(height: 30),

                  // Sales Team Section
                  if (widget.company.salesCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText18(l10n.salesTeam, bold: true, color: AppColors.black),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomText16(
                            '${widget.company.salesCount} ${widget.company.salesCount == 1 ? l10n.member : l10n.members}',
                            bold: true,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.company.sales.map((sale) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSalesCard(sale, l10n),
                    )).toList(),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),

            // All Compounds Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText18(l10n.allCompounds, bold: true, color: AppColors.black),
                      BlocBuilder<CompoundBloc, CompoundState>(
                        builder: (context, state) {
                          if (state is CompoundSuccess && state.response.data.isNotEmpty) {
                            return TextButton(
                              onPressed: () {
                                // TODO: Navigate to full compounds list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.viewAll} ${state.response.data.length} ${l10n.compounds} ${widget.company.name}'),
                                    backgroundColor: AppColors.mainColor,
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CustomText16(
                                    l10n.seeAll,
                                    bold: true,
                                    color: AppColors.mainColor,
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.mainColor,
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Compounds List
            BlocBuilder<CompoundBloc, CompoundState>(
              builder: (context, state) {
                if (state is CompoundLoading) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (state is CompoundSuccess) {
                  if (state.response.data.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apartment,
                                size: 48,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 8),
                              CustomText16(
                                l10n.noCompoundsAvailable,
                                color: AppColors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final compounds = state.response.data;
                  final displayCount = _showAllCompounds ? compounds.length : (compounds.length > 5 ? 5 : compounds.length);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ...compounds.take(displayCount).map((compound) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CompoundsName(compound: compound),
                        )).toList(),
                        if (compounds.length > 5) ...[
                          const SizedBox(height: 16),
                          ShowAllButton(
                            label: _showAllCompounds ? l10n.showLess : '${l10n.showAll} ${l10n.compounds}',
                            pressed: () {
                              setState(() {
                                _showAllCompounds = !_showAllCompounds;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                } else if (state is CompoundError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 8),
                            CustomText16(
                              '${l10n.error} loading ${l10n.compounds.toLowerCase()}',
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CompoundBloc>().add(
                                      FetchCompoundsByCompanyEvent(
                                        companyId: widget.company.id,
                                      ),
                                    );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                              ),
                              child: CustomText16(l10n.retry, color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox(height: 220);
              },
            ),
            const SizedBox(height: 30),

            // Reviews Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText18(l10n.customerReviews, bold: true, color: AppColors.black),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to reviews page
                        },
                        child: CustomText16(
                          l10n.viewAll,
                          bold: true,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReviewCard(
                    name: 'Ahmed Hassan',
                    rating: 5.0,
                    date: '2 weeks ago',
                    review: 'Excellent company with professional service. Very satisfied with my purchase.',
                  ),
                  const SizedBox(height: 12),
                  _buildReviewCard(
                    name: 'Sara Mohamed',
                    rating: 4.0,
                    date: '1 month ago',
                    review: 'Good experience overall. The staff was helpful and responsive.',
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Star Rating Widget
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          );
        } else if (index < rating) {
          // Half star
          return Icon(
            Icons.star_half,
            color: Colors.amber,
            size: 20,
          );
        } else {
          // Empty star
          return Icon(
            Icons.star_border,
            color: Colors.amber,
            size: 20,
          );
        }
      }),
    );
  }

  // Stat Card Widget
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          CustomText24(
            value,
            bold: true,
            color: color,
          ),
          const SizedBox(height: 6),
          CustomText16(
            title,
            align: TextAlign.center,
            color: color.withOpacity(0.8),
            bold: true,
          ),
        ],
      ),
    );
  }

  // Contact Info Widget
  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.mainColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText16(
                title,
                color: AppColors.grey,
              ),
              const SizedBox(height: 2),
              CustomText16(
                value,
                bold: true,
                color: AppColors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Review Card Widget
  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String date,
    required String review,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mainColor.withOpacity(0.15),
                          AppColors.mainColor.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: CustomText18(
                        name[0],
                        bold: true,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText16(
                        name,
                        bold: true,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 2),
                      CustomText16(
                        date,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildStarRating(rating),
                    const SizedBox(width: 4),
                    CustomText16(
                      rating.toStringAsFixed(1),
                      bold: true,
                      color: Colors.amber.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomText16(
              review,
              color: AppColors.black.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Sales Card Widget
  Widget _buildSalesCard(sale, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.mainColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.mainColor.withOpacity(0.15),
                  AppColors.mainColor.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.mainColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: sale.image != null && sale.image!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      sale.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: CustomText20(
                            sale.name.isNotEmpty ? sale.name[0].toUpperCase() : 'S',
                            bold: true,
                            color: AppColors.mainColor,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: CustomText20(
                      sale.name.isNotEmpty ? sale.name[0].toUpperCase() : 'S',
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Sales Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText16(
                        sale.name,
                        bold: true,
                        color: AppColors.black,
                      ),
                    ),
                    if (sale.isVerified == '1')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            CustomText16(
                              l10n.verified,
                              bold: true,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText16(
                        sale.email,
                        color: AppColors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 6),
                    CustomText16(
                      sale.phone,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contact Actions
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: AppColors.mainColor,
                    size: 22,
                  ),
                  onPressed: () {
                    // TODO: Implement call functionality
                    final l10nLocal = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: CustomText16(l10nLocal.calling2(sale.name), color: AppColors.white),
                        backgroundColor: AppColors.mainColor,
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.email,
                    color: AppColors.mainColor,
                    size: 22,
                  ),
                  onPressed: () {
                    // TODO: Implement email functionality
                    final l10nLocal = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: CustomText16('${l10nLocal.email} ${sale.name}...', color: AppColors.white),
                        backgroundColor: AppColors.mainColor,
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
