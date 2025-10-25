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
import '../../../feature_web/widgets/web_unit_card.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<CompoundBloc>().add(FetchCompoundDetailEvent(compoundId: widget.compoundId));
    context.read<UnitBloc>().add(FetchUnitsEvent(compoundId: widget.compoundId));
    _startImageRotation();
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
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.mainColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.loading,
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

        if (state is CompoundDetailError) {
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
            ? Stack(
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
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildCompoundInfo(Map<String, dynamic> compoundData) {
    final companyLogo = _getString(compoundData, 'company_logo');
    final companyName = _getString(compoundData, 'company_name');

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
                color: Color(0xFF999999),
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
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
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
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (_loadingSalespeople)
            Center(child: CircularProgressIndicator())
          else if (_salespeople.isEmpty)
            Text(
              l10n.noSalesPersonAvailable,
              style: TextStyle(color: Color(0xFF999999)),
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
                        color: Color(0xFF333333),
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
                            color: Color(0xFF666666),
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
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                _buildImageGallery(compoundData),
                SizedBox(height: 20),

                // Main Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Main Info
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildCompoundDescription(compoundData),
                          SizedBox(height: 16),
                          _buildCompoundInfo(compoundData),
                          SizedBox(height: 16),
                          if (_getString(compoundData, 'finish_specs').isNotEmpty)
                            _buildFinishSpecs(compoundData),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),

                    // Right Column - Pricing & Contact
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildPricingInfo(compoundData),
                          SizedBox(height: 16),
                          _buildSalespeople(),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Features & Amenities
                _buildFeaturesAmenities(compoundData),
                SizedBox(height: 20),

                // TabBar Section
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
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE6E6E6),
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.mainColor,
                          labelColor: AppColors.mainColor,
                          unselectedLabelColor: Color(0xFF666666),
                          labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          tabs: [
                            Tab(text: 'Gallery'),
                            Tab(text: l10n.masterPlan),
                            Tab(text: l10n.units),
                            Tab(text: 'Request'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 450,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildGalleryTab(compoundData),
                            _buildMasterPlanTab(compoundData, l10n),
                            _buildUnitsTabContent(compoundData, l10n),
                            _buildRequestTab(l10n),
                          ],
                        ),
                      ),
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
                      color: Color(0xFF999999),
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
                return ClipRRect(
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
                );
              },
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
                      color: Color(0xFF999999),
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
                      onPressed: () {
                        // Open location URL in browser
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

  Widget _buildUnitsTabContent(Map<String, dynamic> compoundData, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: BlocBuilder<UnitBloc, UnitState>(
        builder: (context, state) {
          if (state is UnitLoading) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AppColors.mainColor),
              ),
            );
          } else if (state is UnitSuccess) {
            if (state.response.data.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Text(
                    l10n.noUnitsAvailable,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: state.response.data.length,
              itemBuilder: (context, index) {
                return WebUnitCard(unit: state.response.data[index]);
              },
            );
          } else if (state is UnitError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Text(
                  state.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRequestTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.requestMoreInformation,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.yourName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.emailAddress,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.messageOptional,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Handle form submission
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
              color: Color(0xFF333333),
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
                  color: Color(0xFF666666),
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
                  color: Color(0xFF666666),
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
          // Compound Name
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              project,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
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
                  color: Color(0xFF333333),
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
                color: Color(0xFF666666),
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
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
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
              color: Color(0xFF333333),
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
                          color: available ? AppColors.mainColor : Color(0xFF999999),
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

}
