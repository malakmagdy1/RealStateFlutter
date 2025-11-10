import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import 'package:real/feature/company/presentation/screen/company_detail_screen.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/animated_list_item.dart';

class CompaniesScreen extends StatefulWidget {
  static String routeName = '/companies';

  CompaniesScreen({Key? key}) : super(key: key);

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'compounds', 'units'

  @override
  void initState() {
    super.initState();
    // Fetch companies when screen loads
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Company> _filterAndSortCompanies(List<Company> companies) {
    // Filter by search query
    List<Company> filtered = companies;
    if (_searchQuery.isNotEmpty) {
      filtered = companies.where((company) {
        return company.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            company.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'compounds':
          final aValue = int.tryParse(a.numberOfCompounds) ?? 0;
          final bValue = int.tryParse(b.numberOfCompounds) ?? 0;
          return bValue.compareTo(aValue); // Descending
        case 'units':
          final aValue = int.tryParse(a.numberOfAvailableUnits) ?? 0;
          final bValue = int.tryParse(b.numberOfAvailableUnits) ?? 0;
          return bValue.compareTo(aValue); // Descending
        case 'name':
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Ascending
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header with Back Button and Title
          Container(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
            color: AppColors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<CompanyBloc, CompanyState>(
                        builder: (context, state) {
                          if (state is CompanySuccess) {
                            return Row(
                              children: [
                                CustomText20(
                                  l10n.companiesName,
                                  bold: true,
                                  color: AppColors.black,
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.8)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${state.response.total}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return CustomText20(
                            l10n.companiesName,
                            bold: true,
                            color: AppColors.black,
                          );
                        },
                      ),
                    ),
                    // Sort Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.sort, color: AppColors.mainColor),
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort_by_alpha,
                                color: _sortBy == 'name' ? AppColors.mainColor : AppColors.grey,
                              ),
                              SizedBox(width: 8),
                              Text('Sort by Name'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'compounds',
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: _sortBy == 'compounds' ? AppColors.mainColor : AppColors.grey,
                              ),
                              SizedBox(width: 8),
                              Text('Sort by Compounds'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'units',
                          child: Row(
                            children: [
                              Icon(
                                Icons.apartment,
                                color: _sortBy == 'units' ? AppColors.mainColor : AppColors.grey,
                              ),
                              SizedBox(width: 8),
                              Text('Sort by Units'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      hintStyle: TextStyle(color: AppColors.grey),
                      prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Companies List
          Expanded(
            child: BlocBuilder<CompanyBloc, CompanyState>(
              builder: (context, state) {
                if (state is CompanyLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.mainColor),
                  );
                } else if (state is CompanySuccess) {
                  final companies = _filterAndSortCompanies(state.response.companies);

                  if (companies.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          SizedBox(height: 16),
                          CustomText16(
                            _searchQuery.isNotEmpty
                                ? 'No companies found'
                                : 'No companies available',
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return AnimatedListItem(
                        index: index,
                        delay: Duration(milliseconds: 50),
                        child: _buildCompanyCard(company, context),
                      );
                    },
                  );
                } else if (state is CompanyError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        CustomText16(
                          'Error: ${state.message}',
                          color: Colors.red,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CompanyBloc>().add(FetchCompaniesEvent());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: AppColors.white,
                          ),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Company company, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              CompanyDetailScreen.routeName,
              arguments: company,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Company Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: company.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: RobustNetworkImage(
                            imageUrl: company.logo!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url) => _buildPlaceholderLogo(company),
                          ),
                        )
                      : _buildPlaceholderLogo(company),
                ),
                SizedBox(width: 16),

                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText16(
                        company.name,
                        bold: true,
                        color: AppColors.black,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      if (company.email.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: AppColors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: CustomText12(
                                company.email,
                                color: AppColors.grey,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.business,
                            label: company.numberOfCompounds,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          _buildStatChip(
                            icon: Icons.apartment,
                            label: company.numberOfAvailableUnits,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo(Company company) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.mainColor.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.mainColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          CustomText12(
            label,
            color: color,
            bold: true,
          ),
        ],
      ),
    );
  }
}
