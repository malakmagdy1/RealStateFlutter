import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../../feature_web/widgets/web_compound_card.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/ai_chat/presentation/widget/floating_comparison_cart.dart';

class WebCompanyDetailScreen extends StatefulWidget {
  static String routeName = '/web-company-detail';
  final String companyId;
  final Company? company;

  WebCompanyDetailScreen({
    Key? key,
    required this.companyId,
    this.company,
  }) : super(key: key);

  @override
  State<WebCompanyDetailScreen> createState() => _WebCompanyDetailScreenState();
}

class _WebCompanyDetailScreenState extends State<WebCompanyDetailScreen> {
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  Company? _currentCompany;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize company immediately if provided to prevent loading screen flash
    if (widget.company != null) {
      _currentCompany = widget.company;
    }
    _initializeCompany();
  }

  Future<void> _initializeCompany() async {
    print('[WEB COMPANY DETAIL] Initializing company: ${widget.companyId}');
    print('[WEB COMPANY DETAIL] Has company data: ${widget.company != null}');

    if (widget.company != null) {
      // Company data provided, already set in initState, just fetch compounds
      print('[WEB COMPANY DETAIL] Using provided company data: ${widget.company!.name}');
      _fetchCompounds();
    } else {
      // No company data, fetch from API
      print('[WEB COMPANY DETAIL] Fetching company from API');
      await _fetchCompany();
    }
  }

  Future<void> _fetchCompany() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companyData = await _companyWebServices.getCompanyById(widget.companyId);
      final company = Company.fromJson(companyData);

      setState(() {
        _currentCompany = company;
        _isLoading = false;
      });

      _fetchCompounds();
    } catch (e) {
      print('[WEB COMPANY DETAIL] Error fetching company: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _fetchCompounds() {
    if (_currentCompany != null) {
      context.read<CompoundBloc>().add(
        FetchCompoundsByCompanyEvent(companyId: _currentCompany!.id),
      );
    }
  }

  String _getCompanyName(AppLocalizations l10n) {
    if (_currentCompany == null) return '';
    final isArabic = l10n.localeName == 'ar';
    return _currentCompany!.getLocalizedName(isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Text(
            'Loading...',
            style: TextStyle(
              color: AppColors.mainColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mainColor),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Text(
            'Error',
            style: TextStyle(
              color: AppColors.mainColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCompany,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Company not loaded yet
    if (_currentCompany == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mainColor),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            automaticallyImplyLeading: true,
            title: Text(
              _getCompanyName(l10n),
              style: TextStyle(
                color: AppColors.mainColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: AppColors.mainColor),
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
                        id: _currentCompany!.id.toString(),
                        compounds: compounds,
                      ),
                    );
                  }
                },
              ),
              SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompanyHeader(l10n),
                      SizedBox(height: 32),
                      _buildStatsSection(l10n),
                      SizedBox(height: 48),
                      _buildContactInfo(l10n),
                      SizedBox(height: 48),
                      _buildCompoundsSection(l10n),
                      SizedBox(height: 48),


                      if (_currentCompany!.sales.isNotEmpty) ...[
                        _buildSalespeopleSection(l10n),
                        SizedBox(height: 48),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Floating Comparison Cart
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingComparisonCart(isWeb: true),
        ),
      ],
    );
  }

  Widget _buildCompanyHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.mainColor.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (_currentCompany!.logo != null)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mainColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: RobustNetworkImage(
                imageUrl: _currentCompany!.logo!,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, url) => Icon(
                  Icons.business,
                  size: 70,
                  color: AppColors.mainColor,
                ),
              ),
            )
          else
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getCompanyName(l10n)[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.developer.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _getCompanyName(l10n),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _currentCompany!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.apartment,
            _currentCompany!.numberOfCompounds,
            l10n.compounds,
            AppColors.mainColor,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            Icons.home_outlined,
            _currentCompany!.numberOfAvailableUnits,
            l10n.availableUnits,
            Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            Icons.people_outline,
            _currentCompany!.salesCount.toString(),
            l10n.salesTeam,
            Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, size: 28, color: AppColors.mainColor),
              SizedBox(width: 12),
              Text(
                l10n.contactInformation,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on, color: AppColors.mainColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.headOffice,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      l10n.cairoEgypt,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.email, color: AppColors.mainColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentCompany!.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalespeopleSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.support_agent, size: 28, color: AppColors.mainColor),
            SizedBox(width: 12),
            Text(
              l10n.salesTeam,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: _currentCompany!.sales.length,
          itemBuilder: (context, index) {
            final sales = _currentCompany!.sales[index];
            return Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.06),
                    blurRadius: 15,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            sales.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sales.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 18, color: AppColors.mainColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sales.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email, size: 18, color: AppColors.mainColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sales.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompoundsSection(AppLocalizations l10n) {
    return BlocBuilder<CompoundBloc, CompoundState>(
      builder: (context, state) {
        if (state is CompoundLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
                  SizedBox(width: 12),
                  Text(
                    l10n.ourProjects,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.mainColor),
                ),
              ),
            ],
          );
        }

        if (state is CompoundError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
                  SizedBox(width: 12),
                  Text(
                    l10n.ourProjects,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        state.message,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CompoundBloc>().add(
                            FetchCompoundsByCompanyEvent(companyId: _currentCompany!.id),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (state is CompoundSuccess) {
          if (state.response.data.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
                    SizedBox(width: 12),
                    Text(
                      l10n.ourProjects,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment,
                          size: 64,
                          color: AppColors.greyText,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l10n.noCompoundsAvailable,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final compounds = state.response.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
                  SizedBox(width: 12),
                  Text(
                    l10n.ourProjects,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300, // Unified width to match other screens
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
                ),
                itemCount: compounds.length,
                itemBuilder: (context, index) {
                  final compound = compounds[index];
                  return WebCompoundCard(compound: compound);
                },
              ),
            ],
          );
        }

        // State is not CompoundSuccess, CompoundLoading, or CompoundError
        // This happens when navigating back from compound detail (state is CompoundDetailSuccess)
        // Re-fetch compounds for this company
        if (_currentCompany != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CompoundBloc>().add(
              FetchCompoundsByCompanyEvent(companyId: _currentCompany!.id),
            );
          });
        }

        // Show loading indicator while re-fetching
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
                SizedBox(width: 12),
                Text(
                  l10n.ourProjects,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.mainColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
