import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/unit_model.dart';
import '../../data/web_services/compound_web_services.dart';
import '../../../sale/data/models/sale_model.dart';
import '../../../sale/data/services/sale_web_services.dart';
import '../../../sale/presentation/widgets/sales_person_selector.dart';
import '../../../share/presentation/widgets/share_bottom_sheet.dart';
import '../../../company/data/web_services/company_web_services.dart';
import '../../../company/data/models/company_user_model.dart';
import '../../data/models/compound_model.dart';
import '../bloc/favorite/unit_favorite_bloc.dart';
import '../bloc/favorite/unit_favorite_state.dart';
import '../bloc/favorite/unit_favorite_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../search/data/services/view_history_service.dart';

class UnitDetailScreen extends StatefulWidget {
  static String routeName = '/unit-detail';
  final Unit unit;

  UnitDetailScreen({Key? key, required this.unit}) : super(key: key);

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late PageController _imagePageController;
  Timer? _autoSlideTimer;
  final CompoundWebServices _compoundWebServices = CompoundWebServices();
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  final SaleWebServices _saleWebServices = SaleWebServices();
  late TabController _tabController;
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
  Sale? _unitSale;
  bool _isLoadingSale = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Track view history
    ViewHistoryService().addViewedUnit(widget.unit);
    _imagePageController = PageController();
    _tabController = TabController(length: 4, vsync: this);
    _startAutoSlide();
    _fetchSalesPeople();
    _fetchUnitSale();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _imagePageController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    // Only start auto-slide if there are multiple images
    if (widget.unit.images.length > 1) {
      _autoSlideTimer = Timer.periodic(Duration(seconds: 4), (timer) {
        if (mounted) {
          final nextIndex = (_currentImageIndex + 1) % widget.unit.images.length;
          _imagePageController.animateToPage(
            nextIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      // Format with thousand separators
      return numPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return price;
    }
  }

  String _calculatePricePerSqm() {
    try {
      final numPrice = double.parse(widget.unit.price);
      final numArea = double.parse(widget.unit.area);
      if (numArea > 0) {
        return (numPrice / numArea).toStringAsFixed(2);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '0';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Color _getStatusColor() {
    switch (widget.unit.status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'sold':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchSalesPeople() async {
    // Check if unit has companyId
    if (widget.unit.companyId == null || widget.unit.companyId!.isEmpty) {
      print('[UNIT DETAIL] No companyId available for this unit');
      return;
    }

    if (_isLoadingSalesPeople) return;

    setState(() {
      _isLoadingSalesPeople = true;
    });

    try {
      final companyData = await _companyWebServices.getCompanyById(widget.unit.companyId!);

      print('[UNIT DETAIL] Company data: $companyData');

      if (companyData['users'] != null && companyData['users'] is List) {
        final allUsers = (companyData['users'] as List)
            .map((user) => CompanyUser.fromJson(user as Map<String, dynamic>))
            .toList();

        // Filter only sales people
        final salesPeople = allUsers.where((user) => user.isSales).toList();

        print('[UNIT DETAIL] Found ${salesPeople.length} sales people');

        if (mounted) {
          setState(() {
            _salesPeople = salesPeople;
            _isLoadingSalesPeople = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSalesPeople = false;
          });
        }
      }
    } catch (e) {
      print('[UNIT DETAIL] Error fetching sales people: $e');
      if (mounted) {
        setState(() {
          _isLoadingSalesPeople = false;
        });
      }
    }
  }

  Future<void> _fetchUnitSale() async {
    if (_isLoadingSale) return;

    setState(() => _isLoadingSale = true);

    try {
      final response = await _saleWebServices.getSalesByUnit(widget.unit.id);

      print('[UNIT DETAIL] Sale response for unit ${widget.unit.id}: $response');

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
      print('[UNIT DETAIL] Error fetching unit sale: $e');
      if (mounted) {
        setState(() => _isLoadingSale = false);
      }
    }
  }

  Future<void> _showSalespeople() async {
    try {
      // Use compound ID as the search parameter since we don't have compound name in Unit model
      final response = await _compoundWebServices.getSalespeopleByCompound(widget.unit.compoundId);

      if (response['success'] == true && response['salespeople'] != null) {
        final salespeople = (response['salespeople'] as List)
            .map((sp) => SalesPerson.fromJson(sp as Map<String, dynamic>))
            .toList();

        if (salespeople.isNotEmpty && mounted) {
          SalesPersonSelector.show(
            context,
            salesPersons: salespeople,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noSalesPersonAvailable),
              backgroundColor: AppColors.mainColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _callNow() async {
    final phone = widget.unit.salesNumber ?? '';
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      _showSalespeople();
    }
  }

  void _openWhatsApp() async {
    final phone = widget.unit.salesNumber ?? '';
    if (phone.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _showSalespeople();
    }
  }

  void _requestInfo() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request submitted! We will contact you soon.'),
          backgroundColor: AppColors.mainColor,
        ),
      );
      _nameController.clear();
      _phoneController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = widget.unit.images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText18(
          l10n.unitDetails,
          bold: true,
          color: Colors.black,
        ),
        centerTitle: true,
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
                  color: isFavorite ? Colors.red : Colors.black,
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
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: _shareUnit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImageSection(hasImages),

            // Unit Info Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Name and Price
                  _buildUnitHeader(l10n),
                  SizedBox(height: 16),

                  // Stats Row (Area, Bedrooms, Bathrooms)
                  _buildStatsRow(l10n),
                  SizedBox(height: 24),

                  // Sale Section (if unit is on sale)
                  if (_unitSale != null) ...[
                    _buildSaleSection(_unitSale!, l10n),
                    SizedBox(height: 24),
                  ],

                  // Tab Navigation
                  _buildTabBar(l10n),
                  SizedBox(height: 16),

                  // Tab Content
                  _buildTabContent(l10n),
                  SizedBox(height: 24),

                  // Sales People Section
                  _buildSalesPeopleSection(l10n),

                  // Payment Plans
                  _buildPaymentPlans(l10n),
                  SizedBox(height: 24),

                  // Fill Form
                  _buildFillForm(l10n),
                  SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomButtons(l10n),
    );
  }

  Widget _buildImageSection(bool hasImages) {
    if (!hasImages) {
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: widget.unit.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return RobustNetworkImage(
                imageUrl: widget.unit.images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mainColor),
                  ),
                ),
                errorBuilder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          // Dot Indicators
          if (widget.unit.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.unit.images.length,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == index
                          ? AppColors.mainColor
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText24(
                widget.unit.unitNumber ?? 'Unit ${widget.unit.id}',
                bold: true,
                color: Colors.black,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText14(
                widget.unit.status.toUpperCase(),
                bold: true,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        if (widget.unit.companyName != null && widget.unit.companyName!.isNotEmpty)
          CustomText16(
            widget.unit.companyName!,
            color: AppColors.grey,
          ),
        SizedBox(height: 12),
        // Show sale price if available
        if (_unitSale != null) ...[
          Text(
            'EGP ${_formatPrice(widget.unit.price)}',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              CustomText32(
                'EGP ${_formatPrice(_unitSale!.newPrice.toString())}',
                bold: true,
                color: AppColors.mainColor,
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomText12(
                  '${_unitSale!.discountPercentage.toStringAsFixed(0)}% OFF',
                  bold: true,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ] else
          CustomText32(
            'EGP ${_formatPrice(widget.unit.price)}',
            bold: true,
            color: AppColors.mainColor,
          ),
        CustomText14(
          'EGP ${_calculatePricePerSqm()} ${l10n.perSqm}',
          color: AppColors.grey,
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            widget.unit.area != '0' ? widget.unit.area : '0',
            l10n.sqm,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            widget.unit.bedrooms != '0' ? widget.unit.bedrooms : '0',
            l10n.bedrooms,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            widget.unit.bathrooms != '0' ? widget.unit.bathrooms : '0',
            l10n.bathrooms,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        CustomText24(
          value,
          bold: true,
          color: Colors.black,
        ),
        SizedBox(height: 4),
        CustomText14(
          label,
          color: AppColors.grey,
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.mainColor,
        unselectedLabelColor: AppColors.grey,
        indicatorColor: AppColors.mainColor,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        isScrollable: true,
        tabs: [
          Tab(text: l10n.details),
          Tab(text: l10n.gallery),
          Tab(text: l10n.viewOnMap),
          Tab(text: l10n.floorPlan),
        ],
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n) {
    return Container(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(l10n),
          _buildGalleryTab(),
          _buildMapTab(l10n),
          _buildFloorPlanTab(l10n),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText18(
            '${l10n.about} ${widget.unit.unitType}',
            bold: true,
            color: Colors.black,
          ),
          SizedBox(height: 12),
          CustomText16(
            widget.unit.view ?? l10n.noDescriptionAvailable,
            color: AppColors.grey,
          ),
          SizedBox(height: 24),

          // Property Specifications
          _buildSpecRow(l10n.compound, widget.unit.compoundId ?? '0'),
          _buildSpecRow(l10n.saleType, 'Resale'),
          _buildSpecRow(l10n.finishing, widget.unit.finishing ?? '0'),
          _buildSpecRow(l10n.deliveryDate, widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty
            ? _formatDate(widget.unit.deliveryDate!) : '0'),
          _buildSpecRow(l10n.builtUpArea, '${widget.unit.area != '0' ? widget.unit.area : '0'} ${l10n.sqm}'),
          if (widget.unit.gardenArea != null && widget.unit.gardenArea!.isNotEmpty)
            _buildSpecRow(l10n.landArea, '${widget.unit.gardenArea != '0' ? widget.unit.gardenArea : '0'} ${l10n.sqm}'),
          _buildSpecRow(l10n.floor, widget.unit.floor != '0' ? widget.unit.floor : '0'),
          _buildSpecRow(l10n.numberOfBedrooms, widget.unit.bedrooms != '0' ? widget.unit.bedrooms : '0'),
          _buildSpecRow(l10n.numberOfBathrooms, widget.unit.bathrooms != '0' ? widget.unit.bathrooms : '0'),
          if (widget.unit.buildingName != null && widget.unit.buildingName!.isNotEmpty)
            _buildSpecRow(l10n.building, widget.unit.buildingName!),
          if (widget.unit.roofArea != null && widget.unit.roofArea!.isNotEmpty && widget.unit.roofArea != '0')
            _buildSpecRow(l10n.roofArea, '${widget.unit.roofArea} ${l10n.sqm}'),
          _buildSpecRow(l10n.price, 'EGP ${_formatPrice(widget.unit.price)}'),
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
          CustomText16(
            label,
            color: AppColors.grey,
          ),
          Expanded(
            child: CustomText16(
              value,
              bold: true,
              color: Colors.black,
              align: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (widget.unit.images.isEmpty) {
      return Center(
        child: CustomText16('No images available', color: AppColors.grey),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
          Icon(Icons.map, size: 60, color: AppColors.grey),
          SizedBox(height: 16),
          CustomText16(l10n.mapViewNotAvailable, color: AppColors.grey),
        ],
      ),
    );
  }

  Widget _buildFloorPlanTab(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 60, color: AppColors.grey),
          SizedBox(height: 16),
          CustomText16(l10n.floorPlanNotAvailable, color: AppColors.grey),
        ],
      ),
    );
  }

  // Sales People Section
  Widget _buildSaleSection(Sale sale, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF6B6B).withOpacity(0.15),
            Color(0xFFFFE66D).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                    Icon(Icons.local_offer, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    CustomText12(
                      'SALE',
                      bold: true,
                      color: Colors.white,
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
                child: CustomText12(
                  '${sale.discountPercentage.toStringAsFixed(0)}% OFF',
                  bold: true,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          CustomText20(
            sale.saleName,
            bold: true,
            color: Color(0xFF333333),
          ),
          SizedBox(height: 8),
          CustomText14(
            sale.description,
            color: Color(0xFF666666),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Old Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText12(
                      'Original Price',
                      color: Color(0xFF999999),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'EGP ${_formatPrice(sale.oldPrice.toString())}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF999999),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              // New Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText12(
                      'Sale Price',
                      color: AppColors.mainColor,
                    ),
                    SizedBox(height: 4),
                    CustomText20(
                      'EGP ${_formatPrice(sale.newPrice.toString())}',
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
              // Savings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText12(
                      'You Save',
                      color: Colors.green,
                    ),
                    SizedBox(height: 4),
                    CustomText18(
                      'EGP ${_formatPrice(sale.savings.toString())}',
                      bold: true,
                      color: Colors.green,
                    ),
                  ],
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
                  CustomText14(
                    '${sale.daysRemaining.toInt()} days remaining',
                    bold: true,
                    color: Colors.orange.shade800,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesPeopleSection(AppLocalizations l10n) {
    if (_isLoadingSalesPeople) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.mainColor),
        ),
      );
    }

    if (_salesPeople.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText20(
          'Contact Sales Team',
          bold: true,
          color: Colors.black,
        ),
        SizedBox(height: 12),
        CustomText16(
          'Get in touch with our professional sales team for more information',
          color: AppColors.grey,
        ),
        SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _salesPeople.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final salesPerson = _salesPeople[index];
            return _buildSalesPersonCard(salesPerson);
          },
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSalesPersonCard(CompanyUser salesPerson) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                salesPerson.name.isNotEmpty
                    ? salesPerson.name[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText16(
                  salesPerson.name,
                  bold: true,
                  color: Colors.black,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: AppColors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: CustomText14(
                        salesPerson.email,
                        color: AppColors.grey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (salesPerson.hasPhone) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: AppColors.grey),
                      SizedBox(width: 4),
                      CustomText14(
                        salesPerson.phone!,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Action Buttons
          if (salesPerson.hasPhone)
            Column(
              children: [
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse('tel:${salesPerson.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(Icons.phone, color: AppColors.mainColor),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(height: 8),
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/${salesPerson.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.chat, color: Colors.green),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlans(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText20(
          l10n.paymentPlans,
          bold: true,
          color: Colors.black,
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments, color: AppColors.mainColor),
                  SizedBox(width: 8),
                  CustomText18('Cash', bold: true, color: Colors.black),
                ],
              ),
              SizedBox(height: 8),
              CustomText24(
                'EGP ${_formatPrice(widget.unit.price)}',
                bold: true,
                color: AppColors.mainColor,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  CustomText14(
                    l10n.noMortgageAvailable,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFillForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText20(
            l10n.fillForm,
            bold: true,
            color: Colors.black,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.yourName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterYourName;
              }
              return null;
            },
          ),
          SizedBox(height: 12),
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterYourPhone;
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _requestInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: CustomText16(
                l10n.requestInfo,
                bold: true,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _callNow,
                icon: Icon(Icons.phone, color: Colors.white),
                label: CustomText16(l10n.callNow, bold: true, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: Icon(Icons.chat, color: Colors.white),
                label: CustomText16('WhatsApp', bold: true, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
