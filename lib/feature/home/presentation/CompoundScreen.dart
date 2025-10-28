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
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widget/button/showAll.dart';
import '../../compound/presentation/bloc/unit/unit_bloc.dart';
import '../../compound/presentation/bloc/unit/unit_event.dart';
import '../../compound/presentation/bloc/unit/unit_state.dart';
import '../../compound/presentation/widget/unit_card.dart';
import '../../compound/data/web_services/compound_web_services.dart';
import '../../sale/data/models/sale_model.dart';
import '../../sale/presentation/widgets/sales_person_selector.dart';
import '../../notifications/presentation/screens/notifications_screen.dart';
import '../../company/data/web_services/company_web_services.dart';
import '../../company/data/models/company_user_model.dart';
import '../../search/data/services/view_history_service.dart';

class CompoundScreen extends StatefulWidget {
  static String routeName = '/compund';
  final Compound compound;

  CompoundScreen({super.key, required this.compound});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _userRating = 0; // User's rating (0-5)
  bool _showAllUnits = false;
  bool _showReviews = false; // Control reviews visibility
  bool _showFullDescription = false; // Control description expansion
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _imagePageController = PageController();
  Timer? _imageSliderTimer;
  final CompoundWebServices _compoundWebServices = CompoundWebServices();
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  late TabController _tabController;
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
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

    // Track view history
    ViewHistoryService().addViewedCompound(widget.compound);

    // Initialize TabController with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

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

    // Fetch sales people from company
    _fetchSalesPeople();

    // Start auto-slider if there are multiple images
    if (widget.compound.images.length > 1) {
      _imageSliderTimer = Timer.periodic(Duration(seconds: 4), (timer) {
        if (_imagePageController.hasClients) {
          int nextPage =
              (_currentImageIndex + 1) % widget.compound.images.length;
          _imagePageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _fetchSalesPeople() async {
    if (_isLoadingSalesPeople) return;

    setState(() {
      _isLoadingSalesPeople = true;
    });

    try {
      final companyData = await _companyWebServices.getCompanyById(widget.compound.companyId);

      print('[COMPOUND SCREEN] Company data: $companyData');

      if (companyData['users'] != null && companyData['users'] is List) {
        final allUsers = (companyData['users'] as List)
            .map((user) => CompanyUser.fromJson(user as Map<String, dynamic>))
            .toList();

        // Filter only sales people
        final salesPeople = allUsers.where((user) => user.isSales).toList();

        print('[COMPOUND SCREEN] Found ${salesPeople.length} sales people');

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
      print('[COMPOUND SCREEN] Error fetching sales people: $e');
      if (mounted) {
        setState(() {
          _isLoadingSalesPeople = false;
        });
      }
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

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    // Don't display if value is "0" or "0.00" or empty
    if (value == "0" || value == "0.00" || value.isEmpty || value == "null") {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
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
          Expanded(flex: 3, child: CustomText16(value, color: AppColors.greyText)),
        ],
      ),
    );
  }

  // Description Section Widget
  Widget _buildDescriptionSection(AppLocalizations l10n) {
    final description = widget.compound.finishSpecs ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.mainColor, size: 20),
              SizedBox(width: 8),
              CustomText18(
                l10n.finishSpecs,
                bold: true,
                color: AppColors.black,
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            maxLines: _showFullDescription ? null : 5,
            overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyText,
              height: 1.5,
            ),
          ),
          if (description.length > 200) // Only show button if text is long enough
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFullDescription = !_showFullDescription;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _showFullDescription ? l10n.showLess : l10n.showAll,
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      _showFullDescription
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.mainColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Details Tab Content
  Widget _buildDetailsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Section with Finish Specs
          if (widget.compound.finishSpecs != null && widget.compound.finishSpecs!.isNotEmpty)
            _buildDescriptionSection(l10n),
          SizedBox(height: 16),

          // Other Details
          if (widget.compound.availableUnits != "0")
            _buildInfoRow(
              l10n.availableUnits,
              widget.compound.availableUnits,
            ),
          _buildInfoRow(l10n.status, widget.compound.status.toUpperCase()),
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
          _buildInfoRow(
            l10n.hasClub,
            widget.compound.club == "1" ? l10n.yes : l10n.no,
          ),
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
        ],
      ),
    );
  }

  // Gallery Tab Content
  Widget _buildGalleryTab() {
    if (widget.compound.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: AppColors.grey),
            SizedBox(height: 16),
            CustomText16('No images available', color: AppColors.grey),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.compound.images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: RobustNetworkImage(
            imageUrl: widget.compound.images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: AppColors.grey),
            ),
          ),
        );
      },
    );
  }

  // Map Tab Content
  Widget _buildMapTab(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 80, color: AppColors.mainColor),
          SizedBox(height: 16),
          CustomText16(
            widget.compound.location,
            bold: true,
            color: AppColors.black,
            align: TextAlign.center,
          ),
          SizedBox(height: 8),
          if (widget.compound.locationUrl != null &&
              widget.compound.locationUrl!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final Uri mapUri = Uri.parse(widget.compound.locationUrl!);
                if (await canLaunchUrl(mapUri)) {
                  await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(Icons.directions, size: 20),
              label: CustomText16('Open in Maps', color: AppColors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            CustomText16(
              'Map location not available',
              color: AppColors.grey,
            ),
        ],
      ),
    );
  }

  // Master Plan Tab Content
  Widget _buildMasterPlanTab(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 80, color: AppColors.mainColor),
          SizedBox(height: 16),
          CustomText16(
            'Master Plan',
            bold: true,
            color: AppColors.black,
          ),
          SizedBox(height: 8),
          CustomText16(
            'Master plan details coming soon',
            color: AppColors.grey,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Sales People Section
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
          color: AppColors.black,
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
                  color: AppColors.black,
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
                  onPressed: () => _launchPhone(salesPerson.phone!),
                  icon: Icon(Icons.phone, color: AppColors.mainColor),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(height: 8),
                IconButton(
                  onPressed: () => _launchWhatsApp(salesPerson.phone!),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = widget.compound.images.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider Section
            Stack(
              children: [
                // Image Slider
                hasImages
                    ? SizedBox(
                        height: 280,
                        child: PageView.builder(
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
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.mainColor,
                                  ),
                                ),
                              ),
                              errorBuilder: (context, url) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    : Container(
                        height: 280,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: AppColors.grey,
                          ),
                        ),
                      ),

                // Back Button
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Dot Indicators (only show if multiple images)
                if (hasImages && widget.compound.images.length > 1)
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
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),

            // About Section
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compound Name
                  CustomText20(
                    'About ${widget.compound.project}',
                    bold: true,
                    color: AppColors.black,
                  ),
                  SizedBox(height: 12),

                  // Compound Description
                  CustomText16(
                    widget.compound.project.isNotEmpty
                        ? '${widget.compound.project} is located in ${widget.compound.location} at El Riviera Real Estate Company. Available units with various sizes and types.'
                        : 'Premium real estate compound with modern amenities and facilities.',
                    color: AppColors.greyText,
                  ),
                  SizedBox(height: 20),

                  // Developer Start Price (calculate from available units)
                  BlocBuilder<UnitBloc, UnitState>(
                    builder: (context, state) {
                      String developerStartPrice = '6,000,000 EGP'; // Default value

                      if (state is UnitSuccess && state.response.data.isNotEmpty) {
                        // Find the minimum price from units
                        try {
                          final prices = state.response.data
                              .where((unit) => unit.price != null && unit.price!.isNotEmpty)
                              .map((unit) => double.tryParse(unit.price!) ?? 0)
                              .where((price) => price > 0)
                              .toList();

                          if (prices.isNotEmpty) {
                            final minPrice = prices.reduce((a, b) => a < b ? a : b);
                            developerStartPrice = '${minPrice.toStringAsFixed(0)} EGP';
                          }
                        } catch (e) {
                          print('Error calculating developer start price: $e');
                        }
                      }

                      return Row(
                        children: [
                          CustomText16(
                            'Developer Start Price',
                            bold: true,
                            color: AppColors.black,
                          ),
                          Spacer(),
                          CustomText18(
                            developerStartPrice,
                            bold: true,
                            color: AppColors.mainColor,
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24),

                  // Call Us and WhatsApp Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.compound.sales.isNotEmpty) {
                              final phone = widget.compound.sales.first.phone;
                              _launchPhone(phone);
                            } else {
                              _showSalespeople();
                            }
                          },
                          icon: Icon(Icons.phone, size: 20),
                          label: CustomText16('Call Us', color: AppColors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.compound.sales.isNotEmpty) {
                              final phone = widget.compound.sales.first.phone;
                              _launchWhatsApp(phone);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.noSalesPersonAvailable),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.chat, size: 20),
                          label: CustomText16('WhatsApp', color: AppColors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
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
                        Tab(text: 'Details'),
                        Tab(text: 'Gallery'),
                        Tab(text: 'View on Map'),
                        Tab(text: 'Master Plan'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Tab Content
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Details Tab
                        _buildDetailsTab(l10n),

                        // Gallery Tab
                        _buildGalleryTab(),

                        // View on Map Tab
                        _buildMapTab(l10n),

                        // Master Plan Tab
                        _buildMasterPlanTab(l10n),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Sales People Section
                  _buildSalesPeopleSection(l10n),

                  // Explore Properties Section
                  CustomText20(
                    'Explore Properties In ${widget.compound.project}',
                    bold: true,
                    color: AppColors.black,
                  ),
                  SizedBox(height: 16),
                  // Units List
                  BlocBuilder<UnitBloc, UnitState>(
                    builder: (context, state) {
                      if (state is UnitLoading) {
                        return Center(
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
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 80,
                                    color: AppColors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  CustomText18(
                                    _searchQuery.isEmpty
                                        ? l10n.noUnitsAvailable
                                        : l10n.noUnitsMatch,
                                    color: AppColors.grey,
                                    bold: true,
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    SizedBox(height: 8),
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
                            : (units.length > 6 ? 6 : units.length);

                        return Column(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: displayCount,
                              itemBuilder: (context, index) {
                                return UnitCard(unit: units[index]);
                              },
                            ),
                            if (units.length > 6) ...[
                              SizedBox(height: 16),
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
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                CustomText16(
                                  '${l10n.error}: ${state.message}',
                                  color: Colors.red,
                                  align: TextAlign.center,
                                ),
                                SizedBox(height: 16),
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
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ]),

      ),
    );
  }
}
