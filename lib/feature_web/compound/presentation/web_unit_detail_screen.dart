import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import '../../../feature/share/presentation/widgets/share_bottom_sheet.dart';
import '../../../feature/company/data/web_services/company_web_services.dart';
import '../../../feature/company/data/models/company_user_model.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';
import '../../../feature/sale/data/services/sale_web_services.dart';
import '../../../feature/sale/data/models/sale_model.dart';

class WebUnitDetailScreen extends StatefulWidget {
  static String routeName = '/web-unit-detail';
  final Unit unit;

  WebUnitDetailScreen({Key? key, required this.unit}) : super(key: key);

  @override
  State<WebUnitDetailScreen> createState() => _WebUnitDetailScreenState();
}

class _WebUnitDetailScreenState extends State<WebUnitDetailScreen> with SingleTickerProviderStateMixin {
  int _selectedImageIndex = 0;
  Timer? _imageTimer;
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  final SaleWebServices _saleWebServices = SaleWebServices();
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
  Sale? _unitSale;
  bool _isLoadingSale = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchSalesPeople();
    _fetchUnitSale();
    _startImageRotation();
    // Track view history
    ViewHistoryService().addViewedUnit(widget.unit);
  }

  void _startImageRotation() {
    if (widget.unit.images.isEmpty) return;
    _imageTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && widget.unit.images.isNotEmpty) {
        setState(() {
          _selectedImageIndex = (_selectedImageIndex + 1) % widget.unit.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesPeople() async {
    if (widget.unit.companyId == null || widget.unit.companyId!.isEmpty) {
      return;
    }

    if (_isLoadingSalesPeople) return;

    setState(() => _isLoadingSalesPeople = true);

    try {
      final companyData = await _companyWebServices.getCompanyById(widget.unit.companyId!);

      if (companyData['users'] != null && companyData['users'] is List) {
        final allUsers = (companyData['users'] as List)
            .map((user) => CompanyUser.fromJson(user as Map<String, dynamic>))
            .toList();

        final salesPeople = allUsers.where((user) => user.isSales).toList();

        if (mounted) {
          setState(() {
            _salesPeople = salesPeople;
            _isLoadingSalesPeople = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingSalesPeople = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSalesPeople = false);
      }
    }
  }

  Future<void> _fetchUnitSale() async {
    if (_isLoadingSale) return;

    setState(() => _isLoadingSale = true);

    try {
      final response = await _saleWebServices.getSalesByUnit(widget.unit.id);

      print('[WEB UNIT DETAIL] Sale response for unit ${widget.unit.id}: $response');

      if (response['success'] == true && response['sales'] != null) {
        final sales = (response['sales'] as List)
            .map((s) => Sale.fromJson(s as Map<String, dynamic>))
            .toList();

        // Filter for only currently active sales
        final activeSales = sales.where((sale) => sale.isCurrentlyActive).toList();

        if (activeSales.isNotEmpty && mounted) {
          setState(() {
            _unitSale = activeSales.first; // Take the first currently active sale
            _isLoadingSale = false;
          });
        } else {
          if (mounted) {
            setState(() => _isLoadingSale = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingSale = false);
        }
      }
    } catch (e) {
      print('[WEB UNIT DETAIL] Error fetching unit sale: $e');
      if (mounted) {
        setState(() => _isLoadingSale = false);
      }
    }
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      return numPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return price;
    }
  }

  void _shareUnit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        type: 'unit',
        id: widget.unit.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.mainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.unit.unitNumber ?? 'Unit ${widget.unit.id}',
          style: TextStyle(
            color: AppColors.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
            builder: (context, state) {
              bool isFavorite = false;
              if (state is UnitFavoriteUpdated) {
                isFavorite = state.favorites.any((u) => u.id == widget.unit.id);
              }
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppColors.mainColor,
                ),
                onPressed: () {
                  if (isFavorite) {
                    context.read<UnitFavoriteBloc>().add(
                      RemoveFavoriteUnit(widget.unit),
                    );
                  } else {
                    context.read<UnitFavoriteBloc>().add(
                      AddFavoriteUnit(widget.unit),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Main Content
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageGallery(),
                        SizedBox(height: 20),
                        // Show sale information if available
                        if (_unitSale != null) ...[
                          _buildSaleSection(_unitSale!, l10n),
                          SizedBox(height: 16),
                        ],
                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.mainColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AppColors.mainColor,
                            indicatorWeight: 3,
                            tabs: [
                              Tab(text: l10n.details),
                              Tab(text: l10n.gallery),
                              Tab(text: l10n.viewOnMap),
                              Tab(text: l10n.requestInfo),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Tab Bar View
                        Container(
                          height: 600,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildDetailsTab(l10n),
                              _buildGalleryTab(),
                              _buildMapTab(l10n),
                              _buildRequestTab(l10n),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  // Right Column - Price Card & Contact
                  Container(
                    width: 320,
                    child: Column(
                      children: [
                        _buildPriceCard(l10n),
                        SizedBox(height: 16),
                        _buildAgentCard(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.unit.images;
    final hasImages = images.isNotEmpty;

    if (!hasImages) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 60, color: AppColors.mainColor.withOpacity(0.3)),
              SizedBox(height: 12),
              Text(
                'No images available',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      );
    }

    final currentIndex = _selectedImageIndex % images.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            RobustNetworkImage(
              imageUrl: images[currentIndex],
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, url) => Container(
                height: 350,
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              ),
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Image counter
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${currentIndex + 1} / ${images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSection(Sale sale, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF6B6B).withOpacity(0.1),
            Color(0xFFFFE66D).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6B6B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'SALE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sale.discountPercentage.toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            sale.saleName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            sale.description,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Old Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'EGP ${_formatPrice(sale.oldPrice.toString())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 32),
              // New Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sale Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mainColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'EGP ${_formatPrice(sale.newPrice.toString())}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 32),
              // Savings
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You Save',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'EGP ${_formatPrice(sale.savings.toString())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (sale.daysRemaining > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    '${sale.daysRemaining.toInt()} days remaining',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.about} ${widget.unit.unitType}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.unit.view ?? l10n.noDescriptionAvailable,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(AppLocalizations l10n) {
    final amenities = [
      {'icon': Icons.pool, 'label': l10n.swimmingPool},
      {'icon': Icons.fitness_center, 'label': l10n.gym},
      {'icon': Icons.wifi, 'label': 'Internet'},
      {'icon': Icons.electric_bolt, 'label': 'Electric'},
      {'icon': Icons.ac_unit, 'label': 'AC'},
      {'icon': Icons.local_parking, 'label': l10n.parking},
      {'icon': Icons.security, 'label': l10n.security247},
      {'icon': Icons.child_care, 'label': l10n.kidsArea},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.amenities,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE6E6E6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      amenity['icon'] as IconData,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        amenity['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, size: 18, color: AppColors.mainColor),
              SizedBox(width: 8),
              Text(
                l10n.pricingPayment,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Price - show sale price if available
          if (_unitSale != null) ...[
            Text(
              'EGP ${_formatPrice(widget.unit.price)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'EGP ${_formatPrice(_unitSale!.newPrice.toString())}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainColor,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_unitSale!.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'EGP ${_formatPrice(widget.unit.price)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 16),
          // Property Stats
          _buildStatRow(Icons.bed_outlined, '${widget.unit.bedrooms}', l10n.bedrooms),
          SizedBox(height: 12),
          _buildStatRow(Icons.bathtub_outlined, '${widget.unit.bathrooms}', l10n.bathrooms),
          SizedBox(height: 12),
          _buildStatRow(Icons.square_foot_outlined, '${widget.unit.area}', l10n.sqm),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 16),
          // Schedule a Tour Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.requestSubmittedSuccessfully),
                    backgroundColor: AppColors.mainColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Schedule a Tour',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mainColor),
        SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(AppLocalizations l10n) {
    if (_isLoadingSalesPeople) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.mainColor, strokeWidth: 2),
          ),
        ),
      );
    }

    // Get contact info prioritizing sales person from sale
    final salesPerson = _unitSale?.salesPerson;
    final companyAgent = _salesPeople.isNotEmpty ? _salesPeople.first : null;

    // Determine which contact to show
    final String? contactPhone = salesPerson?.phone ?? companyAgent?.phone;
    final String? contactName = salesPerson?.name ?? companyAgent?.name;
    final bool hasContact = contactName != null && contactName.isNotEmpty;
    final bool hasPhone = contactPhone != null && contactPhone.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contactSales,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 16),
          if (hasContact) ...[
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contactName!.isNotEmpty ? contactName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sales Agent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (hasPhone) ...[
              _buildContactButton(
                icon: Icons.phone,
                label: l10n.callNow,
                color: AppColors.mainColor,
                onTap: () async {
                  final uri = Uri.parse('tel:$contactPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              SizedBox(height: 8),
              _buildContactButton(
                icon: Icons.chat,
                label: l10n.whatsapp,
                color: Color(0xFF25D366),
                onTap: () async {
                  final uri = Uri.parse('https://wa.me/$contactPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ] else ...[
            Text(
              l10n.noSalesPersonAvailable,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // Tab content methods
  Widget _buildDetailsTab(AppLocalizations l10n) {
    String _formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'N/A';
      try {
        final date = DateTime.parse(dateStr);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        if (dateStr.contains('T')) return dateStr.split('T')[0];
        return dateStr;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          Text(
            '${l10n.about} ${widget.unit.unitType ?? "Unit"}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.unit.view ?? l10n.noDescriptionAvailable,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          // Unit Specifications
          _buildSpecRow(l10n.compound, widget.unit.compoundName ?? 'N/A'),
          _buildSpecRow(l10n.saleType, 'Resale'),
          _buildSpecRow(l10n.finishing, widget.unit.finishing ?? 'N/A'),
          _buildSpecRow(l10n.deliveryDate, _formatDate(widget.unit.deliveryDate)),
          _buildSpecRow(l10n.builtUpArea, '${widget.unit.area ?? "0"} ${l10n.sqm}'),
          if (widget.unit.gardenArea != null && widget.unit.gardenArea!.isNotEmpty && widget.unit.gardenArea != '0')
            _buildSpecRow(l10n.landArea, '${widget.unit.gardenArea} ${l10n.sqm}'),
          _buildSpecRow(l10n.floor, widget.unit.floor ?? 'N/A'),
          _buildSpecRow(l10n.numberOfBedrooms, widget.unit.bedrooms ?? '0'),
          _buildSpecRow(l10n.numberOfBathrooms, widget.unit.bathrooms ?? '0'),
          if (widget.unit.buildingName != null && widget.unit.buildingName!.isNotEmpty)
            _buildSpecRow(l10n.building, widget.unit.buildingName!),
          if (widget.unit.roofArea != null && widget.unit.roofArea!.isNotEmpty && widget.unit.roofArea != '0')
            _buildSpecRow(l10n.roofArea, '${widget.unit.roofArea} ${l10n.sqm}'),
          _buildSpecRow(l10n.price, 'EGP ${_formatPrice(widget.unit.price)}'),
          SizedBox(height: 24),
          // Amenities
          _buildAmenitiesSection(l10n),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (widget.unit.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No images available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.unit.images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: RobustNetworkImage(
            imageUrl: widget.unit.images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTab(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            l10n.mapViewNotAvailable,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.requestInfo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fill out the form below and we\'ll get back to you shortly.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.yourName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request submitted! We will contact you soon.'),
                    backgroundColor: AppColors.mainColor,
                  ),
                );
                _nameController.clear();
                _phoneController.clear();
                _emailController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.submitRequest,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
