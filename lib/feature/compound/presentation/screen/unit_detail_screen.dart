import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/unit_model.dart';
import '../../data/web_services/compound_web_services.dart';
import '../../data/web_services/unit_web_services.dart';
import '../../../sale/data/models/sale_model.dart';
import '../../../sale/data/services/sale_web_services.dart';
import '../../../sale/presentation/widgets/sales_person_selector.dart';
import '../../../share/presentation/widgets/advanced_share_bottom_sheet.dart';
import '../../../company/data/web_services/company_web_services.dart';
import '../../../company/data/models/company_user_model.dart';
import '../bloc/favorite/unit_favorite_bloc.dart';
import '../bloc/favorite/unit_favorite_state.dart';
import '../bloc/favorite/unit_favorite_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../search/data/services/view_history_service.dart';
import '../../../../core/widgets/sale_card.dart';
import '../../../../core/widgets/note_dialog.dart';
import '../../data/web_services/favorites_web_services.dart';
import '../../../../core/widgets/zoomable_image_viewer.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import '../../../ai_chat/data/models/comparison_item.dart';
import '../../../ai_chat/data/services/comparison_list_service.dart';
import '../../../ai_chat/presentation/screen/unified_ai_chat_screen.dart';

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
  final UnitWebServices _unitWebServices = UnitWebServices();
  final FavoritesWebServices _favoritesWebServices = FavoritesWebServices();
  late TabController _tabController;
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
  Sale? _unitSale;
  bool _isLoadingSale = false;
  List<Map<String, dynamic>> _notes = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Unit? _currentUnit; // To hold refreshed unit data if needed

  @override
  void initState() {
    super.initState();
    // Track view history
    ViewHistoryService().addViewedUnit(widget.unit);
    _imagePageController = PageController();
    _tabController = TabController(length: 6, vsync: this);
    _currentUnit = widget.unit; // Initialize with passed unit

    print('[UNIT DETAIL] ========================================');
    print('[UNIT DETAIL] Unit ID: ${widget.unit.id}');
    print('[UNIT DETAIL] Note ID: ${widget.unit.noteId}');
    print('[UNIT DETAIL] Has active sale: ${widget.unit.hasActiveSale}');
    // PaymentPlans feature not yet implemented in Unit model
    // print('[UNIT DETAIL] Payment plans: ${widget.unit.paymentPlans?.length ?? 0}');
    print('[UNIT DETAIL] ========================================');

    // Always fetch full unit data from API to get payment plans and complete data
    // The list API doesn't include payment_plans, so we need to fetch by ID
    print('[UNIT DETAIL] Fetching full unit details from API...');
    _refetchUnitData();

    _startAutoSlide();
    _fetchSalesPeople();
    _fetchUnitNote();
  }

  Future<void> _refetchUnitData() async {
    try {
      print('[UNIT DETAIL] Fetching complete unit data from API...');
      final unitData = await _unitWebServices.getUnitById(widget.unit.id);
      print('[UNIT DETAIL] Payment plans in response: ${unitData['payment_plans']}');

      // Merge original unit data with fetched data to preserve fields that might be missing
      // The search API returns different fields than the unit detail API
      final mergedData = Map<String, dynamic>.from(unitData);

      // Preserve original data if API response is missing these critical fields
      if ((mergedData['total_area'] == null || mergedData['total_area'].toString() == '0') &&
          widget.unit.area.isNotEmpty && widget.unit.area != '0') {
        mergedData['total_area'] = widget.unit.area;
        print('[UNIT DETAIL] Preserving original area: ${widget.unit.area}');
      }
      if ((mergedData['delivered_at'] == null || mergedData['delivered_at'].toString().isEmpty) &&
          widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty) {
        mergedData['delivered_at'] = widget.unit.deliveryDate;
        print('[UNIT DETAIL] Preserving original delivery date: ${widget.unit.deliveryDate}');
      }
      if ((mergedData['finishing_type'] == null || mergedData['finishing_type'].toString().isEmpty) &&
          widget.unit.finishing != null && widget.unit.finishing!.isNotEmpty) {
        mergedData['finishing_type'] = widget.unit.finishing;
        print('[UNIT DETAIL] Preserving original finishing: ${widget.unit.finishing}');
      }
      if ((mergedData['number_of_beds'] == null || mergedData['number_of_beds'].toString() == '0') &&
          widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0') {
        mergedData['number_of_beds'] = widget.unit.bedrooms;
        print('[UNIT DETAIL] Preserving original bedrooms: ${widget.unit.bedrooms}');
      }
      if ((mergedData['number_of_bathrooms'] == null || mergedData['number_of_bathrooms'].toString() == '0') &&
          widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0') {
        mergedData['number_of_bathrooms'] = widget.unit.bathrooms;
        print('[UNIT DETAIL] Preserving original bathrooms: ${widget.unit.bathrooms}');
      }
      // Preserve compound location data
      if (mergedData['compound'] == null && widget.unit.compoundLocation != null) {
        mergedData['compound_location'] = widget.unit.compoundLocation;
        mergedData['compound_location_en'] = widget.unit.compoundLocationEn;
        mergedData['compound_location_ar'] = widget.unit.compoundLocationAr;
        print('[UNIT DETAIL] Preserving original compound location');
      }

      final refreshedUnit = Unit.fromJson(mergedData);

      setState(() {
        _currentUnit = refreshedUnit;
      });

      print('[UNIT DETAIL] ✓ Unit data refreshed');
      // PaymentPlans feature not yet implemented in Unit model
      // print('[UNIT DETAIL] Refreshed payment plans count: ${refreshedUnit.paymentPlans?.length ?? 0}');

      _setupSale();
    } catch (e) {
      print('[UNIT DETAIL] ✗ Error refetching unit data: $e');
      // Fall back to using original unit data
      _setupSale();
    }
  }

  void _setupSale() {
    // Check if sale is included in unit data first
    if (_currentUnit!.sale != null) {
      print('[UNIT DETAIL] Sale found in unit data: ${_currentUnit!.sale!.saleName}');
      _unitSale = _currentUnit!.sale;
    } else {
      // If not included, fetch separately from API
      print('[UNIT DETAIL] No sale in unit data, fetching from API...');
      _fetchUnitSale();
    }
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
    final unit = _currentUnit ?? widget.unit;
    // Only start auto-slide if there are multiple images
    if (unit.images.length > 1) {
      _autoSlideTimer = Timer.periodic(Duration(seconds: 4), (timer) {
        if (mounted) {
          final currentUnit = _currentUnit ?? widget.unit;
          final nextIndex = (_currentImageIndex + 1) % currentUnit.images.length;
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

  /// Format area value - rounds to nearest integer or 1 decimal place
  String _formatArea(String? areaStr) {
    if (areaStr == null || areaStr.isEmpty) return '-';
    try {
      final area = double.parse(areaStr);
      // If it's a whole number, show without decimals
      if (area == area.roundToDouble()) {
        return area.toInt().toString();
      }
      // Otherwise show with 1 decimal place
      return area.toStringAsFixed(1);
    } catch (e) {
      return areaStr;
    }
  }

  String _calculatePricePerSqm() {
    final unit = _currentUnit ?? widget.unit;
    try {
      final numPrice = double.parse(unit.price);
      final numArea = double.parse(unit.area);
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
    final unit = _currentUnit ?? widget.unit;
    final statusLower = unit.status.toLowerCase();
    // Handle both English and Arabic status values
    if (statusLower == 'available' || statusLower == 'متاح') {
      return Colors.green;
    } else if (statusLower == 'reserved' || statusLower == 'محجوز') {
      return Colors.orange;
    } else if (statusLower == 'sold' || statusLower == 'مباع') {
      return Colors.red;
    } else if (statusLower == 'in_progress' || statusLower == 'قيد الإنشاء') {
      return Colors.orange; // Changed from blue to orange for in_progress
    } else if (statusLower == 'completed' || statusLower == 'مكتمل') {
      return Colors.green;
    } else if (statusLower == 'delivered' || statusLower == 'تم التسليم') {
      return Colors.blue;
    }
    return Colors.grey;
  }

  Future<void> _fetchSalesPeople() async {
    final unit = _currentUnit ?? widget.unit;
    // Check if unit has companyId
    if (unit.companyId == null || unit.companyId!.isEmpty) {
      print('[UNIT DETAIL] No companyId available for this unit');
      return;
    }

    if (_isLoadingSalesPeople) return;

    setState(() {
      _isLoadingSalesPeople = true;
    });

    try {
      final companyData = await _companyWebServices.getCompanyById(unit.companyId!);

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
    if (_isLoadingSale || _currentUnit == null) return;

    setState(() => _isLoadingSale = true);

    try {
      final response = await _saleWebServices.getSalesByUnit(_currentUnit!.id);

      print('[UNIT DETAIL] Sale response for unit ${_currentUnit!.id}: $response');

      if (response['success'] == true && response['sales'] != null) {
        final salesList = response['sales'] as List;
        print('[UNIT DETAIL] Processing ${salesList.length} sales from API');

        final sales = salesList.map((saleData) {
          final saleJson = Map<String, dynamic>.from(saleData as Map<String, dynamic>);

          // If sale doesn't have old_price/new_price, calculate from unit data
          if ((saleJson['old_price'] == null || saleJson['old_price'] == 0) &&
              (saleJson['new_price'] == null || saleJson['new_price'] == 0)) {

            print('[UNIT DETAIL] Sale missing prices, calculating from unit data...');
            print('[UNIT DETAIL] Unit originalPrice: ${_currentUnit!.originalPrice}');
            print('[UNIT DETAIL] Unit normalPrice: ${_currentUnit!.normalPrice}');
            print('[UNIT DETAIL] Unit price: ${_currentUnit!.price}');

            double unitPrice = 0.0;

            // Priority: original_price > normal_price > price
            if (_currentUnit!.originalPrice != null && _currentUnit!.originalPrice!.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.originalPrice!) ?? 0.0;
              print('[UNIT DETAIL] Using originalPrice: $unitPrice');
            } else if (_currentUnit!.normalPrice != null && _currentUnit!.normalPrice!.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.normalPrice!) ?? 0.0;
              print('[UNIT DETAIL] Using normalPrice: $unitPrice');
            } else if (_currentUnit!.price.isNotEmpty) {
              unitPrice = double.tryParse(_currentUnit!.price) ?? 0.0;
              print('[UNIT DETAIL] Using price: $unitPrice');
            }

            final discountPercent = saleJson['discount_percentage'] is num
                ? (saleJson['discount_percentage'] as num).toDouble()
                : double.tryParse(saleJson['discount_percentage']?.toString() ?? '0') ?? 0.0;

            print('[UNIT DETAIL] Discount percentage: $discountPercent');

            if (unitPrice > 0 && discountPercent > 0) {
              saleJson['old_price'] = unitPrice;
              saleJson['new_price'] = unitPrice * (1 - (discountPercent / 100));
              saleJson['savings'] = unitPrice * (discountPercent / 100);
              print('[UNIT DETAIL] ✓ Calculated prices - Old: ${saleJson['old_price']}, New: ${saleJson['new_price']}, Savings: ${saleJson['savings']}');
            } else {
              print('[UNIT DETAIL] ✗ Cannot calculate - unitPrice: $unitPrice, discount: $discountPercent');
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

        print('[UNIT DETAIL] Found ${activeSales.length} matching sales for this unit');
        if (activeSales.isNotEmpty) {
          print('[UNIT DETAIL] First sale: ${activeSales.first.saleName} - Type: ${activeSales.first.saleType}');
          print('[UNIT DETAIL] Sale prices - Old: ${activeSales.first.oldPrice}, New: ${activeSales.first.newPrice}, Savings: ${activeSales.first.savings}');
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
      print('[UNIT DETAIL] Error fetching unit sale: $e');
      if (mounted) {
        setState(() => _isLoadingSale = false);
      }
    }
  }

  Future<void> _fetchUnitNote() async {
    try {
      print('[UNIT DETAIL] Fetching notes for unit ${widget.unit.id}');
      final response = await _favoritesWebServices.getNotes(
        unitId: int.parse(widget.unit.id),
      );

      print('[UNIT DETAIL] getNotes response: $response');

      // New API structure: response['data']['notes']
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['notes'] != null) {
          final notes = data['notes'] as List;
          print('[UNIT DETAIL] Found ${notes.length} notes');
          if (mounted) {
            setState(() {
              _notes = notes.map((note) {
                return {
                  'id': note['id'],
                  'content': note['content'],
                  'title': note['title'] ?? 'Note',
                  'created_at': note['created_at'],
                  'updated_at': note['updated_at'],
                };
              }).toList();
            });
          }
          print('[UNIT DETAIL] Loaded ${_notes.length} notes');
        } else {
          print('[UNIT DETAIL] Notes field is null');
        }
      } else {
        print('[UNIT DETAIL] No notes in response or success=false');
      }
    } catch (e) {
      print('[UNIT DETAIL] Error fetching unit notes: $e');
      print('[UNIT DETAIL] Error stack: ${StackTrace.current}');
    }
  }

  Future<void> _showSalespeople() async {
    final unit = _currentUnit ?? widget.unit;
    try {
      // Use compound ID as the search parameter since we don't have compound name in Unit model
      final response = await _compoundWebServices.getSalespeopleByCompound(unit.compoundId);

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
          _showCenteredMessage(
            context: context,
            message: AppLocalizations.of(context)!.noSalesPersonAvailable,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showCenteredMessage(
          context: context,
          message: '${AppLocalizations.of(context)!.error}: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _shareUnit() {
    final unit = _currentUnit ?? widget.unit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedShareBottomSheet(
        type: 'unit',
        id: unit.id,
      ),
    );
  }

  void _callNow() async {
    final unit = _currentUnit ?? widget.unit;
    final phone = unit.salesNumber ?? '';
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
    final unit = _currentUnit ?? widget.unit;
    final phone = unit.salesNumber ?? '';
    if (phone.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _showSalespeople();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = _currentUnit ?? widget.unit;
    final hasImages = unit.images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.greyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText18(
          l10n.unitDetails,
          bold: true,
          color: AppColors.greyText,
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
            builder: (context, state) {
              bool isFavorite = false;
              if (state is UnitFavoriteUpdated) {
                isFavorite = state.favorites.any((u) => u.id == unit.id);
              }
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                ),
                onPressed: () {
                  if (isFavorite) {
                    context.read<UnitFavoriteBloc>().add(
                      RemoveFavoriteUnit(unit),
                    );
                  } else {
                    context.read<UnitFavoriteBloc>().add(
                      AddFavoriteUnit(unit),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.compare_arrows, color: AppColors.greyText),
            onPressed: _showCompareDialog,
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppColors.greyText),
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

                  // Unit Change Notes (if unit has updates)
                  UnitChangeNotes(unit: widget.unit),

                  // Sale Section (if unit is on sale)
                  if (_unitSale != null) ...[
                    _buildSaleSection(_unitSale!, l10n),
                    SizedBox(height: 24),
                  ],
                  SizedBox(height: 24),

                  // Sales People Section
                  _buildSalesPeopleSection(l10n),
                  // Tab Navigation
                  _buildTabBar(l10n),
                  SizedBox(height: 16),

                  // Tab Content
                  _buildTabContent(l10n),

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

    final unit = _currentUnit ?? widget.unit;

    return Column(
      children: [
        Container(
          height: 250,
          child: GestureDetector(
            onTap: () {
              // Open zoomable image viewer
              ZoomableImageViewer.show(
                context,
                images: unit.images,
                initialIndex: _currentImageIndex,
              );
            },
            child: PageView.builder(
              controller: _imagePageController,
              itemCount: unit.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return RobustNetworkImage(
                  imageUrl: unit.images[index],
                  fit: BoxFit.cover,
                loadingBuilder: (context) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CustomLoadingDots(size: 80),
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
          ),
        ),
        // Dot Indicators - Now under the image
        if (unit.images.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                unit.images.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentImageIndex == index
                        ? AppColors.mainColor
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnitHeader(AppLocalizations l10n) {
    // Use refreshed unit data from API if available, fallback to widget.unit
    final unit = _currentUnit ?? widget.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText24(
                unit.unitNumber?.isNotEmpty == true
                    ? unit.unitNumber!
                    : (unit.code?.isNotEmpty == true ? unit.code! : 'Unit ${unit.id}'),
                bold: true,
                color: AppColors.greyText,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText14(
                unit.status.toUpperCase(),
                bold: true,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        // Show compound name
        if (unit.compoundName != null && unit.compoundName!.isNotEmpty)
          CustomText16(
            unit.compoundName!,
            color: AppColors.greyText,
          ),
        // Show company name
        if (unit.companyName != null && unit.companyName!.isNotEmpty)
          CustomText14(
            unit.companyName!,
            color: AppColors.greyText,
          ),
        SizedBox(height: 12),
        // Show sale price if available
        if (_unitSale != null) ...[
          Text(
            'EGP ${_formatPrice(_unitSale!.oldPrice.toString())}',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.greyText,
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
                  color: AppColors.mainColor,
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
        ] else ...[
          // Check if price is 0 or empty
          if (unit.price != '0' && unit.price.isNotEmpty)
            CustomText32(
              'EGP ${_formatPrice(unit.price)}',
              bold: true,
              color: AppColors.mainColor,
            )
          else
            CustomText24(
              l10n.contactForPrice,
              bold: true,
              color: AppColors.mainColor,
            ),
        ],
        // Only show price per sqm if both price and area are not 0
        if (unit.price != '0' &&
            unit.area != '0' &&
            unit.price.isNotEmpty && unit.area.isNotEmpty)
          CustomText14(
            'EGP ${_calculatePricePerSqm()} ${l10n.perSqm}',
            color: AppColors.greyText,
          ),
      ],
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    // Use refreshed unit data from API if available, fallback to widget.unit
    final unit = _currentUnit ?? widget.unit;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            unit.area != '0' && unit.area.isNotEmpty
                ? _formatArea(unit.area) : '-',
            l10n.sqm,
          ),
          Container(width: 1, height: 30, color: AppColors.mainColor.withOpacity(0.3)),
          _buildStatItem(
            unit.bedrooms != '0' && unit.bedrooms.isNotEmpty
                ? unit.bedrooms : '-',
            l10n.bedrooms,
            icon: Icons.bed_outlined,
          ),
          Container(width: 1, height: 30, color: AppColors.mainColor.withOpacity(0.3)),
          _buildStatItem(
            unit.bathrooms != '0' && unit.bathrooms.isNotEmpty
                ? unit.bathrooms : '-',
            l10n.bathrooms,
            icon: Icons.bathtub_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {IconData? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.greyText, size: 24),
          SizedBox(height: 4),
        ],
        CustomText24(
          value,
          bold: true,
          color: AppColors.greyText,
        ),
        SizedBox(height: 4),
        CustomText14(
          label,
          color: AppColors.greyText,
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      height: 50,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.mainColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(icon: Icon(Icons.info_outline, size: 18), text: l10n.details),
          Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: l10n.gallery),
          Tab(icon: Icon(Icons.note_outlined, size: 18), text: l10n.notes),
          Tab(icon: Icon(Icons.payment, size: 18), text: l10n.paymentPlans),
          Tab(icon: Icon(Icons.map_outlined, size: 18), text: l10n.viewOnMap),
          Tab(icon: Icon(Icons.architecture_outlined, size: 18), text: l10n.floorPlan),
        ],
      ),
    );
  }


  Widget _buildTabContent(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(l10n),
              _buildGalleryTab(),
              _buildNotesTab(),
              _buildPaymentPlansTab(l10n),
              _buildMapTab(l10n),
              _buildFloorPlanTab(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(AppLocalizations l10n) {
    // Use refreshed unit data from API if available, fallback to widget.unit
    final unit = _currentUnit ?? widget.unit;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Specifications - Show all fields even if null
          _buildSpecRow(l10n.unitCode, unit.code ?? unit.unitNumber ?? 'N/A'),
          _buildSpecRow(l10n.unitType, unit.unitType ?? 'N/A'),
          _buildSpecRow(l10n.usageType, unit.usageType ?? 'N/A'),
          _buildSpecRow(l10n.compound, unit.compoundName ?? unit.compoundId ?? 'N/A'),
          _buildSpecRow(l10n.status, unit.status ?? 'N/A'),
          _buildSpecRow(l10n.available, unit.available != null ? (unit.available! ? l10n.yes : l10n.no) : 'N/A'),
          // Update Notes - Show if unit was recently updated
          if (unit.notes != null && unit.notes!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFFECAA), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.update, color: Color(0xFFFF9800), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.recentUpdate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          unit.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildSpecRow(l10n.saleType, l10n.resale),
          _buildSpecRow(l10n.finishing, unit.finishing ?? 'N/A'),
          _buildSpecRow(l10n.deliveryDate, unit.deliveryDate != null && unit.deliveryDate!.isNotEmpty
            ? _formatDate(unit.deliveryDate!) : 'N/A'),
          _buildSpecRow(l10n.builtUpArea, unit.builtUpArea != null
            ? '${_formatArea(unit.builtUpArea)} ${l10n.sqm}'
            : (unit.area != '0' ? '${_formatArea(unit.area)} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow(l10n.totalArea, unit.area != '0' ? '${_formatArea(unit.area)} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.landArea, unit.landArea != null
            ? '${_formatArea(unit.landArea)} ${l10n.sqm}'
            : (unit.gardenArea != null && unit.gardenArea != '0' ? '${_formatArea(unit.gardenArea)} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow(l10n.gardenArea, unit.gardenArea != null && unit.gardenArea != '0' ? '${_formatArea(unit.gardenArea)} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.roofArea, unit.roofArea != null && unit.roofArea != '0' ? '${_formatArea(unit.roofArea)} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.floor, unit.floor != '0' ? unit.floor : 'N/A'),
          _buildSpecRow(l10n.building, unit.buildingName ?? 'N/A'),
          _buildSpecRow(l10n.company, unit.companyName ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label - takes up to 40% of width
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ),
          // Spacing - minimum 16px gap
          SizedBox(width: 16),
          // Value - takes up to 60% of width
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.greyText,
              ),
              textAlign: isRtl ? TextAlign.left : TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    final l10n = AppLocalizations.of(context)!;
    final unit = _currentUnit ?? widget.unit;

    if (unit.images.isEmpty) {
      return Center(
        child: CustomText16(l10n.noImagesAvailable, color: AppColors.grey),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: unit.images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Open zoomable image viewer
            ZoomableImageViewer.show(
              context,
              images: unit.images,
              initialIndex: index,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RobustNetworkImage(
              imageUrl: unit.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTab(AppLocalizations l10n) {
    final unit = _currentUnit ?? widget.unit;
    final compoundLocation = unit.compoundLocation ?? '';
    final actualLocation = compoundLocation.isNotEmpty ? compoundLocation : (l10n.locationNotAvailable ?? 'Location not available');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Location Icon
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 64,
                color: AppColors.mainColor,
              ),
            ),

            SizedBox(height: 24),

            // Location Text
            Text(
              actualLocation,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32),

            // Open Location Button
            if (unit.compoundLocationUrl != null && unit.compoundLocationUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(unit.compoundLocationUrl!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.map, color: Colors.white, size: 24),
                  label: Text(
                    l10n.openLocationInMaps ?? 'Open Location in Maps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                    SizedBox(height: 12),
                    Text(
                      l10n.mapViewNotAvailable ?? 'Location not available',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.greyText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
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
          Icon(Icons.architecture, size: 60, color: AppColors.grey),
          SizedBox(height: 16),
          CustomText16(l10n.floorPlanNotAvailable, color: AppColors.grey),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _notes.isNotEmpty ? Icons.note : Icons.note_add_outlined,
                    color: AppColors.mainColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${l10n.myNotes} (${_notes.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: Icon(Icons.add, size: 16),
                label: Text(l10n.addNote),

                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mainColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_notes.isEmpty) ...[
            Text(
              l10n.addYourPersonalNotes,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.greyText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _notes.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note['title'] ?? l10n.note,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 18),
                                color: Colors.blue,
                                onPressed: () => _showNoteDialog(
                                  noteId: note['id'],
                                  initialContent: note['content'],
                                  initialTitle: note['title'],
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, size: 18),
                                color: Colors.red,
                                onPressed: () => _deleteNote(note['id']),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        note['content'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${l10n.updated}: ${_formatNoteDate(note['updated_at'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.greyText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatNoteDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildPaymentPlansTab(AppLocalizations l10n) {
    // PaymentPlans feature not yet implemented in Unit model
    // final paymentPlans = _currentUnit?.paymentPlans;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 22, color: AppColors.mainColor),
              SizedBox(width: 10),
              CustomText20(
                l10n.paymentPlans,
                bold: true,
                color: AppColors.greyText,
              ),
            ],
          ),
          SizedBox(height: 16),

          // PaymentPlans feature not yet implemented - showing cash option
          // Fallback: Show basic cash option if no payment plans from API
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
                      CustomText18(l10n.cash, bold: true, color: AppColors.greyText),
                    ],
                  ),
                  SizedBox(height: 8),
                  CustomText24(
                    'EGP ${_formatPrice(_currentUnit?.price ?? widget.unit.price)}',
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
      ),
    );
  }

  // PaymentPlan feature not yet implemented - _buildPaymentPlanCard method removed
  // Widget _buildPaymentPlanCard(PaymentPlan plan, AppLocalizations l10n) { ... }

  Widget _buildPaymentInfoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.greyText),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.greyText),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.greyText,
          ),
        ),
      ],
    );
  }
  // Sales People Section
  Widget _buildSaleSection(Sale sale, AppLocalizations l10n) {
    return SaleCard(sale: sale);
  }

  Widget _buildSalesPeopleSection(AppLocalizations l10n) {
    if (_isLoadingSalesPeople) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CustomLoadingDots(size: 60),
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
          l10n.contactSales,
          bold: true,
          color: AppColors.greyText,
        ),
        SizedBox(height: 12),
        CustomText16(
          l10n.contactSales,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText16(
                  salesPerson.name,
                  bold: true,
                  color: AppColors.greyText,
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

  Widget _buildBottomButtons(AppLocalizations l10n) {
    final unit = _currentUnit ?? widget.unit;
    final hasPhone = unit.salesNumber != null && unit.salesNumber!.isNotEmpty;
    final hasSalesPeople = _salesPeople.isNotEmpty;

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
          // Show Call/WhatsApp buttons only if phone number is available
          if (hasPhone) ...[
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
          ] else if (hasSalesPeople) ...[
            // Show "Contact Sales" button if salespeople are available
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _showSalespeople,
                  icon: Icon(Icons.support_agent, color: Colors.white),
                  label: CustomText16(l10n.contactSales, bold: true, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Show share button as fallback when no contact info is available
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _shareUnit,
                  icon: Icon(Icons.share, color: Colors.white),
                  label: CustomText16(l10n.share, bold: true, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Notes Section
  Future<void> _showNoteDialog({
    int? noteId,
    String? initialContent,
    String? initialTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await NoteDialog.show(
      context,
      initialNote: initialContent,
      title: noteId != null ? l10n.editNote : l10n.addNote,
    );

    if (result != null && mounted) {
      try {
        Map<String, dynamic> response;

        if (noteId != null) {
          // Update existing note
          print('[UNIT DETAIL] Updating note $noteId');
          response = await _favoritesWebServices.updateNote(
            noteId: noteId,
            content: result,
            title: initialTitle ?? 'Unit Note',
          );
        } else {
          // Create new note
          print('[UNIT DETAIL] Creating new note for unit ${widget.unit.id}');
          response = await _favoritesWebServices.createNote(
            content: result,
            title: 'Unit Note',
            unitId: int.tryParse(widget.unit.id),
          );
        }

        print('[UNIT DETAIL] Note save response: $response');

        if (mounted) {
          _showCenteredMessage(
            context: context,
            message: l10n.noteSavedSuccessfully,
            isSuccess: true,
          );

          // Reload notes to show updated list
          await _fetchUnitNote();
        }

        // Trigger bloc refresh to reload favorites with updated noteId
        if (mounted) {
          context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
        }
      } catch (e) {
        print('Error saving note: $e');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showCenteredMessage(
            context: context,
            message: l10n.failedToSaveNote,
            isSuccess: false,
          );
        }
      }
    }
  }

  Future<void> _deleteNote(int noteId) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.areYouSureDeleteNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        print('[UNIT DETAIL] Deleting note $noteId');
        final response = await _favoritesWebServices.deleteNote(noteId);

        print('[UNIT DETAIL] Delete note response: $response');

        if (mounted) {
          _showCenteredMessage(
            context: context,
            message: l10n.noteDeletedSuccessfully,
            isSuccess: true,
          );

          // Reload notes to show updated list
          await _fetchUnitNote();
        }

        // Trigger bloc refresh
        if (mounted) {
          context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
        }
      } catch (e) {
        print('Error deleting note: $e');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showCenteredMessage(
            context: context,
            message: l10n.failedToDeleteNote,
            isSuccess: false,
          );
        }
      }
    }
  }

  void _showCompareDialog() {
    final comparisonItem = ComparisonItem.fromUnit(widget.unit);
    final comparisonService = ComparisonListService();
    final l10n = AppLocalizations.of(context)!;

    // Add to comparison list
    final added = comparisonService.addItem(comparisonItem);

    if (added) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.addedToComparison,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: l10n.undo,
            textColor: Colors.white,
            onPressed: () {
              comparisonService.removeItem(comparisonItem);
            },
          ),
        ),
      );
    } else {
      // Show error (already in list or list is full)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  comparisonService.isFull
                      ? l10n.comparisonListFull
                      : l10n.alreadyInComparison,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCenteredMessage({
    required BuildContext context,
    required String message,
    required bool isSuccess,
  })
  {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

// Unit Change Notes Widget
class UnitChangeNotes extends StatelessWidget {
  final Unit unit;

  const UnitChangeNotes({Key? key, required this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[UNIT CHANGE NOTES MOBILE] ========================================');
    print('[UNIT CHANGE NOTES MOBILE] Unit ID: ${unit.id}');
    print('[UNIT CHANGE NOTES MOBILE] isUpdated: ${unit.isUpdated}');
    print('[UNIT CHANGE NOTES MOBILE] changeType: ${unit.changeType}');
    print('[UNIT CHANGE NOTES MOBILE] changeProperties: ${unit.changeProperties}');
    print('[UNIT CHANGE NOTES MOBILE] lastChangedAt: ${unit.lastChangedAt}');
    print('[UNIT CHANGE NOTES MOBILE] ========================================');

    if (unit.isUpdated != true) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 18),
              SizedBox(width: 6),
              Text(
                'Recent Changes', // Note: Needs context for localization
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Change type
          if (unit.changeType != null)
            _buildInfoRow(
              AppLocalizations.of(context)!.status,
              unit.changeType!.toUpperCase(),
              _getChangeColor(unit.changeType!),
            ),

          // Last changed date
          if (unit.lastChangedAt != null)
            _buildInfoRow(
              AppLocalizations.of(context)!.updated,
              _formatDate(unit.lastChangedAt!),
              Colors.grey.shade800,
            ),

          // Changed fields with values (from changeProperties)
          if (unit.changeProperties != null) ...[
            SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.whatChanged}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6),
            _buildChangesTable(unit.changeProperties!),
          ] else if (unit.changedFields != null && unit.changedFields!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Changed Fields:', // Note: Needs context for localization
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
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
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
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

  Widget _buildChangesTable(Map<String, dynamic> properties) {
    final changes = properties['changes'] as Map<String, dynamic>?;
    final original = properties['original'] as Map<String, dynamic>?;

    if (changes == null || changes.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: changes.entries.map((entry) {
          final fieldName = entry.key;
          final newValue = entry.value?.toString() ?? 'N/A';
          final oldValue = original?[fieldName]?.toString() ?? 'N/A';

          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade100, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field name
                Text(
                  _formatFieldName(fieldName),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 6),
                // Original value
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Old: $oldValue', // Note: Needs context for localization
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade900,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                // Arrow icon
                Center(
                  child: Icon(Icons.arrow_downward, size: 12, color: Colors.orange),
                ),
                SizedBox(height: 4),
                // New value
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'New: $newValue', // Note: Needs context for localization
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
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
