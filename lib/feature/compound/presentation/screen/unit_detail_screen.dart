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
    print('[UNIT DETAIL] Unit originalPrice: ${widget.unit.originalPrice}');
    print('[UNIT DETAIL] Unit normalPrice: ${widget.unit.normalPrice}');
    print('[UNIT DETAIL] Unit price: ${widget.unit.price}');

    // Check if unit has sale but missing price data
    bool hasSale = widget.unit.hasActiveSale == true || widget.unit.sale != null;
    bool missingPriceData = (widget.unit.originalPrice == null || widget.unit.originalPrice!.isEmpty) &&
                             (widget.unit.normalPrice == null || widget.unit.normalPrice!.isEmpty) &&
                             (widget.unit.price.isEmpty || widget.unit.price == '0');

    print('[UNIT DETAIL] Has sale: $hasSale');
    print('[UNIT DETAIL] Missing price data: $missingPriceData');

    if (hasSale && missingPriceData) {
      print('[UNIT DETAIL] Unit has sale but missing price data - refetching from API...');
      _refetchUnitData();
    } else {
      print('[UNIT DETAIL] Unit data complete - proceeding normally');
      _setupSale();
    }
    print('[UNIT DETAIL] ========================================');

    _startAutoSlide();
    _fetchSalesPeople();
    _fetchUnitNote();
  }

  Future<void> _refetchUnitData() async {
    try {
      print('[UNIT DETAIL] Fetching complete unit data from API...');
      final unitData = await _unitWebServices.getUnitById(widget.unit.id);
      final refreshedUnit = Unit.fromJson(unitData);

      setState(() {
        _currentUnit = refreshedUnit;
      });

      print('[UNIT DETAIL] ✓ Unit data refreshed');
      print('[UNIT DETAIL] Refreshed originalPrice: ${refreshedUnit.originalPrice}');
      print('[UNIT DETAIL] Refreshed normalPrice: ${refreshedUnit.normalPrice}');
      print('[UNIT DETAIL] Refreshed price: ${refreshedUnit.price}');

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedShareBottomSheet(
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

    return Column(
      children: [
        Container(
          height: 250,
          child: GestureDetector(
            onTap: () {
              // Open zoomable image viewer
              ZoomableImageViewer.show(
                context,
                images: widget.unit.images,
                initialIndex: _currentImageIndex,
              );
            },
            child: PageView.builder(
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
          ),
        ),
        // Dot Indicators - Now under the image
        if (widget.unit.images.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
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
            color: Colors.grey.shade600,
          ),
        SizedBox(height: 12),
        // Show sale price if available
        if (_unitSale != null) ...[
          Text(
            'EGP ${_formatPrice(_unitSale!.oldPrice.toString())}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
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
          if (widget.unit.price != null && widget.unit.price != '0' && widget.unit.price.isNotEmpty)
            CustomText32(
              'EGP ${_formatPrice(widget.unit.price)}',
              bold: true,
              color: AppColors.mainColor,
            )
          else
            CustomText24(
              'Contact for Price',
              bold: true,
              color: AppColors.mainColor,
            ),
        ],
        // Only show price per sqm if both price and area are not 0
        if (widget.unit.price != null && widget.unit.price != '0' &&
            widget.unit.area != null && widget.unit.area != '0' &&
            widget.unit.price.isNotEmpty && widget.unit.area.isNotEmpty)
          CustomText14(
            'EGP ${_calculatePricePerSqm()} ${l10n.perSqm}',
            color: Colors.grey.shade700,
          ),
      ],
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
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
            widget.unit.area != null && widget.unit.area != '0' && widget.unit.area.isNotEmpty
                ? widget.unit.area : '-',
            l10n.sqm,
          ),
          Container(width: 1, height: 30, color: AppColors.mainColor.withOpacity(0.3)),
          _buildStatItem(
            widget.unit.bedrooms != null && widget.unit.bedrooms != '0' && widget.unit.bedrooms.isNotEmpty
                ? widget.unit.bedrooms : '-',
            l10n.bedrooms,
            icon: Icons.bed_outlined,
          ),
          Container(width: 1, height: 30, color: AppColors.mainColor.withOpacity(0.3)),
          _buildStatItem(
            widget.unit.bathrooms != null && widget.unit.bathrooms != '0' && widget.unit.bathrooms.isNotEmpty
                ? widget.unit.bathrooms : '-',
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
          Icon(icon, color: Colors.grey.shade600, size: 24),
          SizedBox(height: 4),
        ],
        CustomText24(
          value,
          bold: true,
          color: Colors.black87,
        ),
        SizedBox(height: 4),
        CustomText14(
          label,
          color: Colors.black87,
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: AppColors.mainColor,
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
        Tab(text: 'Notes'),
        Tab(text: l10n.paymentPlans),
        Tab(text: l10n.viewOnMap),
        Tab(text: l10n.floorPlan),
      ],
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Specifications - Show all fields even if null
          _buildSpecRow('Unit Code', widget.unit.code ?? widget.unit.unitNumber ?? 'N/A'),
          _buildSpecRow('Unit Type', widget.unit.unitType ?? 'N/A'),
          _buildSpecRow('Usage Type', widget.unit.usageType ?? 'N/A'),
          _buildSpecRow(l10n.compound, widget.unit.compoundName ?? widget.unit.compoundId ?? 'N/A'),
          _buildSpecRow('Status', widget.unit.status ?? 'N/A'),
          _buildSpecRow('Available', widget.unit.available != null ? (widget.unit.available! ? 'Yes' : 'No') : 'N/A'),
          // Update Notes - Show if unit was recently updated
          if (widget.unit.notes != null && widget.unit.notes!.isNotEmpty)
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
                          'Recent Update',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.unit.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildSpecRow(l10n.saleType, 'Resale'),
          _buildSpecRow(l10n.finishing, widget.unit.finishing ?? 'N/A'),
          _buildSpecRow(l10n.deliveryDate, widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty
            ? _formatDate(widget.unit.deliveryDate!) : 'N/A'),
          _buildSpecRow(l10n.builtUpArea, widget.unit.builtUpArea != null
            ? '${widget.unit.builtUpArea} ${l10n.sqm}'
            : (widget.unit.area != '0' ? '${widget.unit.area} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow('Total Area', widget.unit.area != '0' ? '${widget.unit.area} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.landArea, widget.unit.landArea != null
            ? '${widget.unit.landArea} ${l10n.sqm}'
            : (widget.unit.gardenArea != null && widget.unit.gardenArea != '0' ? '${widget.unit.gardenArea} ${l10n.sqm}' : 'N/A')),
          _buildSpecRow('Garden Area', widget.unit.gardenArea != null && widget.unit.gardenArea != '0' ? '${widget.unit.gardenArea} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.roofArea, widget.unit.roofArea != null && widget.unit.roofArea != '0' ? '${widget.unit.roofArea} ${l10n.sqm}' : 'N/A'),
          _buildSpecRow(l10n.floor, widget.unit.floor != '0' ? widget.unit.floor : 'N/A'),
          _buildSpecRow(l10n.building, widget.unit.buildingName ?? 'N/A'),
          _buildSpecRow('Company', widget.unit.companyName ?? 'N/A'),
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
            color: Colors.grey.shade700,
            bold: false,
          ),
          Expanded(
            child: CustomText16(
              value,
              bold: true,
              color: Colors.black87,
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
        return GestureDetector(
          onTap: () {
            // Open zoomable image viewer
            ZoomableImageViewer.show(
              context,
              images: widget.unit.images,
              initialIndex: index,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RobustNetworkImage(
              imageUrl: widget.unit.images[index],
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
    final compoundLocation = unit.compoundName ?? '';
    final actualLocation = compoundLocation.isNotEmpty ? compoundLocation : l10n.locationNotAvailable ?? 'Location not available';

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
                    CustomText18(
                      l10n.location ?? 'Location',
                      bold: true,
                      color: AppColors.black,
                    ),
                    SizedBox(height: 4),
                    CustomText14(
                      l10n.compoundLocation ?? 'Compound Location',
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Location Card
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
                // Compound Name
                Row(
                  children: [
                    Icon(Icons.apartment, size: 20, color: AppColors.mainColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomText16(
                        l10n.compoundName ?? 'Compound',
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: CustomText18(
                    actualLocation,
                    bold: true,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),

                // Unit Details
                Row(
                  children: [
                    Icon(Icons.home_work, size: 20, color: AppColors.mainColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomText16(
                        l10n.unitDetails ?? 'Unit Details',
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unit.buildingName != null && unit.buildingName!.isNotEmpty) ...[
                        _locationDetailRow(
                          Icons.business,
                          l10n.building ?? 'Building',
                          unit.buildingName!,
                        ),
                        SizedBox(height: 8),
                      ],
                      if (unit.floor.isNotEmpty && unit.floor != '0') ...[
                        _locationDetailRow(
                          Icons.layers,
                          l10n.floor ?? 'Floor',
                          unit.floor,
                        ),
                        SizedBox(height: 8),
                      ],
                      if (unit.unitNumber != null && unit.unitNumber!.isNotEmpty) ...[
                        _locationDetailRow(
                          Icons.pin,
                          l10n.unitNumber ?? 'Unit Number',
                          unit.unitNumber!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Location URL / Map
          if (unit.compoundLocationUrl != null && unit.compoundLocationUrl!.isNotEmpty) ...[
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
                        child: CustomText16(
                          l10n.viewOnMap ?? 'View on Map',
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(unit.compoundLocationUrl!);
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
                    CustomText14(
                      l10n.mapViewNotAvailable ?? 'Map view coming soon',
                      color: Colors.grey.shade600,
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
          Icon(Icons.architecture, size: 60, color: AppColors.grey),
          SizedBox(height: 16),
          CustomText16(l10n.floorPlanNotAvailable, color: AppColors.grey),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
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
                    'My Notes (${_notes.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: Icon(Icons.add, size: 16),
                label: Text('Add Note'),

                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mainColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_notes.isEmpty) ...[
            Text(
              'Add your personal notes about this unit. Your notes are private and only visible to you.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
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
                              note['title'] ?? 'Note',
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
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Updated: ${_formatNoteDate(note['updated_at'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
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
      ),
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
              mainAxisSize: MainAxisSize.min,
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

  // Notes Section
  Future<void> _showNoteDialog({
    int? noteId,
    String? initialContent,
    String? initialTitle,
  }) async {
    final result = await NoteDialog.show(
      context,
      initialNote: initialContent,
      title: noteId != null ? 'Edit Note' : 'Add Note',
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
            message: 'Note saved successfully',
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
          _showCenteredMessage(
            context: context,
            message: 'Failed to save note',
            isSuccess: false,
          );
        }
      }
    }
  }

  Future<void> _deleteNote(int noteId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
            message: 'Note deleted successfully',
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
          _showCenteredMessage(
            context: context,
            message: 'Failed to delete note',
            isSuccess: false,
          );
        }
      }
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
              Colors.grey.shade800,
            ),

          // Changed fields
          if (unit.changedFields != null && unit.changedFields!.isNotEmpty) ...[
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
              color: Colors.grey.shade800,
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
}
