import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/compound/presentation/bloc/unit/unit_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/unit/unit_event.dart';
import 'package:real/feature/compound/presentation/bloc/unit/unit_state.dart';
import 'package:real/core/network/api_service.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/data/services/sale_web_services.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/widgets/zoomable_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:real/feature_web/widgets/web_unit_card.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';

class WebCompoundDetailScreen extends StatefulWidget {
  static String routeName = '/web-compound-detail';
  final String compoundId;

  WebCompoundDetailScreen({Key? key, required this.compoundId}) : super(key: key);

  @override
  State<WebCompoundDetailScreen> createState() => _WebCompoundDetailScreenState();
}

class _WebCompoundDetailScreenState extends State<WebCompoundDetailScreen> with SingleTickerProviderStateMixin {
  int _selectedImageIndex = 0;
  List<dynamic> _salespeople = [];
  bool _loadingSalespeople = false;
  bool _isFinishSpecsExpanded = false;
  Timer? _imageTimer;
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final SaleWebServices _saleWebServices = SaleWebServices();
  final FavoritesWebServices _favoritesWebServices = FavoritesWebServices();
  Sale? _compoundSale;
  bool _isLoadingSale = false;
  Compound? _currentCompound;
  String? _currentNote;
  String? _lastFetchedCompoundId; // Track which compound we've fetched notes for

  // Notes for tab
  List<Map<String, dynamic>> _compoundNotes = [];
  bool _isLoadingNotes = false;
  final TextEditingController _noteController = TextEditingController();

  // Units search
  final TextEditingController _unitsSearchController = TextEditingController();
  String _unitsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    context.read<CompoundBloc>().add(FetchCompoundDetailEvent(compoundId: widget.compoundId));
    context.read<UnitBloc>().add(FetchUnitsEvent(compoundId: widget.compoundId));
    _startImageRotation();
    _fetchCompoundSale();
  }

  void _startImageRotation() {
    _imageTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _selectedImageIndex = (_selectedImageIndex + 1);
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
    _messageController.dispose();
    _noteController.dispose();
    _unitsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CompoundBloc, CompoundState>(
      builder: (context, state) {
        if (state is CompoundDetailLoading) {
          return Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                l10n.loading,
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

        if (state is CompoundDetailError) {
          return Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                l10n.error,
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
                    state.message,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CompoundBloc>().add(
                        FetchCompoundDetailEvent(compoundId: widget.compoundId),
                      );
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CompoundDetailSuccess) {
          final compoundData = state.compoundData;
          // Extract the actual compound data from API response
          final Map<String, dynamic> actualCompoundData = compoundData['data'] != null && compoundData['data'] is Map
              ? compoundData['data'] as Map<String, dynamic>
              : compoundData;
          // Track view history
          final compound = Compound.fromJson(actualCompoundData);
          ViewHistoryService().addViewedCompound(compound);

          // Store compound and fetch notes from API only if we haven't fetched for this compound yet
          _currentCompound = compound;
          _currentNote = compound.notes;

          print('[WEB COMPOUND DETAIL] Current compound ID: ${compound.id}');
          print('[WEB COMPOUND DETAIL] Last fetched compound ID: $_lastFetchedCompoundId');
          print('[WEB COMPOUND DETAIL] Is loading notes: $_isLoadingNotes');

          // Only fetch if this is a new compound or if we haven't fetched yet
          if (_lastFetchedCompoundId != compound.id && !_isLoadingNotes) {
            print('[WEB COMPOUND DETAIL] Triggering notes fetch for compound ${compound.id}');
            _lastFetchedCompoundId = compound.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchCompoundNotes();
            });
          } else {
            print('[WEB COMPOUND DETAIL] Skipping notes fetch - already fetched or loading');
          }

          return _buildDetailScreen(compoundData, l10n);
        }

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Center(child: Text(l10n.noData)),
        );
      },
    );
  }

  Widget _buildDetailScreen(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    // Extract the actual compound data from API response
    // API response structure: { "data": { compound_fields... } }
    final Map<String, dynamic> actualCompoundData = compoundData['data'] != null && compoundData['data'] is Map
        ? compoundData['data'] as Map<String, dynamic>
        : compoundData;

    print('====== WEB COMPOUND DETAIL DEBUG ======');
    print('Raw API Response keys: ${compoundData.keys.toList()}');
    print('Has data field: ${compoundData.containsKey('data')}');
    print('Actual compound data keys: ${actualCompoundData.keys.toList()}');
    print('======================================');

    // Load salespeople when compound data is available
    if (_salespeople.isEmpty && !_loadingSalespeople) {
      _loadSalespeople(actualCompoundData['project'] ?? '');
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: _buildHomeTab(actualCompoundData, l10n),
    );
  }

  Future<void> _loadSalespeople(String compoundName) async {
    if (compoundName.isEmpty) return;
    setState(() => _loadingSalespeople = true);
    try {
      final apiService = ApiService();
      final response = await apiService.compoundRepository.getSalespeopleByCompound(compoundName);
      setState(() {
        _salespeople = response['salespeople'] ?? [];
        _loadingSalespeople = false;
      });
    } catch (e) {
      setState(() => _loadingSalespeople = false);
      print('Error loading salespeople: $e');
    }
  }

  Future<void> _fetchCompoundSale() async {
    if (_isLoadingSale) return;

    setState(() {
      _isLoadingSale = true;
    });

    try {
      final response = await _saleWebServices.getSalesByCompound(widget.compoundId);

      if (response['success'] == true && response['sales'] != null) {
        final sales = (response['sales'] as List)
            .map((sale) => Sale.fromJson(sale as Map<String, dynamic>))
            .where((sale) => sale.isCurrentlyActive)
            .toList();

        if (mounted && sales.isNotEmpty) {
          setState(() {
            _compoundSale = sales.first;
            _isLoadingSale = false;
          });
          print('[WEB COMPOUND DETAIL] Found active sale: ${_compoundSale!.saleName}');
        } else {
          if (mounted) {
            setState(() {
              _isLoadingSale = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSale = false;
          });
        }
      }
    } catch (e) {
      print('[WEB COMPOUND DETAIL] Error fetching compound sale: $e');
      if (mounted) {
        setState(() {
          _isLoadingSale = false;
        });
      }
    }
  }

  Future<void> _fetchCompoundNote() async {
    if (_currentCompound == null) return;

    try {
      final response = await _favoritesWebServices.getNotes(
        compoundId: int.parse(_currentCompound!.id),
      );

      if (response['success'] == true && response['notes'] != null) {
        final notes = response['notes'] as List;
        if (notes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentNote = notes.first['content'] as String?;
            });
          }
          print('[WEB COMPOUND DETAIL] Loaded note: $_currentNote');
        }
      }
    } catch (e) {
      print('[WEB COMPOUND DETAIL] Error fetching compound note: $e');
    }
  }

  // Helper methods to safely get data from API response
  List<String> _getImages(Map<String, dynamic> data) {
    // Debug print
    print('====== COMPOUND DETAIL IMAGES DEBUG ======');
    print('Compound data keys: ${data.keys.toList()}');
    print('Images field: ${data['images']}');
    print('Images type: ${data['images'].runtimeType}');

    if (data['images'] == null) {
      print('Images is null');
      return [];
    }

    if (data['images'] is String) {
      // Sometimes API returns single image as string
      final imageUrl = data['images'] as String;
      print('Single image string: $imageUrl');
      return imageUrl.isNotEmpty ? [imageUrl] : [];
    }

    if (data['images'] is List) {
      final imagesList = (data['images'] as List)
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
      print('Found ${imagesList.length} images');
      for (int i = 0; i < imagesList.length; i++) {
        print('Image $i: ${imagesList[i]}');
      }
      return imagesList;
    }

    print('Images field is unknown type');
    return [];
  }

  String _getString(Map<String, dynamic> data, String key, [String defaultValue = '']) {
    return data[key]?.toString() ?? defaultValue;
  }

  Widget _buildImageGallery(Map<String, dynamic> compoundData) {
    final images = _getImages(compoundData);

    print('Building image gallery with ${images.length} images');

    // Calculate current index with modulo for looping
    final currentIndex = images.isNotEmpty ? _selectedImageIndex % images.length : 0;

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
        child: images.isNotEmpty
            ? GestureDetector(
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
                  child: Stack(
                    children: [
                      RobustNetworkImage(
                        imageUrl: images[currentIndex],
                        height: 350,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) => _buildImagePlaceholder(),
                      ),
                  // Gradient overlay at bottom
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
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildCompoundInfo(Map<String, dynamic> compoundData) {
    final companyLogo = _getString(compoundData, 'company_logo');
    final companyName = _getString(compoundData, 'company_name');
    final compoundId = _getString(compoundData, 'id');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (companyLogo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: RobustNetworkImage(
                    imageUrl: companyLogo,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                    errorBuilder: (context, url) => SizedBox.shrink(),
                  ),
                ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
              // Share button
              IconButton(
                icon: Icon(Icons.share_outlined, color: AppColors.mainColor),
                onPressed: () {
                  // Share compound functionality
                  if (_currentCompound != null) {
                    // Get units from bloc state
                    final unitState = context.read<UnitBloc>().state;
                    List<Map<String, dynamic>>? units;
                    if (unitState is UnitSuccess) {
                      units = unitState.response.data.map((unit) => {
                        'id': unit.id,
                        'unit_name': unit.unitNumber ?? 'Unit ${unit.id}',
                        'unit_code': unit.code ?? unit.unitNumber,
                      }).toList();
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AdvancedShareBottomSheet(
                        type: 'compound',
                        id: _currentCompound!.id,
                        units: units,
                      ),
                    );
                  }
                },
                tooltip: 'Share',
              ),
              // Favorite button
              BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                builder: (context, state) {
                  bool isFavorite = false;
                  if (state is CompoundFavoriteUpdated && _currentCompound != null) {
                    isFavorite = state.favorites.any((c) => c.id == _currentCompound!.id);
                  }
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : AppColors.mainColor,
                    ),
                    onPressed: () {
                      if (_currentCompound != null) {
                        if (isFavorite) {
                          context.read<CompoundFavoriteBloc>().add(
                            RemoveFavoriteCompound(_currentCompound!),
                          );
                        } else {
                          context.read<CompoundFavoriteBloc>().add(
                            AddFavoriteCompound(_currentCompound!),
                          );
                        }
                      }
                    },
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE6E6E6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: AppColors.mainColor.withOpacity(0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No images available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mainColor),
          SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalespeople() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(24),
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
              Icon(Icons.support_agent, color: AppColors.mainColor),
              SizedBox(width: 12),
              Text(
                l10n.contactSales,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (_loadingSalespeople)
            Center(child: CustomLoadingDots(size: 60))
          else if (_salespeople.isEmpty)
            Text(
              l10n.noSalesPersonAvailable,
              style: TextStyle(color: AppColors.greyText),
            )
          else
            ..._salespeople.map((salesperson) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salesperson['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Color(0xFF666666)),
                        SizedBox(width: 8),
                        Text(
                          salesperson['phone'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                    if (salesperson['phone'] != null) ...[
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open WhatsApp
                          },
                          icon: Icon(Icons.chat, size: 16),
                          label: Text(l10n.whatsapp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Tab Views
  Widget _buildHomeTab(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ---------------- LEFT CONTENT ----------------
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageGallery(compoundData),
                      SizedBox(height: 16),

                      _buildCompoundDescription(compoundData),
                      SizedBox(height: 16),

                      if (_getString(compoundData, 'finish_specs').isNotEmpty) ...[
                        _buildFinishSpecs(compoundData),
                        SizedBox(height: 16),
                      ],

                      _buildFeaturesAmenities(compoundData),
                      SizedBox(height: 16),

                      /// ---- TAB BAR ----
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.grey,
                        indicator: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        labelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: [
                          Tab(text: l10n.gallery),
                          Tab(text: l10n.units),
                          Tab(text: l10n.viewOnMap),
                          Tab(text: l10n.masterPlan),
                          Tab(text: l10n.floorPlan),
                          Tab(text: l10n.notes),
                        ],
                      ),
                      SizedBox(height: 16),

                      /// ---- TAB CONTENT ----
                      SizedBox(
                        height: 800,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildGalleryTab(compoundData),
                            _buildUnitsTab(),
                            _buildLocationTab(compoundData, l10n),
                            _buildMasterPlanTab(compoundData, l10n),
                            _buildFloorPlanTab(compoundData, l10n),
                            _buildNotesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20),

                /// ---------------- RIGHT SIDEBAR ----------------
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      if (_compoundSale != null) ...[
                        _buildSaleSection(_compoundSale!, l10n),
                        SizedBox(height: 16),
                      ],

                      _buildPricingInfo(compoundData),
                      SizedBox(height: 16),

                      _buildSalespeople(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New Tab Content Methods
  Widget _buildGalleryTab(Map<String, dynamic> compoundData) {
    final images = _getImages(compoundData);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: AppColors.mainColor.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No images available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Open zoomable image viewer
                    ZoomableImageViewer.show(
                      context,
                      images: images,
                      initialIndex: index,
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RobustNetworkImage(
                        imageUrl: images[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) => Container(
                          color: Color(0xFFF8F9FA),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.mainColor.withOpacity(0.3),
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLocationTab(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    final locationUrl = _getString(compoundData, 'location_url');
    final location = _getString(compoundData, 'location');

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.location_on,
                size: 80,
                color: AppColors.mainColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              location,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (locationUrl.isNotEmpty)
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(locationUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.directions, size: 20, color: Colors.white),
                  label: Text(
                    l10n.openLocationInMaps ?? 'Open Location in Maps',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Text(
                l10n.mapViewNotAvailable ?? 'Map location not available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterPlanTab(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    final masterPlan = _getString(compoundData, 'master_plan');
    final locationUrl = _getString(compoundData, 'location_url');

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: masterPlan.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: AppColors.mainColor.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No master plan available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locationUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Open location URL in browser
                        final uri = Uri.parse(locationUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Icon(Icons.location_on, size: 18),
                      label: Text(l10n.viewOnMap),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RobustNetworkImage(
                    imageUrl: masterPlan,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, url) => Container(
                      height: 400,
                      color: Color(0xFFF8F9FA),
                      child: Center(
                        child: Icon(
                          Icons.map,
                          size: 100,
                          color: AppColors.mainColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUnitsTab() {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UnitBloc, UnitState>(
      builder: (context, state) {
        if (state is UnitLoading) {
          return Center(child: CustomLoadingDots(size: 120));
        } else if (state is UnitSuccess) {
          final allUnits = state.response.data;

          // Filter units based on search query
          final filteredUnits = allUnits.where((unit) {
            if (_unitsSearchQuery.isEmpty) return true;

            final query = _unitsSearchQuery.toLowerCase();
            final unitNumber = (unit.unitNumber ?? '').toLowerCase();
            final unitType = (unit.unitType ?? '').toLowerCase();
            final price = (unit.price ?? '').toLowerCase();
            final bedrooms = (unit.bedrooms ?? '').toLowerCase();
            final floor = (unit.floor ?? '').toLowerCase();
            final status = (unit.status ?? '').toLowerCase();

            return unitNumber.contains(query) ||
                   unitType.contains(query) ||
                   price.contains(query) ||
                   bedrooms.contains(query) ||
                   floor.contains(query) ||
                   status.contains(query);
          }).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.all(24),
                child: TextField(
                  controller: _unitsSearchController,
                  onChanged: (value) {
                    setState(() {
                      _unitsSearchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '${l10n.searchForUnits ?? 'Search for units'}...',
                    prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                    suffixIcon: _unitsSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _unitsSearchController.clear();
                                _unitsSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Results count
              if (_unitsSearchQuery.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '${l10n.foundResults(filteredUnits.length)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 8),

              // Units grid or empty state
              Expanded(
                child: filteredUnits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _unitsSearchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.home_outlined,
                              size: 80,
                              color: AppColors.mainColor.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              _unitsSearchQuery.isNotEmpty
                                  ? l10n.noResultsFound ?? 'No results found'
                                  : 'No units available',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.greyText,
                              ),
                            ),
                            if (_unitsSearchQuery.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Try different search terms',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFBBBBBB),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: filteredUnits.length,
                        itemBuilder: (context, index) {
                          return WebUnitCard(unit: filteredUnits[index]);
                        },
                      ),
              ),
            ],
          );
        } else if (state is UnitError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        return Center(child: Text('No units data available'));
      },
    );
  }

  Widget _buildFloorPlanTab(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    final floorPlan = _getString(compoundData, 'floor_plan');

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: floorPlan.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.architecture_outlined,
                    size: 80,
                    color: AppColors.mainColor.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No floor plan available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RobustNetworkImage(
                    imageUrl: floorPlan,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, url) => Container(
                      height: 400,
                      color: Color(0xFFF8F9FA),
                      child: Center(
                        child: Icon(
                          Icons.architecture,
                          size: 100,
                          color: AppColors.mainColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Build Sale Section (like unit details)
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
          SizedBox(height: 8),
          Text(
            sale.saleName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            sale.description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.greyText,
              height: 1.4,
            ),
          ),
          if (sale.daysRemaining > 0) ...[
            SizedBox(height: 8),
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

  Widget _buildFinishSpecs(Map<String, dynamic> compoundData) {
    final finishSpecs = _getString(compoundData, 'finish_specs');
    final l10n = AppLocalizations.of(context)!;

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
            l10n.finishSpecifications,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          AnimatedCrossFade(
            duration: Duration(milliseconds: 300),
            crossFadeState: _isFinishSpecsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Html(
              data: finishSpecs,
              style: {
                "body": Style(
                  fontSize: FontSize(12),
                  color: AppColors.greyText,
                  lineHeight: LineHeight(1.6),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              },
            ),
            secondChild: Html(
              data: finishSpecs,
              style: {
                "body": Style(
                  fontSize: FontSize(12),
                  color: AppColors.greyText,
                  lineHeight: LineHeight(1.6),
                ),
              },
            ),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isFinishSpecsExpanded = !_isFinishSpecsExpanded;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isFinishSpecsExpanded ? 'Show Less' : l10n.showAll,
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompoundDescription(Map<String, dynamic> compoundData) {
    final project = _getString(compoundData, 'project');
    final location = _getString(compoundData, 'location');
    final status = _getString(compoundData, 'status');
    final totalUnits = _getString(compoundData, 'total_units');
    final availableUnits = _getString(compoundData, 'available_units');
    final builtUpArea = _getString(compoundData, 'built_up_area', '0.00');
    final floors = _getString(compoundData, 'how_many_floors', '0');
    final l10n = AppLocalizations.of(context)!;

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
          _buildCompoundInfo(compoundData),          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              project,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          _buildInfoRow(Icons.location_on_outlined, l10n.location, location),
          _buildInfoRow(Icons.check_circle_outline, l10n.status, status),
          _buildInfoRow(Icons.apartment_outlined, l10n.totalUnits, totalUnits),
          _buildInfoRow(Icons.verified_outlined, l10n.availableUnits, availableUnits),
          if (builtUpArea != '0.00' && builtUpArea.isNotEmpty)
            _buildInfoRow(Icons.square_foot_outlined, l10n.builtArea, '$builtUpArea ${l10n.sqm}'),
          if (floors != '0' && floors.isNotEmpty)
            _buildInfoRow(Icons.layers_outlined, l10n.floors, floors),
        ],
      ),
    );
  }

  Widget _buildPricingInfo(Map<String, dynamic> compoundData) {
    final deliveryDate = _getString(compoundData, 'planned_delivery_date');
    final completionProgress = _getString(compoundData, 'completion_progress', '0.00');
    final l10n = AppLocalizations.of(context)!;

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
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildPricingRow(l10n.startingPrice, l10n.contactForDetails),
          SizedBox(height: 8),
          _buildPricingRow(l10n.paymentPlans, l10n.available),
          SizedBox(height: 12),
          _buildPricingRow(l10n.deliveryDate, deliveryDate.isNotEmpty
              ? _formatDate(deliveryDate)
              : l10n.tba),
          if (completionProgress.isNotEmpty && completionProgress != '0.00' && completionProgress != '0') ...[
            SizedBox(height: 20),
            Text(
              l10n.completionProgress,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyText,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: double.tryParse(completionProgress) != null
                  ? double.parse(completionProgress) / 100
                  : 0,
              backgroundColor: Color(0xFFE6E6E6),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
              minHeight: 8,
            ),
            SizedBox(height: 4),
            Text(
              '$completionProgress% ${l10n.complete}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mainColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

  Widget _buildPricingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.greyText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesAmenities(Map<String, dynamic> compoundData) {
    final club = _getString(compoundData, 'club');
    final l10n = AppLocalizations.of(context)!;

    final amenities = [
      {'icon': Icons.pool, 'label': l10n.swimmingPool, 'available': club == '1'},
      {'icon': Icons.fitness_center, 'label': l10n.gym, 'available': club == '1'},
      {'icon': Icons.sports_tennis, 'label': l10n.sportsClub, 'available': club == '1'},
      {'icon': Icons.security, 'label': l10n.security247, 'available': true},
      {'icon': Icons.local_parking, 'label': l10n.parking, 'available': true},
      {'icon': Icons.park, 'label': l10n.greenAreas, 'available': true},
      {'icon': Icons.shopping_bag, 'label': l10n.commercialArea, 'available': true},
      {'icon': Icons.child_care, 'label': l10n.kidsArea, 'available': club == '1'},
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
            l10n.featuresAmenities,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              final available = amenity['available'] as bool;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: available
                      ? AppColors.mainColor.withOpacity(0.05)
                      : Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: available
                        ? AppColors.mainColor.withOpacity(0.3)
                        : Color(0xFFE6E6E6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      amenity['icon'] as IconData,
                      size: 14,
                      color: available ? AppColors.mainColor : Color(0xFF999999),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        amenity['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: available ? AppColors.mainColor : AppColors.greyText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

  // Build Notes Tab
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
              : _compoundNotes.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: TextStyle(fontSize: 16, color: AppColors.greyText),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first note above',
                  style: TextStyle(fontSize: 14, color: AppColors.greyText),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _compoundNotes.length,
            itemBuilder: (context, index) {
              final note = _compoundNotes[index];
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
                                color: Colors.black,
                              ),
                            ),
                            if (createdAt.isNotEmpty) ...[
                              SizedBox(height: 6),
                              Text(
                                _formatNoteDate(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
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
  // Fetch compound notes
  Future<void> _fetchCompoundNotes() async {
    if (_currentCompound == null) {
      print('[WEB COMPOUND DETAIL] Cannot fetch notes: _currentCompound is null');
      return;
    }

    if (_isLoadingNotes) {
      print('[WEB COMPOUND DETAIL] Already loading notes, skipping...');
      return;
    }

    print('[WEB COMPOUND DETAIL] Fetching notes for compound ID: ${_currentCompound!.id}');
    setState(() => _isLoadingNotes = true);

    try {
      final compoundIdInt = int.tryParse(_currentCompound!.id);
      print('[WEB COMPOUND DETAIL] Parsed compound ID: $compoundIdInt');

      final response = await _favoritesWebServices.getNotes(
        compoundId: compoundIdInt,
      );

      print('[WEB COMPOUND DETAIL] Notes API response received');
      print('[WEB COMPOUND DETAIL] Response keys: ${response.keys}');
      print('[WEB COMPOUND DETAIL] Full response: $response');

      if (response['success'] == true) {
        List<Map<String, dynamic>> notes = [];
        bool structureMatched = false;

        // Check multiple possible response structures
        if (response['data'] != null && response['data'] is Map && response['data']['notes'] != null) {
          // Structure: { success: true, data: { notes: [...] } }
          print('[WEB COMPOUND DETAIL] Response structure: data.notes');
          notes = (response['data']['notes'] as List)
              .map((note) => note as Map<String, dynamic>)
              .toList();
          structureMatched = true;
        } else if (response['notes'] != null && response['notes'] is List) {
          // Structure: { success: true, notes: [...] }
          print('[WEB COMPOUND DETAIL] Response structure: notes array');
          notes = (response['notes'] as List)
              .map((note) => note as Map<String, dynamic>)
              .toList();
          structureMatched = true;
        } else if (response['data'] is List) {
          // Structure: { success: true, data: [...] }
          print('[WEB COMPOUND DETAIL] Response structure: data array');
          notes = (response['data'] as List)
              .map((note) => note as Map<String, dynamic>)
              .toList();
          structureMatched = true;
        } else {
          print('[WEB COMPOUND DETAIL] ⚠️ WARNING: Response structure does not match any expected pattern!');
          print('[WEB COMPOUND DETAIL] Available keys: ${response.keys.toList()}');
          if (response['data'] != null) {
            print('[WEB COMPOUND DETAIL] data type: ${response['data'].runtimeType}');
            if (response['data'] is Map) {
              print('[WEB COMPOUND DETAIL] data keys: ${(response['data'] as Map).keys.toList()}');
            }
          }
        }

        print('[WEB COMPOUND DETAIL] Structure matched: $structureMatched');
        print('[WEB COMPOUND DETAIL] Parsed ${notes.length} notes');
        if (notes.isNotEmpty) {
          print('[WEB COMPOUND DETAIL] First note: ${notes.first}');
        } else if (structureMatched) {
          print('[WEB COMPOUND DETAIL] Structure matched but notes list is empty');
        }

        if (mounted) {
          setState(() {
            _compoundNotes = notes;
            _isLoadingNotes = false;
          });
        }
      } else {
        print('[WEB COMPOUND DETAIL] Notes fetch failed: success=false, message: ${response['message']}');
        if (mounted) {
          setState(() => _isLoadingNotes = false);
        }
      }
    } catch (e) {
      print('[WEB COMPOUND DETAIL] Error fetching notes: $e');
      if (mounted) {
        setState(() => _isLoadingNotes = false);
      }
    }
  }

  // Add note
  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) {
      _showCenteredMessage(
        context: context,
        message: 'Please enter a note',
        isSuccess: false,
      );
      return;
    }

    try {
      final response = await _favoritesWebServices.createNote(
        content: _noteController.text.trim(),
        title: 'Compound Note',
        compoundId: int.tryParse(_currentCompound!.id),
      );

      if (response['success'] == true) {
        _noteController.clear();
        _showCenteredMessage(
          context: context,
          message: 'Note added successfully',
          isSuccess: true,
        );
        // Force refetch by resetting the tracking flag
        _lastFetchedCompoundId = null;
        _fetchCompoundNotes();
      } else {
        _showCenteredMessage(
          context: context,
          message: 'Failed to add note',
          isSuccess: false,
        );
      }
    } catch (e) {
      _showCenteredMessage(
        context: context,
        message: 'Error: $e',
        isSuccess: false,
      );
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
        _showCenteredMessage(
          context: context,
          message: 'Note deleted successfully',
          isSuccess: true,
        );
        // Force refetch by resetting the tracking flag
        _lastFetchedCompoundId = null;
        _fetchCompoundNotes();
      } else {
        _showCenteredMessage(
          context: context,
          message: 'Failed to delete note',
          isSuccess: false,
        );
      }
    } catch (e) {
      _showCenteredMessage(
        context: context,
        message: 'Error: $e',
        isSuccess: false,
      );
    }
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
  /// Build Units Section - Display all units in the compound
  Widget _buildUnitsSection(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Container(
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
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.home_work, color: AppColors.mainColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Available Units',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Units Grid
          BlocBuilder<UnitBloc, UnitState>(
            builder: (context, state) {
              if (state is UnitLoading) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CustomLoadingDots(
                      size: 120,
                    ),
                  ),
                );
              }

              if (state is UnitSuccess) {
                final units = state.response.data;

                if (units.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No units available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: units.length > 12 ? 12 : units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return WebUnitCard(unit: unit);
                  },
                );
              }

              if (state is UnitError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading units',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox.shrink();
            },
          ),
        ],
        ),
      ),
    );
  }
}
