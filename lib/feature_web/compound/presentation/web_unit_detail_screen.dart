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

class WebUnitDetailScreen extends StatefulWidget {
  static String routeName = '/web-unit-detail';
  final Unit unit;

  WebUnitDetailScreen({Key? key, required this.unit}) : super(key: key);

  @override
  State<WebUnitDetailScreen> createState() => _WebUnitDetailScreenState();
}

class _WebUnitDetailScreenState extends State<WebUnitDetailScreen> {
  int _selectedImageIndex = 0;
  Timer? _imageTimer;
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSalesPeople();
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
                        _buildAboutSection(l10n),
                        SizedBox(height: 16),
                        _buildAmenitiesSection(l10n),
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
          // Price
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

    final agent = _salesPeople.isNotEmpty ? _salesPeople.first : null;

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
          if (agent != null) ...[
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
                      agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
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
                        agent.name,
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
            if (agent.hasPhone) ...[
              _buildContactButton(
                icon: Icons.phone,
                label: l10n.callNow,
                color: AppColors.mainColor,
                onTap: () async {
                  final uri = Uri.parse('tel:${agent.phone}');
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
                  final uri = Uri.parse('https://wa.me/${agent.phone}');
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
}
