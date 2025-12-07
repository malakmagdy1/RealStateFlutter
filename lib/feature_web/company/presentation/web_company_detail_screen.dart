import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/ai_chat/presentation/widget/floating_comparison_cart.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/data/services/sale_web_services.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../../feature_web/widgets/web_compound_card.dart';

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
  final SaleWebServices _saleWebServices = SaleWebServices();
  Company? _currentCompany;
  bool _isLoading = false;
  String? _errorMessage;
  List<Compound> _compounds = [];
  List<Sale> _activeSales = [];

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

    // Always fetch from API to get complete compound data with unit counts
    // The widget.company from list view might not have full compound details
    print('[WEB COMPANY DETAIL] Fetching company from API for complete data');
    await _fetchCompany();

    // Fetch active sales for this company
    await _fetchCompanySales();
  }

  Future<void> _fetchCompanySales() async {
    try {
      print('[WEB COMPANY DETAIL] Fetching sales for company: ${widget.companyId}');
      final salesData = await _saleWebServices.getSalesByCompany(widget.companyId);

      if (salesData['success'] == true && salesData['data'] != null) {
        final salesList = salesData['data'] as List;
        setState(() {
          _activeSales = salesList.map((s) => Sale.fromJson(s)).toList();
        });
        print('[WEB COMPANY DETAIL] Found ${_activeSales.length} active sales');
      }
    } catch (e) {
      print('[WEB COMPANY DETAIL] Error fetching sales: $e');
    }
  }

  /// Convert CompanyCompound objects to Compound objects for display
  void _convertCompoundsFromCompany() {
    if (_currentCompany == null) return;

    final companyCompounds = _currentCompany!.compounds;
    print('[WEB COMPANY DETAIL] Converting ${companyCompounds
        .length} compounds from company data');

    // Safely get locale - default to English if context not ready
    bool isArabic = false;
    try {
      isArabic = Localizations
          .localeOf(context)
          .languageCode == 'ar';
    } catch (e) {
      print('[WEB COMPANY DETAIL] Could not get locale, defaulting to English');
    }

    _compounds = companyCompounds.map((cc) {
      print('[WEB COMPANY DETAIL] Compound ${cc.project}: totalUnits=${cc
          .totalUnits}, availableUnits=${cc.availableUnits}, soldUnits=${cc
          .soldUnits}');

      // Get localized name based on current locale
      final projectName = cc.getLocalizedProject(isArabic);
      final locationName = cc.getLocalizedLocation(isArabic);

      return Compound(
        id: cc.id,
        companyId: _currentCompany!.id,
        project: projectName.isNotEmpty ? projectName : cc.project,
        location: locationName.isNotEmpty ? locationName : cc.location,
        locationUrl: null,
        images: cc.images,
        builtUpArea: '0',
        // Not available in CompanyCompound
        howManyFloors: '0',
        // Not available in CompanyCompound
        plannedDeliveryDate: null,
        actualDeliveryDate: null,
        completionProgress: cc.completionProgress,
        landArea: null,
        builtArea: null,
        finishSpecs: null,
        masterPlan: null,
        club: '0',
        isSold: '0',
        status: cc.status,
        deliveredAt: null,
        totalUnits: cc.totalUnits,
        createdAt: '',
        updatedAt: '',
        deletedAt: null,
        companyName: _currentCompany!.getLocalizedName(isArabic),
        companyLogo: _currentCompany!.fullLogoUrl,
        soldUnits: cc.soldUnits,
        availableUnits: cc.availableUnits,
        sales: [],
      );
    }).toList();

    setState(() {});
  }

  Future<void> _fetchCompany() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companyData = await _companyWebServices.getCompanyById(widget.companyId);

      // Debug: Log compound data from API
      print('[WEB COMPANY DETAIL] Raw company data keys: ${companyData.keys.toList()}');
      if (companyData['compounds'] != null) {
        final compoundsList = companyData['compounds'] as List;
        print('[WEB COMPANY DETAIL] API returned ${compoundsList.length} compounds');
        for (var i = 0; i < compoundsList.length && i < 3; i++) {
          final c = compoundsList[i];
          print('[WEB COMPANY DETAIL] Compound $i: total_units=${c['total_units']}, available_units=${c['available_units']}, sold_units=${c['sold_units']}');
        }
      } else {
        print('[WEB COMPANY DETAIL] No compounds field in API response');
      }

      final company = Company.fromJson(companyData);
      print('[WEB COMPANY DETAIL] Parsed company: ${company.name}, compounds count: ${company.compounds.length}');

      if (company.compounds.isNotEmpty) {
        final firstCompound = company.compounds.first;
        print('[WEB COMPANY DETAIL] First compound after parsing: totalUnits=${firstCompound.totalUnits}, availableUnits=${firstCompound.availableUnits}');
      }

      setState(() {
        _currentCompany = company;
        _isLoading = false;
      });

      // Convert compounds from company data (which includes unit counts)
      _convertCompoundsFromCompany();
    } catch (e) {
      print('[WEB COMPANY DETAIL] Error fetching company: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
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
                  // Use local compounds data for advanced share
                  List<Map<String, dynamic>>? compounds;

                  if (_compounds.isNotEmpty) {
                    compounds = _compounds.map((compound) {
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

                      // Active Sales/Promotions Section
                      if (_activeSales.isNotEmpty) ...[
                        _buildSalesSection(l10n),
                        SizedBox(height: 48),
                      ],

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
          // Phone number section
          if (_currentCompany!.phone != null && _currentCompany!.phone!.isNotEmpty) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF26A69A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phone, color: Color(0xFF26A69A)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                      SizedBox(height: 4),
                      SelectableText(
                        _currentCompany!.phone!,
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

  Widget _buildSalesSection(AppLocalizations l10n) {
    final isArabic = l10n.localeName == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, size: 28, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              l10n.activeSales,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeSales.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: _activeSales.length,
          itemBuilder: (context, index) {
            final sale = _activeSales[index];
            return _buildSaleCard(sale, l10n, isArabic);
          },
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale, AppLocalizations l10n, bool isArabic) {
    // Determine sale type color and icon
    Color saleColor;
    IconData saleIcon;
    String saleTypeLabel;

    switch (sale.saleType.toLowerCase()) {
      case 'discount':
        saleColor = Colors.red;
        saleIcon = Icons.percent;
        saleTypeLabel = l10n.discount;
        break;
      case 'cashback':
        saleColor = Colors.green;
        saleIcon = Icons.money;
        saleTypeLabel = isArabic ? 'استرداد نقدي' : 'Cashback';
        break;
      case 'gift':
        saleColor = Colors.purple;
        saleIcon = Icons.card_giftcard;
        saleTypeLabel = isArabic ? 'هدية' : 'Gift';
        break;
      case 'installment':
        saleColor = Colors.blue;
        saleIcon = Icons.credit_card;
        saleTypeLabel = isArabic ? 'تقسيط' : 'Installment';
        break;
      default:
        saleColor = Colors.orange;
        saleIcon = Icons.local_offer;
        saleTypeLabel = isArabic ? 'عرض' : 'Offer';
    }

    final title = sale.saleName;
    final description = sale.description;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: saleColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: saleColor.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon/Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: saleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(saleIcon, color: saleColor, size: 28),
                SizedBox(height: 4),
                if (sale.discountPercentage > 0)
                  Text(
                    '${sale.discountPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: saleColor,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sale type badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: saleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    saleTypeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: saleColor,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8),
                // Dates
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Color(0xFF999999)),
                    SizedBox(width: 4),
                    Text(
                      '${_formatDate(sale.startDate)} - ${_formatDate(sale.endDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildCompoundsSection(AppLocalizations l10n) {
    // Show empty state if no compounds
    if (_compounds.isEmpty) {
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

    // Show compounds grid
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
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _compounds.length,
          itemBuilder: (context, index) {
            final compound = _compounds[index];
            return WebCompoundCard(compound: compound);
          },
        ),
      ],
    );
  }
}
