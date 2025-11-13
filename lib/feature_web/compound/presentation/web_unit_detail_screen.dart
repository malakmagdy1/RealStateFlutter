import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/web_services/unit_web_services.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/zoomable_image_viewer.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import '../../../feature/share/presentation/widgets/share_bottom_sheet.dart';
import '../../../feature/company/data/web_services/company_web_services.dart';
import '../../../feature/company/data/models/company_user_model.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';
import '../../../feature/sale/data/services/sale_web_services.dart';
import '../../../feature/sale/data/models/sale_model.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

class WebUnitDetailScreen extends StatefulWidget {
  static String routeName = '/web-unit-detail';
  final String unitId;
  final Unit? unit;

  WebUnitDetailScreen({
    Key? key,
    required this.unitId,
    this.unit,
  }) : super(key: key);

  @override
  State<WebUnitDetailScreen> createState() => _WebUnitDetailScreenState();
}

class _WebUnitDetailScreenState extends State<WebUnitDetailScreen> with SingleTickerProviderStateMixin {
  final UnitWebServices _unitWebServices = UnitWebServices();
  Unit? _currentUnit;
  bool _isLoadingUnit = false;
  String? _errorMessage;

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

  // Notes
  final FavoritesWebServices _favoritesWebServices = FavoritesWebServices();
  List<Map<String, dynamic>> _unitNotes = [];
  bool _isLoadingNotes = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeUnit();
  }

  Future<void> _initializeUnit() async {
    if (widget.unit != null) {
      // Unit passed from previous screen
      _currentUnit = widget.unit;

      // Check if unit has complete price data
      // If unit has a sale but missing price data, refetch from API to get complete info
      bool hasSale = _currentUnit!.hasActiveSale == true || _currentUnit!.sale != null;
      bool missingPriceData = (_currentUnit!.originalPrice == null || _currentUnit!.originalPrice!.isEmpty) &&
                               (_currentUnit!.normalPrice == null || _currentUnit!.normalPrice!.isEmpty) &&
                               (_currentUnit!.price.isEmpty || _currentUnit!.price == '0');

      print('[WEB UNIT DETAIL] ========================================');
      print('[WEB UNIT DETAIL] Unit passed from navigation - ID: ${_currentUnit!.id}');
      print('[WEB UNIT DETAIL] Has sale: $hasSale');
      print('[WEB UNIT DETAIL] Missing price data: $missingPriceData');
      print('[WEB UNIT DETAIL] originalPrice: ${_currentUnit!.originalPrice}');
      print('[WEB UNIT DETAIL] normalPrice: ${_currentUnit!.normalPrice}');
      print('[WEB UNIT DETAIL] price: ${_currentUnit!.price}');

      if (hasSale && missingPriceData) {
        print('[WEB UNIT DETAIL] Unit has sale but missing price data - refetching from API...');
        await _fetchUnit(); // Refetch to get complete data
      } else {
        print('[WEB UNIT DETAIL] Unit has complete data - using passed unit');
        _setupUnit();
      }
      print('[WEB UNIT DETAIL] ========================================');
    } else {
      // Fetch from API if not passed
      print('[WEB UNIT DETAIL] No unit passed - fetching from API...');
      await _fetchUnit();
    }
  }

  Future<void> _fetchUnit() async {
    setState(() {
      _isLoadingUnit = true;
      _errorMessage = null;
    });

    try {
      final unitData = await _unitWebServices.getUnitById(widget.unitId); // ✅ Correct param type: String
      final unit = Unit.fromJson(unitData);

      setState(() {
        _currentUnit = unit;
        _isLoadingUnit = false;
      });

      _setupUnit();
    } catch (e) {
      print('[WEB UNIT DETAIL] Error fetching unit: $e');
      setState(() {
        _isLoadingUnit = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _setupUnit() {
    if (_currentUnit != null) {
      _fetchSalesPeople();
      // Check if sale is included in unit data first
      if (_currentUnit!.sale != null) {
        print('[WEB UNIT DETAIL] Sale found in unit data: ${_currentUnit!.sale!.saleName}');
        setState(() {
          _unitSale = _currentUnit!.sale;
        });
      } else {
        // If not included, fetch separately from API
        print('[WEB UNIT DETAIL] No sale in unit data, fetching from API...');
        _fetchUnitSale();
      }
      _fetchUnitNotes();
      _startImageRotation();

      // Track view history
      ViewHistoryService().addViewedUnit(_currentUnit!);
    }
  }

  void _startImageRotation() {
    if (_currentUnit?.images.isEmpty ?? true) return;

    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _currentUnit!.images.isNotEmpty) {
        setState(() {
          _selectedImageIndex = (_selectedImageIndex + 1) % _currentUnit!.images.length;
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
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesPeople() async {
    if (_currentUnit?.companyId == null || _currentUnit!.companyId!.isEmpty) return;
    if (_isLoadingSalesPeople) return;

    setState(() => _isLoadingSalesPeople = true);

    try {
      final companyData = await _companyWebServices.getCompanyById(_currentUnit!.companyId!);

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
      final response = await _saleWebServices.getSalesByUnit(_currentUnit!.id);

      print('[WEB UNIT DETAIL] Sale response for unit ${_currentUnit!.id}: $response');

      if (response['success'] == true && response['sales'] != null) {
        final salesList = response['sales'] as List;
        print('[WEB UNIT DETAIL] Processing ${salesList.length} sales from API');

        final sales = salesList.map((saleData) {
          final saleJson = Map<String, dynamic>.from(saleData as Map<String, dynamic>);

          // If sale doesn't have old_price/new_price, calculate from unit data
          if ((saleJson['old_price'] == null || saleJson['old_price'] == 0) &&
              (saleJson['new_price'] == null || saleJson['new_price'] == 0)) {

            print('[WEB UNIT DETAIL] Sale missing prices, calculating from unit data...');
            print('[WEB UNIT DETAIL] Unit originalPrice: ${_currentUnit!.originalPrice}');
            print('[WEB UNIT DETAIL] Unit normalPrice: ${_currentUnit!.normalPrice}');
            print('[WEB UNIT DETAIL] Unit price: ${_currentUnit!.price}');

            double unitPrice = 0.0;

            // Priority: original_price > normal_price > price
            if (_currentUnit!.originalPrice != null && _currentUnit!.originalPrice!.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.originalPrice!) ?? 0.0;
              print('[WEB UNIT DETAIL] Using originalPrice: $unitPrice');
            } else if (_currentUnit!.normalPrice != null && _currentUnit!.normalPrice!.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.normalPrice!) ?? 0.0;
              print('[WEB UNIT DETAIL] Using normalPrice: $unitPrice');
            } else if (_currentUnit!.price.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.price) ?? 0.0;
              print('[WEB UNIT DETAIL] Using price: $unitPrice');
            }

            final discountPercent = saleJson['discount_percentage'] is num
                ? (saleJson['discount_percentage'] as num).toDouble()
                : double.tryParse(saleJson['discount_percentage']?.toString() ?? '0') ?? 0.0;

            print('[WEB UNIT DETAIL] Discount percentage: $discountPercent');

            if (unitPrice > 0 && discountPercent > 0) {
              saleJson['old_price'] = unitPrice;
              saleJson['new_price'] = unitPrice * (1 - (discountPercent / 100));
              saleJson['savings'] = unitPrice * (discountPercent / 100);
              print('[WEB UNIT DETAIL] ✓ Calculated prices - Old: ${saleJson['old_price']}, New: ${saleJson['new_price']}, Savings: ${saleJson['savings']}');
            } else {
              print('[WEB UNIT DETAIL] ✗ Cannot calculate - unitPrice: $unitPrice, discount: $discountPercent');
            }
          }

          return Sale.fromJson(saleJson);
        }).toList();

        // Filter for only currently active sales that match this unit
        final activeSales = sales.where((sale) {
          // Must be currently active
          if (!sale.isCurrentlyActive) return false;

          // Check if sale applies to this specific unit or compound
          if (sale.saleType.toLowerCase() == 'unit') {
            // Unit-specific sale: must match exact unit ID
            return sale.unitId == _currentUnit!.id;
          } else if (sale.saleType.toLowerCase() == 'compound') {
            // Compound-wide sale: must match compound ID
            return sale.compoundId == _currentUnit!.compoundId;
          }

          return false;
        }).toList();

        print('[WEB UNIT DETAIL] Found ${activeSales.length} matching sales for this unit');
        if (activeSales.isNotEmpty) {
          print('[WEB UNIT DETAIL] First sale: ${activeSales.first.saleName} - Type: ${activeSales.first.saleType}');
          print('[WEB UNIT DETAIL] Sale prices - Old: ${activeSales.first.oldPrice}, New: ${activeSales.first.newPrice}, Savings: ${activeSales.first.savings}');
        }

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

  String _getBestPrice() {
    // Priority: discountedPrice > totalPrice > normalPrice > originalPrice > price
    if (_currentUnit!.discountedPrice != null &&
        _currentUnit!.discountedPrice!.isNotEmpty &&
        _currentUnit!.discountedPrice != '0') {
      return _currentUnit!.discountedPrice!;
    }
    if (_currentUnit!.totalPrice != null &&
        _currentUnit!.totalPrice!.isNotEmpty &&
        _currentUnit!.totalPrice != '0') {
      return _currentUnit!.totalPrice!;
    }
    if (_currentUnit!.normalPrice != null &&
        _currentUnit!.normalPrice!.isNotEmpty &&
        _currentUnit!.normalPrice != '0') {
      return _currentUnit!.normalPrice!;
    }
    if (_currentUnit!.originalPrice != null &&
        _currentUnit!.originalPrice!.isNotEmpty &&
        _currentUnit!.originalPrice != '0') {
      return _currentUnit!.originalPrice!;
    }
    return _currentUnit!.price;
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
        id: _currentUnit!.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Show loading state
    if (_isLoadingUnit) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
          child: CustomLoadingDots(size: 120),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
                onPressed: _fetchUnit,
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

    // Unit not loaded yet
    if (_currentUnit == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CustomLoadingDots(size: 120),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
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
                        SizedBox(height: 16),
                        // Always show price card
                        _buildPriceCard(l10n),
                        SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.white,
                          indicator: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          unselectedLabelColor: AppColors.grey,
                          indicatorColor: AppColors.mainColor,
                          indicatorWeight: 3,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          tabs: [
                            Tab(text: l10n.details),
                            Tab(text: l10n.gallery),
                            Tab(text: l10n.location),
                            Tab(text: l10n.floorPlan),
                            Tab(text: l10n.notes),
                          ],
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
                              _buildLocationTab(l10n),
                              _buildFloorPlanTab(l10n),
                              _buildNotesTab(),
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
                        if (_unitSale != null) ...[
                          _buildSaleSection(_unitSale!, l10n),
                          SizedBox(height: 16),
                        ],
                        // Unit Change Notes (if unit has updates)
                        UnitChangeNotes(unit: _currentUnit!),

                        // Tab Bar
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
    final images = _currentUnit!.images;
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
            mainAxisSize: MainAxisSize.min,
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
      child: GestureDetector(
        onTap: () {
          // Open zoomable image viewer
          ZoomableImageViewer.show(
            context,
            images: images,
            initialIndex: currentIndex,
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
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
        ),
      ),
    );
  }

  Widget _buildSaleSection(Sale sale, AppLocalizations l10n) {
    print('[SALE SECTION] ========================================');
    print('[SALE SECTION] Starting price calculation');
    print('[SALE SECTION] Sale object - oldPrice: ${sale.oldPrice}, newPrice: ${sale.newPrice}, savings: ${sale.savings}');
    print('[SALE SECTION] Sale discount: ${sale.discountPercentage}%');
    print('[SALE SECTION] Unit data - originalPrice: ${_currentUnit!.originalPrice}');
    print('[SALE SECTION] Unit data - normalPrice: ${_currentUnit!.normalPrice}');
    print('[SALE SECTION] Unit data - discountedPrice: ${_currentUnit!.discountedPrice}');
    print('[SALE SECTION] Unit data - price: ${_currentUnit!.price}');

    // Calculate prices from unit data (in case sale doesn't have them)
    double oldPrice = sale.oldPrice;
    double newPrice = sale.newPrice;
    double savings = sale.savings;

    // If sale doesn't have prices, calculate from unit data
    if (oldPrice == 0 || newPrice == 0) {
      print('[SALE SECTION] Sale prices are 0, calculating from unit data...');
      try {
        // Get original price from unit
        if (_currentUnit!.originalPrice != null && _currentUnit!.originalPrice!.isNotEmpty && _currentUnit!.originalPrice != '0') {
          oldPrice = double.parse(_currentUnit!.originalPrice!);
          print('[SALE SECTION] Got oldPrice from originalPrice: $oldPrice');
        } else if (_currentUnit!.normalPrice != null && _currentUnit!.normalPrice!.isNotEmpty && _currentUnit!.normalPrice != '0') {
          oldPrice = double.parse(_currentUnit!.normalPrice!);
          print('[SALE SECTION] Got oldPrice from normalPrice: $oldPrice');
        } else {
          print('[SALE SECTION] Could not get oldPrice from unit data');
        }

        // Get discounted price from unit
        if (_currentUnit!.discountedPrice != null && _currentUnit!.discountedPrice!.isNotEmpty && _currentUnit!.discountedPrice != '0') {
          newPrice = double.parse(_currentUnit!.discountedPrice!);
          print('[SALE SECTION] Got newPrice from discountedPrice: $newPrice');
        } else {
          print('[SALE SECTION] Could not get newPrice from unit data');
        }

        // Calculate savings
        if (oldPrice > 0 && newPrice > 0) {
          savings = oldPrice - newPrice;
          print('[SALE SECTION] Calculated savings: $savings');
        }
      } catch (e) {
        print('[SALE SECTION] Error calculating prices: $e');
      }
    }

    print('[SALE SECTION] Final prices - old: $oldPrice, new: $newPrice, savings: $savings');
    print('[SALE SECTION] ========================================');

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
              // Old Price
              Column(
                mainAxisSize: MainAxisSize.min,
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
                    'EGP ${_formatPrice(oldPrice.toString())}',
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
                mainAxisSize: MainAxisSize.min,
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
                    'EGP ${_formatPrice(newPrice.toString())}',
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
                mainAxisSize: MainAxisSize.min,
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
                    'EGP ${_formatPrice(savings.toString())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
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
            '${l10n.about} ${_currentUnit!.unitType}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          Text(
            _currentUnit!.view ?? l10n.noDescriptionAvailable,
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
          // Unit number and favorite button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentUnit!.unitNumber ?? 'Unit ${_currentUnit!.id}',
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                builder: (context, state) {
                  bool isFavorite = false;
                  if (state is UnitFavoriteUpdated) {
                    isFavorite = state.favorites.any((u) => u.id == _currentUnit!.id);
                  }
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : AppColors.mainColor,
                    ),
                    onPressed: () {
                      if (isFavorite) {
                        context.read<UnitFavoriteBloc>().add(
                          RemoveFavoriteUnit(_currentUnit!),
                        );
                      } else {
                        context.read<UnitFavoriteBloc>().add(
                          AddFavoriteUnit(_currentUnit!),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          // Pricing & Payment header
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
              'EGP ${_formatPrice(_unitSale!.oldPrice.toString())}',
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
              'EGP ${_formatPrice(_getBestPrice())}',
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
          _buildStatRow(Icons.bed_outlined, '${_currentUnit!.bedrooms}', l10n.bedrooms),
          SizedBox(height: 12),
          _buildStatRow(Icons.bathtub_outlined, '${_currentUnit!.bathrooms}', l10n.bathrooms),
          SizedBox(height: 12),
          _buildStatRow(Icons.square_foot_outlined, '${_currentUnit!.area}', l10n.sqm),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 16),
          Text(
            '${l10n.about} ${_currentUnit!.unitType ?? "Unit"}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          Text(
            _currentUnit!.view ?? l10n.noDescriptionAvailable,
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
            child: CustomLoadingDots(size: 40),
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
                    mainAxisSize: MainAxisSize.min,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          SizedBox(height: 24),
          _buildSpecRow('Unit Type', _currentUnit!.unitType ?? 'N/A'),
          _buildSpecRow('Usage Type', _currentUnit!.usageType ?? 'N/A'),
          _buildSpecRow(l10n.compound, _currentUnit!.compoundName ?? _currentUnit!.compoundId ?? 'N/A'),
          _buildSpecRow('Status', _currentUnit!.status ?? 'N/A'),
          _buildSpecRow('Available', _currentUnit!.available != null ? (_currentUnit!.available! ? 'Yes' : 'No') : 'N/A'),
          _buildSpecRow(l10n.saleType, 'Resale'),
          _buildSpecRow(l10n.finishing, _currentUnit!.finishing ?? 'N/A'),
          _buildSpecRow(l10n.deliveryDate, _formatDate(_currentUnit!.deliveryDate)),
          _buildSpecRow(l10n.builtUpArea, _currentUnit!.builtUpArea != null
            ? '${_currentUnit!.builtUpArea} ${l10n.sqm}'
            : (_currentUnit!.area != '0' ? '${_currentUnit!.area} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow('Total Area', _currentUnit!.area != '0' ? '${_currentUnit!.area} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.landArea, _currentUnit!.landArea != null
            ? '${_currentUnit!.landArea} ${l10n.sqm}'
            : (_currentUnit!.gardenArea != null && _currentUnit!.gardenArea != '0' ? '${_currentUnit!.gardenArea} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow('Garden Area', _currentUnit!.gardenArea != null && _currentUnit!.gardenArea != '0' ? '${_currentUnit!.gardenArea} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.roofArea, _currentUnit!.roofArea != null && _currentUnit!.roofArea != '0' ? '${_currentUnit!.roofArea} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.floor, _currentUnit!.floor ?? 'N/A'),
          _buildSpecRow(l10n.building, _currentUnit!.buildingName ?? 'N/A'),
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
    if (_currentUnit!.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      itemCount: _currentUnit!.images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ZoomableImageViewer.show(
              context,
              images: _currentUnit!.images,
              initialIndex: index,
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RobustNetworkImage(
                imageUrl: _currentUnit!.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationTab(AppLocalizations l10n) {
    final compoundLocation = widget.unit?.compoundName ?? '';
    final actualLocation = compoundLocation.isNotEmpty ? compoundLocation : l10n.locationNotAvailable;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 32,
                  color: AppColors.mainColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.location,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      l10n.compoundLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Location URL / Map
          if (widget.unit?.compoundLocationUrl != null && widget.unit!.compoundLocationUrl!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, size: 20, color: AppColors.mainColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.viewOnMap ?? 'View on Map',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(widget.unit!.compoundLocationUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Icon(Icons.location_on, color: Colors.white),
                      label: Text(
                        l10n.openLocationInMaps ?? 'Open Location in Maps',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                    SizedBox(height: 12),
                    Text(
                      l10n.mapViewNotAvailable,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloorPlanTab(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            l10n.floorPlanNotAvailable,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Fetch unit notes
  Future<void> _fetchUnitNotes() async {
    if (_isLoadingNotes) return;

    setState(() => _isLoadingNotes = true);

    try {
      final response = await _favoritesWebServices.getNotes(
        unitId: int.tryParse(_currentUnit!.id),
      );

      print('[WEB UNIT DETAIL] Notes response: $response');

      if (response['success'] == true) {
        List<Map<String, dynamic>> notes = [];

        // Check if data exists and has notes
        if (response['data'] != null && response['data']['notes'] != null) {
          notes = (response['data']['notes'] as List)
              .map((note) => note as Map<String, dynamic>)
              .toList();
        }

        if (mounted) {
          setState(() {
            _unitNotes = notes;
            _isLoadingNotes = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingNotes = false);
        }
      }
    } catch (e) {
      print('[WEB UNIT DETAIL] Error fetching notes: $e');
      if (mounted) {
        setState(() => _isLoadingNotes = false);
      }
    }
  }

  // Add note
  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) {
      MessageHelper.showError(context, 'Please enter a note');
      return;
    }

    try {
      final response = await _favoritesWebServices.createNote(
        content: _noteController.text.trim(),
        title: 'Unit Note',
        unitId: int.tryParse(_currentUnit!.id),
      );

      if (response['success'] == true) {
        _noteController.clear();
        MessageHelper.showSuccess(context, 'Note added successfully');
        _fetchUnitNotes();
      } else {
        MessageHelper.showError(context, 'Failed to add note');
      }
    } catch (e) {
      MessageHelper.showError(context, 'Error: $e');
    }
  }

  // Delete note
  Future<void> _deleteNote(int noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _favoritesWebServices.deleteNote(noteId);

      if (response['success'] == true) {
        MessageHelper.showSuccess(context, 'Note deleted successfully');
        _fetchUnitNotes();
      } else {
        MessageHelper.showError(context, 'Failed to delete note');
      }
    } catch (e) {
      MessageHelper.showError(context, 'Error: $e');
    }
  }

  // Build notes tab
  Widget _buildNotesTab() {
    return Column(
      children: [
        // Add note section
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addNote,
                icon: Icon(Icons.add, size: 18),
                label: Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),

        // Notes list
        Expanded(
          child: _isLoadingNotes
              ? Center(child: CustomLoadingDots(size: 80))
              : _unitNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notes yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first note above',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _unitNotes.length,
                      itemBuilder: (context, index) {
                        final note = _unitNotes[index];
                        final noteId = note['id'];
                        final content = note['content'] ?? '';
                        final createdAt = note['created_at'] ?? '';

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note, color: AppColors.mainColor, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      if (createdAt.isNotEmpty) ...[
                                        SizedBox(height: 6),
                                        Text(
                                          _formatNoteDate(createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _deleteNote(noteId),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatNoteDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

}
class UnitChangeNotes extends StatelessWidget {
  final Unit unit;

  const UnitChangeNotes({Key? key, required this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[UNIT CHANGE NOTES] isUpdated=${unit.isUpdated}, changeType=${unit.changeType}, changeProperties=${unit.changeProperties}');

    if (unit.isUpdated != true) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Recent Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Change type
          if (unit.changeType != null)
            _buildInfoRow(
              'Status',
              unit.changeType!.toUpperCase(),
              _getChangeColor(unit.changeType!),
            ),

          // Last changed date
          if (unit.lastChangedAt != null)
            _buildInfoRow(
              'Last Updated',
              _formatDate(unit.lastChangedAt!),
              Colors.grey.shade700,
            ),

          // Changed fields with values (from changeProperties)
          if (unit.changeProperties != null) ...[
            SizedBox(height: 12),
            Text(
              'What Changed:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            _buildChangesTable(unit.changeProperties!),
          ] else if (unit.changedFields != null && unit.changedFields!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Changed Fields:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unit.changedFields!.map((field) {
                return Chip(
                  label: Text(
                    field,
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getChangeColor(String changeType) {
    switch (changeType.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'updated':
        return Colors.orange;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildChangesTable(Map<String, dynamic> properties) {
    final changes = properties['changes'] as Map<String, dynamic>?;
    final original = properties['original'] as Map<String, dynamic>?;

    if (changes == null || changes.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: changes.entries.map((entry) {
          final fieldName = entry.key;
          final newValue = entry.value?.toString() ?? 'N/A';
          final oldValue = original?[fieldName]?.toString() ?? 'N/A';

          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Field name
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatFieldName(fieldName),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                // Original value
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      oldValue,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                // New value
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      newValue,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert snake_case to Title Case
    return fieldName
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
