import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../compound/presentation/bloc/favorite/compound_favorite_event.dart';
import '../../compound/presentation/bloc/favorite/compound_favorite_state.dart';
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
import '../../../core/animations/animated_list_item.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/core/utils/message_helper.dart';
import '../../../core/widgets/zoomable_image_viewer.dart';
import '../../compound/data/web_services/favorites_web_services.dart';
import '../../../core/widgets/note_dialog.dart';
import '../../compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

class CompoundScreen extends StatefulWidget {
  static String routeName = '/compund';
  final Compound compound;

  CompoundScreen({super.key, required this.compound});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _userRating = 0; // User's rating (0-5)
  int _unitsDisplayCount = 10;
  final ScrollController _unitsScrollController = ScrollController();
  bool _isLoadingMoreUnits = false;
  bool _showReviews = false; // Control reviews visibility
  bool _showFullDescription = false; // Control description expansion
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _imagePageController = PageController();
  Timer? _imageSliderTimer;

  final CompoundWebServices _compoundWebServices = CompoundWebServices();
  final CompanyWebServices _companyWebServices = CompanyWebServices();
  final FavoritesWebServices _favoritesWebServices = FavoritesWebServices();

  late TabController _tabController;
  List<CompanyUser> _salesPeople = [];
  bool _isLoadingSalesPeople = false;
  List<Map<String, dynamic>> _notes = [];

  // Detailed compound data (fetched from API)
  late Compound _compound;
  bool _isLoadingCompoundDetails = false;

  @override
  void initState() {
    super.initState();

    // Initialize with widget compound, will be updated with detailed data
    _compound = widget.compound;

    // Track view history
    ViewHistoryService().addViewedCompound(widget.compound);

    // Initialize TabController with 6 tabs (including Units and Notes)
    _tabController = TabController(length: 6, vsync: this);

    // Add animation listener for tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Show notification message if there are updated units
    if (widget.compound.updatedUnitsCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateNotification();
      });
    }

    // Debug: Print image count and URLs
    print('==========================================');
    print('[COMPOUND SCREEN] Compound: ${widget.compound.project}');
    print('[COMPOUND SCREEN] Total images: ${widget.compound.images.length}');
    for (int i = 0; i < widget.compound.images.length; i++) {
      print('[COMPOUND SCREEN] Image $i: ${widget.compound.images[i]}');
    }
    print('==========================================');

    // Fetch detailed compound data from API
    _fetchCompoundDetails();

    // Fetch units for this compound
    context.read<UnitBloc>().add(
      FetchUnitsEvent(compoundId: widget.compound.id, limit: 100),
    );

    // Fetch sales people from company
    _fetchSalesPeople();

    // Fetch compound notes
    _fetchCompoundNote();

    // Add scroll listener for units pagination
    _unitsScrollController.addListener(_onUnitsScroll);

    // Start auto-slider if there are multiple images
    if (widget.compound.images.length > 1) {
      _imageSliderTimer = Timer.periodic(Duration(seconds: 4), (timer) {
        if (_imagePageController.hasClients) {
          int nextPage =
              (_currentImageIndex + 1) % _compound.images.length;
          _imagePageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _fetchCompoundDetails() async {
    if (_isLoadingCompoundDetails) return;

    setState(() {
      _isLoadingCompoundDetails = true;
    });

    try {
      print('[COMPOUND SCREEN] Fetching detailed data for compound ${widget.compound.id}');
      final response = await _compoundWebServices.getCompoundById(widget.compound.id);

      print('[COMPOUND SCREEN] Compound detail response: $response');

      if (response['success'] == true && response['data'] != null) {
        final compoundData = response['data'] as Map<String, dynamic>;
        final detailedCompound = Compound.fromJson(compoundData);

        if (mounted) {
          setState(() {
            _compound = detailedCompound;
            _isLoadingCompoundDetails = false;
          });

          // Update image slider if images changed
          if (_compound.images.length > 1 && _imageSliderTimer == null) {
            _imageSliderTimer = Timer.periodic(Duration(seconds: 4), (timer) {
              if (_imagePageController.hasClients) {
                int nextPage = (_currentImageIndex + 1) % _compound.images.length;
                _imagePageController.animateToPage(
                  nextPage,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            });
          }

          print('[COMPOUND SCREEN] Updated compound with detailed data');
          print('[COMPOUND SCREEN] finishSpecs: ${_compound.finishSpecs}');
          print('[COMPOUND SCREEN] landArea: ${_compound.landArea}');
          print('[COMPOUND SCREEN] builtArea: ${_compound.builtArea}');
          print('[COMPOUND SCREEN] locationUrl: ${_compound.locationUrl}');
        }
      } else {
        print('[COMPOUND SCREEN] No detailed data in response');
        if (mounted) {
          setState(() {
            _isLoadingCompoundDetails = false;
          });
        }
      }
    } catch (e) {
      print('[COMPOUND SCREEN] Error fetching compound details: $e');
      if (mounted) {
        setState(() {
          _isLoadingCompoundDetails = false;
        });
      }
    }
  }

  void _showUpdateNotification() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final String detailMessage =
    _compound.latestUpdateNote != null &&
        _compound.latestUpdateNote!.isNotEmpty
        ? '${_compound.latestUpdateNote}'
        : '${_compound.updatedUnitsCount} ${_compound.updatedUnitsCount == 1 ? "unit has" : "units have"} been updated';

    final String fullMessage = 'New Updates Available! $detailMessage';

    MessageHelper.showMessage(
      context: context,
      message: fullMessage,
      isSuccess: false,
    );
  }

  void _onUnitsScroll() {
    if (_isLoadingMoreUnits) return;

    final maxScroll = _unitsScrollController.position.maxScrollExtent;
    final currentScroll = _unitsScrollController.position.pixels;

    // Load more when 80% scrolled (for GridView this works well)
    if (currentScroll >= maxScroll * 0.8) {
      setState(() {
        _isLoadingMoreUnits = true;
        _unitsDisplayCount += 10;
      });

      // Small delay to show loading indicator
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoadingMoreUnits = false;
          });
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
    _unitsScrollController.dispose();
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

  void _shareCompound() {
    // Get current units from bloc state
    final unitState = context.read<UnitBloc>().state;
    List<Map<String, dynamic>>? units;

    if (unitState is UnitSuccess) {
      // Convert units to map format for AdvancedShareBottomSheet
      units = unitState.response.data.map((unit) => {
        'id': unit.id,
        'unit_name': unit.unitNumber ?? 'Unit ${unit.id}',
        'unit_code': unit.code ?? unit.unitNumber,
        'unit_type': unit.unitType,
        'number_of_beds': unit.bedrooms,
        'built_up_area': unit.builtUpArea ?? unit.area,
        'land_area': unit.landArea,
        'garden_area': unit.gardenArea,
        'normal_price': unit.price,
        'status': unit.status,
      }).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedShareBottomSheet(
        type: 'compound',
        id: _compound.id,
        units: units,
      ),
    );
  }

  Future<void> _fetchSalesPeople() async {
    if (_isLoadingSalesPeople) return;

    setState(() {
      _isLoadingSalesPeople = true;
    });

    try {
      final companyData =
      await _companyWebServices.getCompanyById(_compound.companyId);
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
      final response = await _compoundWebServices
          .getSalespeopleByCompound(_compound.project);

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
          MessageHelper.showMessage(
            context: context,
            message: AppLocalizations.of(context)!.noSalesPersonAvailable,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
            context, '${AppLocalizations.of(context)!.error}: $e');
      }
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        MessageHelper.showError(context, 'Could not launch phone call');
      }
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        MessageHelper.showError(context, 'Could not launch WhatsApp');
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
          Expanded(
              flex: 3, child: CustomText16(value, color: Colors.black)),
        ],
      ),
    );
  }

  // Description Section Widget
  Widget _buildDescriptionSection(AppLocalizations l10n) {
    final description = _compound.finishSpecs ?? '';

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
        mainAxisSize: MainAxisSize.min,
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
            overflow: _showFullDescription
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.5,
            ),
          ),
          if (description.length >
              200) // Only show button if text is long enough
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



  Widget _buildUnitStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          CustomText14(label, color: Colors.black),
          SizedBox(height: 4),
          CustomText20(value, bold: true, color: color),
        ],
      ),
    );
  }

  // Details Tab Content
  Widget _buildDetailsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Section with Finish Specs
          if (_compound.finishSpecs != null &&
              _compound.finishSpecs!.isNotEmpty)
            _buildDescriptionSection(l10n),
          SizedBox(height: 16),
          // Other Details
          if (_compound.availableUnits != "0")
            _buildInfoRow(
              l10n.availableUnits,
              _compound.availableUnits,
            ),
          _buildInfoRow(l10n.status, _compound.status.toUpperCase()),
          if (_compound.builtUpArea != "0.00")
            _buildInfoRow(
              l10n.builtUpArea,
              "${_compound.builtUpArea} ${l10n.sqm}",
            ),
          if (_compound.builtArea != null &&
              _compound.builtArea != "0.00")
            _buildInfoRow(
              l10n.builtArea,
              "${_compound.builtArea} ${l10n.sqm}",
            ),
          if (_compound.landArea != null &&
              _compound.landArea != "0.00")
            _buildInfoRow(
              l10n.landArea,
              "${_compound.landArea} ${l10n.sqm}",
            ),
          if (_compound.howManyFloors != "0")
            _buildInfoRow(
              l10n.numberOfFloors,
              _compound.howManyFloors,
            ),
          _buildInfoRow(
            l10n.hasClub,
            _compound.club == "1" ? l10n.yes : l10n.no,
          ),
          if (_compound.plannedDeliveryDate != null)
            _buildInfoRow(
              l10n.plannedDelivery,
              _formatDate(_compound.plannedDeliveryDate!),
            ),
          if (_compound.actualDeliveryDate != null)
            _buildInfoRow(
              l10n.actualDelivery,
              _formatDate(_compound.actualDeliveryDate!),
            ),
          if (_compound.completionProgress != null)
            _buildInfoRow(
              l10n.completionProgress,
              "${_compound.completionProgress}%",
            ),
          SizedBox(height: 24),
          // Unit Summary Section
         // _buildUnitSummarySection(l10n),
        ],
      ),
    );
  }

  // Gallery Tab Content
  Widget _buildGalleryTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_compound.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: AppColors.grey),
            SizedBox(height: 16),
            CustomText16(l10n.noImagesAvailable, color: Colors.black),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _compound.images.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delay: Duration(milliseconds: 60),
          child: GestureDetector(
            onTap: () {
              // Open zoomable image viewer
              ZoomableImageViewer.show(
                context,
                images: _compound.images,
                initialIndex: index,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RobustNetworkImage(
                imageUrl: _compound.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, color: AppColors.grey),
                ),
              ),
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
            _compound.location,
            bold: true,
            color: AppColors.black,
            align: TextAlign.center,
          ),
          SizedBox(height: 8),
          if (_compound.locationUrl != null &&
              _compound.locationUrl!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final Uri mapUri = Uri.parse(_compound.locationUrl!);
                if (await canLaunchUrl(mapUri)) {
                  await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(Icons.directions, size: 20),
              label: CustomText16(l10n.openInMaps, color: AppColors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            CustomText16(
              l10n.mapLocationNotAvailable,
              color: AppColors.greyText,
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
            l10n.masterPlan,
            bold: true,
            color: AppColors.black,
          ),
          SizedBox(height: 8),
          CustomText16(
            l10n.masterPlanComingSoon,
            color: Colors.black,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Units Tab Content
  Widget _buildUnitsTab(AppLocalizations l10n) {
    return BlocBuilder<UnitBloc, UnitState>(
      builder: (context, state) {
        if (state is UnitLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CustomLoadingDots(size: 80),
            ),
          );
        } else if (state is UnitSuccess) {
          final allUnits = state.response.data;

          // Filter units based on search query
          final units = _searchQuery.isEmpty
              ? allUnits
              : allUnits.where((unit) {
            final unitNumber = (unit.unitNumber ?? '').toLowerCase();
            final unitType = (unit.unitType ?? '').toLowerCase();
            final usageType = (unit.usageType ?? '').toLowerCase();
            final area = (unit.area ?? '').toLowerCase();
            final status = (unit.status ?? '').toLowerCase();
            final floor = (unit.floor ?? '').toLowerCase();
            final bedrooms = (unit.bedrooms ?? '').toLowerCase();

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
                  mainAxisSize: MainAxisSize.min,
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
                      color: AppColors.greyText,
                      bold: true,
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      SizedBox(height: 8),
                      CustomText16(
                        l10n.tryDifferentKeywords,
                        color: AppColors.greyText,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Use pagination - show up to _unitsDisplayCount items
          final displayCount = units.length > _unitsDisplayCount
              ? _unitsDisplayCount
              : units.length;

          return SingleChildScrollView(
            controller: _unitsScrollController,
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    return AnimatedListItem(
                      index: index,
                      delay: Duration(milliseconds: 80),
                      child: UnitCard(unit: units[index]),
                    );
                  },
                ),
                // Show loading indicator when loading more
                if (_isLoadingMoreUnits && displayCount < units.length) ...[
                  SizedBox(height: 16),
                  CustomLoadingDots(size: 40),
                  SizedBox(height: 16),
                ],
              ],
            ),
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
                          compoundId: _compound.id,
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
    );
  }

  // Sales People Section
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
          l10n.contactSalesTeam,
          bold: true,
          color: AppColors.black,
        ),
        SizedBox(height: 12),
        CustomText16(
          l10n.getInTouchWithSales,
          color: Colors.black,
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
                        color: Colors.black,
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
                        color: AppColors.greyText,
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

  // Notes Tab
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
                      color: Colors.black,
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
              l10n.addYourPersonalNotesCompound,
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
                          color: Colors.black,
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

  Future<void> _fetchCompoundNote() async {
    try {
      print('[COMPOUND SCREEN] Fetching notes for compound ${_compound.id}');
      final response = await _favoritesWebServices.getNotes(
        compoundId: int.parse(_compound.id),
      );

      print('[COMPOUND SCREEN] getNotes response: $response');

      // New API structure: response['data']['notes']
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['notes'] != null) {
          final notes = data['notes'] as List;
          print('[COMPOUND SCREEN] Found ${notes.length} notes');
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
          print('[COMPOUND SCREEN] Loaded ${_notes.length} notes');
        } else {
          print('[COMPOUND SCREEN] Notes field is null');
        }
      } else {
        print('[COMPOUND SCREEN] No notes in response or success=false');
      }
    } catch (e) {
      print('[COMPOUND SCREEN] Error fetching compound notes: $e');
    }
  }

  Future<void> _showNoteDialog({
    int? noteId,
    String? initialContent,
    String? initialTitle,
  }) async
  {
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
          print('[COMPOUND SCREEN] Updating note $noteId');
          response = await _favoritesWebServices.updateNote(
            noteId: noteId,
            content: result,
            title: initialTitle ?? l10n.compoundNote,
          );
        } else {
          // Create new note
          print('[COMPOUND SCREEN] Creating new note for compound ${_compound.id}');
          response = await _favoritesWebServices.createNote(
            content: result,
            title: l10n.compoundNote,
            compoundId: int.tryParse(_compound.id),
          );
        }

        print('[COMPOUND SCREEN] Note save response: $response');

        if (mounted) {
          MessageHelper.showMessage(
            context: context,
            message: l10n.noteSavedSuccessfully,
            isSuccess: true,
          );

          // Reload notes to show updated list
          await _fetchCompoundNote();
        }

        // Trigger bloc refresh to reload favorites
        if (mounted) {
          context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
        }
      } catch (e) {
        print('[COMPOUND SCREEN] Error saving note: $e');
        if (mounted) {
          MessageHelper.showMessage(
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
        print('[COMPOUND SCREEN] Deleting note $noteId');
        final response = await _favoritesWebServices.deleteNote(noteId);

        print('[COMPOUND SCREEN] Delete note response: $response');

        if (mounted) {
          MessageHelper.showMessage(
            context: context,
            message: l10n.noteDeletedSuccessfully,
            isSuccess: true,
          );

          // Reload notes to show updated list
          await _fetchCompoundNote();
        }

        // Trigger bloc refresh
        if (mounted) {
          context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
        }
      } catch (e) {
        print('[COMPOUND SCREEN] Error deleting note: $e');
        if (mounted) {
          MessageHelper.showMessage(
            context: context,
            message: l10n.failedToDeleteNote,
            isSuccess: false,
          );
        }
      }
    }
  }

  // Tab Bar
  Widget _buildCornerTabBar() {
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
          Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Details'),
          Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: 'Gallery'),
          Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Map'),
          Tab(icon: Icon(Icons.architecture_outlined, size: 18), text: 'Master Plan'),
          Tab(icon: Icon(Icons.home_work_outlined, size: 18), text: 'Units'),
          Tab(icon: Icon(Icons.note_outlined, size: 18), text: 'Notes'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = _compound.images.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
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
                  child: GestureDetector(
                    onTap: () {
                      // Open zoomable image viewer
                      ZoomableImageViewer.show(
                        context,
                        images: _compound.images,
                        initialIndex: _currentImageIndex,
                      );
                    },
                    child: PageView.builder(
                      controller: _imagePageController,
                      itemCount: _compound.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return RobustNetworkImage(
                          imageUrl: _compound.images[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CustomLoadingDots(size: 80),
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        print('[COMPOUND SCREEN] Back button tapped');
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 48,
                        height: 48,
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
                        child: Icon(Icons.arrow_back, color: AppColors.black),
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 40,
                  right: 72,
                  child: BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                    builder: (context, state) {
                      bool isFavorite = false;
                      if (state is CompoundFavoriteUpdated) {
                        isFavorite = state.favorites.any((c) => c.id == _compound.id);
                      }
                      return Container(
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
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.mainColor,
                          ),
                          onPressed: () {
                            if (isFavorite) {
                              context.read<CompoundFavoriteBloc>().add(
                                RemoveFavoriteCompound(_compound),
                              );
                            } else {
                              context.read<CompoundFavoriteBloc>().add(
                                AddFavoriteCompound(_compound),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Share Button
                Positioned(
                  top: 40,
                  right: 16,
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
                      icon: Icon(Icons.share, color: AppColors.mainColor),
                      onPressed: _shareCompound,
                    ),
                  ),
                ),
                // Dot Indicators (only show if multiple images) - positioned at center bottom
                if (hasImages && _compound.images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _compound.images.length,
                                (index) {
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == index ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: _currentImageIndex == index
                                      ? AppColors.mainColor
                                      : Colors.white.withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ),
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
                  CustomText18(
                    'About ${_compound.project}',
                    bold: true,
                    color: AppColors.black,
                  ),
                  SizedBox(height: 10),
                  // Compound Description
                  CustomText14(
                    _compound.project.isNotEmpty
                        ? '${_compound.project} is located in ${_compound.location} at ${_compound.companyName.isNotEmpty ? _compound.companyName : "El Riviera Real Estate Company"}. Available units with various sizes and types.'
                        : 'Premium real estate compound with modern amenities and facilities.',
                    color: Colors.black,
                  ),
                  SizedBox(height: 20),
                  // Developer Start Price (calculate from available units)
                  BlocBuilder<UnitBloc, UnitState>(
                    builder: (context, state) {
                      String developerStartPrice =
                          '6,000,000 EGP'; // Default value

                      if (state is UnitSuccess && state.response.data.isNotEmpty) {
                        // Find the minimum price from units
                        try {
                          final prices = state.response.data
                              .where((unit) =>
                          unit.price != null && unit.price!.isNotEmpty)
                              .map((unit) => double.tryParse(unit.price!) ?? 0)
                              .where((price) => price > 0)
                              .toList();

                          if (prices.isNotEmpty) {
                            final minPrice =
                            prices.reduce((a, b) => a < b ? a : b);
                            developerStartPrice =
                            '${minPrice.toStringAsFixed(0)} EGP';
                          }
                        } catch (e) {
                          print('Error calculating developer start price: $e');
                        }
                      }

                      return Row(
                        children: [
                          CustomText14(
                            'Developer Start Price',
                            bold: true,
                            color: AppColors.black,
                          ),
                          Spacer(),
                          CustomText16(
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
                            if (_compound.sales.isNotEmpty) {
                              final phone = _compound.sales.first.phone;
                              _launchPhone(phone);
                            } else {
                              _showSalespeople();
                            }
                          },
                          icon: Icon(Icons.phone, size: 18),
                          label: CustomText14('Call Us', color: AppColors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
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
                            if (_compound.sales.isNotEmpty) {
                              final phone = _compound.sales.first.phone;
                              _launchWhatsApp(phone);
                            } else {
                              MessageHelper.showMessage(
                                context: context,
                                message: l10n.noSalesPersonAvailable,
                                isSuccess: false,
                              );
                            }
                          },
                          icon: Icon(Icons.chat, size: 18),
                          label: CustomText14('WhatsApp', color: AppColors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Sales People Section
                  _buildSalesPeopleSection(l10n),
                  // Animated Corner Tab Bar
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildCornerTabBar(),
                  ),

                  SizedBox(height: 24),

                  // Animated Tab Content with fade and scale transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_tabController.index),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 300,
                        maxHeight: double.infinity,
                      ),
                      child: _tabController.index == 0
                          ? _buildDetailsTab(l10n)
                          : _tabController.index == 1
                          ? _buildGalleryTab()
                          : _tabController.index == 2
                          ? _buildMapTab(l10n)
                          : _tabController.index == 3
                          ? _buildMasterPlanTab(l10n)
                          : _tabController.index == 4
                          ? _buildUnitsTab(l10n)
                          : _buildNotesTab(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}