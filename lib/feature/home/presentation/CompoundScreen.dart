import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/home/presentation/widget/location.dart';
import 'package:real/feature/home/presentation/widget/rete_review.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../../core/widget/button/showAll.dart';
import '../../compound/presentation/bloc/unit/unit_bloc.dart';
import '../../compound/presentation/bloc/unit/unit_event.dart';
import '../../compound/presentation/bloc/unit/unit_state.dart';
import '../../compound/presentation/widget/unit_card.dart';
import '../../compound/data/web_services/compound_web_services.dart';
import '../../sale/data/models/sale_model.dart';
import '../../sale/presentation/widgets/sales_person_selector.dart';

class CompoundScreen extends StatefulWidget {
  static const String routeName = '/compund';
  final Compound compound;

  const CompoundScreen({super.key, required this.compound});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> {
  int _currentImageIndex = 0;
  int _userRating = 0; // User's rating (0-5)
  bool _showAllUnits = false;
  bool _showReviews = false; // Control reviews visibility
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _imagePageController = PageController();
  Timer? _imageSliderTimer;
  final CompoundWebServices _compoundWebServices = CompoundWebServices();
  final List<Map<String, dynamic>> _reviews = [
    {
      'userName': 'Ahmed Mohamed',
      'rating': 5,
      'comment': 'Excellent compound with great facilities and location!',
      'date': '2 days ago',
    },
    {
      'userName': 'Sarah Hassan',
      'rating': 4,
      'comment': 'Good value for money, nice community and well maintained.',
      'date': '1 week ago',
    },
    {
      'userName': 'Khaled Ali',
      'rating': 5,
      'comment':
          'Perfect place to live, great amenities and friendly neighbors.',
      'date': '2 weeks ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Debug: Print image count and URLs
    print('==========================================');
    print('[COMPOUND SCREEN] Compound: ${widget.compound.project}');
    print('[COMPOUND SCREEN] Total images: ${widget.compound.images.length}');
    for (int i = 0; i < widget.compound.images.length; i++) {
      print('[COMPOUND SCREEN] Image $i: ${widget.compound.images[i]}');
    }
    print('==========================================');

    // Fetch units for this compound
    context.read<UnitBloc>().add(
      FetchUnitsEvent(compoundId: widget.compound.id, limit: 100),
    );

    // Start auto-slider if there are multiple images
    if (widget.compound.images.length > 1) {
      _imageSliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_imagePageController.hasClients) {
          int nextPage =
              (_currentImageIndex + 1) % widget.compound.images.length;
          _imagePageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _imagePageController.dispose();
    _imageSliderTimer?.cancel();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    try {
      // Parse the date string
      final date = DateTime.parse(dateStr);
      // Format as day/month/year
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Future<void> _showSalespeople() async {
    try {
      final response = await _compoundWebServices.getSalespeopleByCompound(widget.compound.project);

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

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.mainColor.withOpacity(0.05),
            AppColors.mainColor.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CustomText16(label, bold: true, color: AppColors.black),
          ),
          Expanded(flex: 3, child: CustomText16(value, color: AppColors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = widget.compound.images.isNotEmpty;
    final displayImage = hasImages
        ? widget.compound.images[_currentImageIndex]
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasImages ? 300 : 120, // Smaller if no images
            pinned: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _showSalespeople,
                tooltip: l10n.contactSales,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                children: [
                  // Company logo if exists
                  if (widget.compound.companyLogo != null &&
                      widget.compound.companyLogo!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        widget.compound.companyLogo!,
                      ),
                      radius: 16,
                    ),

                  const SizedBox(width: 8),

                  // Company name
                  Expanded(
                    child: Text(
                      widget.compound.companyName.isNotEmpty
                          ? widget.compound.companyName
                          : "Unknown Company",
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              background: hasImages
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image Slider
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: widget.compound.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return RobustNetworkImage(
                              imageUrl: widget.compound.images[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorBuilder: (context, url) {
                                print(
                                  '[IMAGE ERROR] Failed to load image: $url',
                                );
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Dot Indicators (only show if multiple images)
                        if (widget.compound.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.compound.images.length,
                                (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.shade200, // Solid color if no images
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Location(compound: widget.compound),
                  const SizedBox(height: 24),

                  // Units Information
                  CustomText20(
                    l10n.unitsInformation,
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    l10n.availableUnits,
                    widget.compound.availableUnits,
                  ),
                  _buildInfoRow(l10n.status, widget.compound.status.toUpperCase()),

                  const SizedBox(height: 24),

                  // Project Details
                  CustomText20(
                    l10n.projectDetails,
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 12),
                  if (widget.compound.builtUpArea != "0.00")
                    _buildInfoRow(
                      l10n.builtUpArea,
                      "${widget.compound.builtUpArea} ${l10n.sqm}",
                    ),
                  if (widget.compound.builtArea != null &&
                      widget.compound.builtArea != "0.00")
                    _buildInfoRow(
                      l10n.builtArea,
                      "${widget.compound.builtArea} ${l10n.sqm}",
                    ),
                  if (widget.compound.landArea != null &&
                      widget.compound.landArea != "0.00")
                    _buildInfoRow(
                      l10n.landArea,
                      "${widget.compound.landArea} ${l10n.sqm}",
                    ),
                  if (widget.compound.howManyFloors != "0")
                    _buildInfoRow(
                      l10n.numberOfFloors,
                      widget.compound.howManyFloors,
                    ),
                  if (widget.compound.finishSpecs != null)
                    _buildInfoRow(l10n.finishSpecs, widget.compound.finishSpecs!),
                  _buildInfoRow(
                    l10n.hasClub,
                    widget.compound.club == "1" ? l10n.yes : l10n.no,
                  ),

                  const SizedBox(height: 24),

                  // Delivery Information
                  CustomText20(
                    l10n.deliveryInformation,
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 12),
                  if (widget.compound.plannedDeliveryDate != null)
                    _buildInfoRow(
                      l10n.plannedDelivery,
                      _formatDate(widget.compound.plannedDeliveryDate!),
                    ),
                  if (widget.compound.actualDeliveryDate != null)
                    _buildInfoRow(
                      l10n.actualDelivery,
                      _formatDate(widget.compound.actualDeliveryDate!),
                    ),
                  if (widget.compound.completionProgress != null)
                    _buildInfoRow(
                      l10n.completionProgress,
                      "${widget.compound.completionProgress}%",
                    ),

                  const SizedBox(height: 24),

                  // Sales Team Section
                  if (widget.compound.sales.isNotEmpty) ...[
                    CustomText20(
                      l10n.salesTeam,
                      bold: true,
                      color: AppColors.black,
                    ),
                    const SizedBox(height: 12),
                    ...widget.compound.sales
                        .map(
                          (sale) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor.withOpacity(0.08),
                                  AppColors.mainColor.withOpacity(0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mainColor.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Sales Avatar
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.mainColor.withOpacity(0.2),
                                          AppColors.mainColor.withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: AppColors.mainColor.withOpacity(
                                          0.3,
                                        ),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.mainColor
                                              .withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child:
                                        sale.image != null &&
                                            sale.image!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              sale.image!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Center(
                                                      child: CustomText20(
                                                        sale.name.isNotEmpty
                                                            ? sale.name[0]
                                                                  .toUpperCase()
                                                            : 'S',
                                                        bold: true,
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          )
                                        : Center(
                                            child: CustomText20(
                                              sale.name.isNotEmpty
                                                  ? sale.name[0].toUpperCase()
                                                  : 'S',
                                              bold: true,
                                              color: AppColors.mainColor,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Sales Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomText18(
                                                sale.name,
                                                bold: true,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            if (sale.isVerified == '1')
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.verified,
                                                      size: 14,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.verified,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: AppColors.mainColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: CustomText16(
                                                sale.phone,
                                                bold: true,
                                                color: AppColors.mainColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (sale.email.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.email_outlined,
                                                size: 16,
                                                color: AppColors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: CustomText16(
                                                  sale.email,
                                                  color: AppColors.grey,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Contact Action Button
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.mainColor.withOpacity(0.2),
                                          AppColors.mainColor.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.phone,
                                        color: AppColors.mainColor,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.calling2(sale.name),
                                            ),
                                            backgroundColor:
                                                AppColors.mainColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 24),
                  ],

                  // Ratings & Reviews Section with Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText20(
                        l10n.ratingsReviews,
                        bold: true,
                        color: AppColors.black,
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showReviews = !_showReviews;
                          });
                        },
                        icon: Icon(
                          _showReviews ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        label: Text(
                          _showReviews ? l10n.hideReviews : l10n.showReviews,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reviews Container (conditionally shown)
                  if (_showReviews)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.mainColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- User Rating Section ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor.withOpacity(0.08),
                                  AppColors.mainColor.withOpacity(0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mainColor.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.rate_review,
                                      color: AppColors.mainColor,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomText18(
                                      l10n.rateThisCompound,
                                      bold: true,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: StarRating(
                                    rating: _userRating,
                                    onChanged: (rating) {
                                      setState(() {
                                        _userRating = rating;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.youRatedStars(_userRating),
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: AppColors.mainColor,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_userRating > 0) ...[
                                  const SizedBox(height: 12),
                                  Center(
                                    child: CustomText16(
                                      _userRating == 5
                                          ? l10n.excellent
                                          : _userRating == 4
                                          ? l10n.veryGood
                                          : _userRating == 3
                                          ? l10n.good
                                          : _userRating == 2
                                          ? l10n.fair
                                          : l10n.needsImprovement,
                                      color: AppColors.mainColor,
                                      bold: true,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // --- Overall Rating Summary ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor.withOpacity(0.15),
                                  AppColors.mainColor.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mainColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '4.7',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                    StaticStars(rating: 5, size: 20),
                                    const SizedBox(height: 4),
                                    CustomText16(
                                      '${_reviews.length} ${l10n.reviews}',
                                      color: AppColors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: const [
                                      RatingBar(stars: '5', percentage: 0.8),
                                      RatingBar(stars: '4', percentage: 0.15),
                                      RatingBar(stars: '3', percentage: 0.03),
                                      RatingBar(stars: '2', percentage: 0.01),
                                      RatingBar(stars: '1', percentage: 0.01),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // --- Reviews List ---
                          CustomText18(
                            l10n.userReviews,
                            bold: true,
                            color: AppColors.black,
                          ),
                          const SizedBox(height: 12),
                          // Display all reviews
                          ..._reviews
                              .map((review) => ReviewCard(review: review))
                              .toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Search Tile for Units
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mainColor.withOpacity(0.08),
                          AppColors.mainColor.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mainColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchUnits,
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.mainColor,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppColors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: AppColors.black, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomText20(
                    l10n.availableUnits,
                    bold: true,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 16),
                  // Units List
                  BlocBuilder<UnitBloc, UnitState>(
                    builder: (context, state) {
                      if (state is UnitLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (state is UnitSuccess) {
                        final allUnits = state.response.data;

                        // Filter units based on search query
                        final units = _searchQuery.isEmpty
                            ? allUnits
                            : allUnits.where((unit) {
                                final unitNumber = (unit.unitNumber ?? '')
                                    .toLowerCase();
                                final unitType = (unit.unitType ?? '')
                                    .toLowerCase();
                                final usageType = (unit.usageType ?? '')
                                    .toLowerCase();
                                final area = (unit.area ?? '').toLowerCase();
                                final status = (unit.status ?? '')
                                    .toLowerCase();
                                final floor = (unit.floor ?? '').toLowerCase();
                                final bedrooms = (unit.bedrooms ?? '')
                                    .toLowerCase();

                                return unitNumber.contains(_searchQuery) ||
                                    unitType.contains(_searchQuery) ||
                                    usageType.contains(_searchQuery) ||
                                    area.contains(_searchQuery) ||
                                    status.contains(_searchQuery) ||
                                    floor.contains(_searchQuery) ||
                                    bedrooms.contains(_searchQuery);
                              }).toList();

                        if (units.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 80,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomText18(
                                    _searchQuery.isEmpty
                                        ? l10n.noUnitsAvailable
                                        : l10n.noUnitsMatch,
                                    color: AppColors.grey,
                                    bold: true,
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    CustomText16(
                                      l10n.tryDifferentKeywords,
                                      color: AppColors.grey,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        final displayCount = _showAllUnits
                            ? units.length
                            : (units.length > 5 ? 5 : units.length);

                        return Column(
                          children: [
                            ...units
                                .take(displayCount)
                                .map((unit) => UnitCard(unit: unit))
                                .toList(),
                            if (units.length > 5) ...[
                              const SizedBox(height: 16),
                              ShowAllButton(
                                label: _showAllUnits
                                    ? l10n.showLess
                                    : l10n.showAllUnits,
                                pressed: () {
                                  setState(() {
                                    _showAllUnits = !_showAllUnits;
                                  });
                                },
                              ),
                            ],
                          ],
                        );
                      } else if (state is UnitError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                CustomText16(
                                  '${l10n.error}: ${state.message}',
                                  color: Colors.red,
                                  align: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    foregroundColor: AppColors.white,
                                  ),
                                  onPressed: () {
                                    context.read<UnitBloc>().add(
                                      FetchUnitsEvent(
                                        compoundId: widget.compound.id,
                                        limit: 100,
                                      ),
                                    );
                                  },
                                  child: CustomText16(
                                    l10n.retry,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
