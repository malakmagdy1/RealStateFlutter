import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:intl/intl.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../data/models/search_filter_model.dart';
import '../../data/services/location_service.dart';
import '../../data/services/company_service.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilter initialFilter;
  final Function(SearchFilter) onApplyFilters;
  final bool enableRealTimeFilters;

  SearchFilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.onApplyFilters,
    this.enableRealTimeFilters = true,
  }) : super(key: key);

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  final LocationService _locationService = LocationService();
  final CompanyService _companyService = CompanyService();
  List<LocationFilterItem> _availableLocations = []; // List with localized names
  List<CompanyFilterItem> _availableCompanies = []; // List with localized names
  bool _isLoadingLocations = true;
  bool _isLoadingCompanies = true;
  Timer? _filterDebounceTimer;

  String? _selectedLocation;
  String? _selectedCompanyId;
  DateTime? _deliveredAtFrom;
  DateTime? _deliveredAtTo;
  bool? _hasBeenDelivered;
  String? _selectedPropertyType;
  int? _selectedBedrooms;
  String? _selectedFinishing;
  bool _hasClub = false;
  bool _hasRoof = false;
  bool _hasGarden = false;
  String? _selectedSortBy;

  // Payment plan filter state
  int? _selectedPaymentDuration;
  late TextEditingController _minMonthlyPaymentController;
  late TextEditingController _maxMonthlyPaymentController;

  // Payment duration options: 0 = Cash, others are years
  final List<int> paymentDurationOptions = [0, 5, 7, 10];

  final List<String> propertyTypes = [
    'Villa',
    'Apartment',
    'Duplex',
    'Studio',
    'Penthouse',
    'Townhouse',
  ];

  final List<int> bedroomOptions = [1, 2, 3, 4, 5, 6];

  final List<String> finishingOptions = [
    'Finished',
    'Semi Finished',
    'Not Finished',
  ];

  final Map<String, String> sortOptions = {
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'date_asc': 'Date: Oldest First',
    'date_desc': 'Date: Newest First',
  };

  @override
  void initState() {
    super.initState();

    // Initialize controllers - convert from full price to millions
    _minPriceController = TextEditingController(
      text: widget.initialFilter.minPrice != null
        ? (widget.initialFilter.minPrice! / 1000000).toString()
        : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilter.maxPrice != null
        ? (widget.initialFilter.maxPrice! / 1000000).toString()
        : '',
    );

    // Initialize payment plan controllers - use raw values
    _minMonthlyPaymentController = TextEditingController(
      text: widget.initialFilter.minMonthlyPayment != null
        ? widget.initialFilter.minMonthlyPayment!.toInt().toString()
        : '',
    );
    _maxMonthlyPaymentController = TextEditingController(
      text: widget.initialFilter.maxMonthlyPayment != null
        ? widget.initialFilter.maxMonthlyPayment!.toInt().toString()
        : '',
    );

    // Add listeners for price text fields
    _minPriceController.addListener(_applyFiltersWithDebounce);
    _maxPriceController.addListener(_applyFiltersWithDebounce);

    // Add listeners for payment plan text fields
    _minMonthlyPaymentController.addListener(_applyFiltersWithDebounce);
    _maxMonthlyPaymentController.addListener(_applyFiltersWithDebounce);

    // Set initial values
    _selectedLocation = widget.initialFilter.location;
    _selectedCompanyId = widget.initialFilter.companyId;
    _selectedPropertyType = widget.initialFilter.propertyType;
    _selectedBedrooms = widget.initialFilter.bedrooms;
    _selectedFinishing = widget.initialFilter.finishing;
    _hasClub = widget.initialFilter.hasClub ?? false;
    _hasRoof = widget.initialFilter.hasRoof ?? false;
    _hasGarden = widget.initialFilter.hasGarden ?? false;
    _selectedSortBy = widget.initialFilter.sortBy;
    _selectedPaymentDuration = widget.initialFilter.paymentPlanDuration;

    // Parse deliveredAtFrom date
    if (widget.initialFilter.deliveredAtFrom != null && widget.initialFilter.deliveredAtFrom!.isNotEmpty) {
      try {
        _deliveredAtFrom = DateTime.parse(widget.initialFilter.deliveredAtFrom!);
      } catch (e) {
        print('[FILTER] Could not parse deliveredAtFrom date: ${widget.initialFilter.deliveredAtFrom}');
      }
    }

    // Parse deliveredAtTo date
    if (widget.initialFilter.deliveredAtTo != null && widget.initialFilter.deliveredAtTo!.isNotEmpty) {
      try {
        _deliveredAtTo = DateTime.parse(widget.initialFilter.deliveredAtTo!);
      } catch (e) {
        print('[FILTER] Could not parse deliveredAtTo date: ${widget.initialFilter.deliveredAtTo}');
      }
    }

    // Set hasBeenDelivered
    _hasBeenDelivered = widget.initialFilter.hasBeenDelivered;

    // Load locations and companies from database
    _loadLocations();
    _loadCompanies();
  }

  Future<void> _loadLocations() async {
    print('[FILTER BOTTOM SHEET] ========================================');
    print('[FILTER BOTTOM SHEET] Loading locations...');
    try {
      final locations = await _locationService.getLocationsWithLocalization();
      print('[FILTER BOTTOM SHEET] ✓ Received ${locations.length} locations');
      print('[FILTER BOTTOM SHEET] Locations: ${locations.take(5).map((l) => l.location).join(", ")}${locations.length > 5 ? "..." : ""}');

      if (mounted) {
        setState(() {
          _availableLocations = locations;
          _isLoadingLocations = false;
        });
        print('[FILTER BOTTOM SHEET] ✓ UI updated with locations');
      }
    } catch (e) {
      print('[FILTER BOTTOM SHEET] ✗ Error loading locations: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
    print('[FILTER BOTTOM SHEET] ========================================');
  }

  Future<void> _loadCompanies() async {
    print('[FILTER BOTTOM SHEET] ========================================');
    print('[FILTER BOTTOM SHEET] Loading companies...');
    try {
      final companies = await _companyService.getCompaniesWithLocalization();
      print('[FILTER BOTTOM SHEET] ✓ Received ${companies.length} companies');
      print('[FILTER BOTTOM SHEET] Companies: ${companies.take(5).map((c) => c.name).join(", ")}${companies.length > 5 ? "..." : ""}');

      if (mounted) {
        setState(() {
          _availableCompanies = companies;
          _isLoadingCompanies = false;
        });
        print('[FILTER BOTTOM SHEET] ✓ UI updated with companies');
      }
    } catch (e) {
      print('[FILTER BOTTOM SHEET] ✗ Error loading companies: $e');
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
        });
      }
    }
    print('[FILTER BOTTOM SHEET] ========================================');
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minMonthlyPaymentController.dispose();
    _maxMonthlyPaymentController.dispose();
    _filterDebounceTimer?.cancel();
    super.dispose();
  }

  void _applyFiltersWithDebounce() {
    if (!widget.enableRealTimeFilters) return;

    // Cancel previous timer
    _filterDebounceTimer?.cancel();

    // Start new timer (400ms debounce like web)
    _filterDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _applyFiltersImmediately();
    });
  }

  void _applyFiltersImmediately() {
    // Format deliveredAtFrom as yyyy-MM-dd string
    String? deliveredAtFromStr;
    if (_deliveredAtFrom != null) {
      deliveredAtFromStr = DateFormat('yyyy-MM-dd').format(_deliveredAtFrom!);
    }

    // Format deliveredAtTo as yyyy-MM-dd string
    String? deliveredAtToStr;
    if (_deliveredAtTo != null) {
      deliveredAtToStr = DateFormat('yyyy-MM-dd').format(_deliveredAtTo!);
    }

    // Convert millions to full price (multiply by 1,000,000)
    final minPriceInMillions = _minPriceController.text.isEmpty
        ? null
        : double.tryParse(_minPriceController.text);
    final maxPriceInMillions = _maxPriceController.text.isEmpty
        ? null
        : double.tryParse(_maxPriceController.text);

    // Monthly payment - use raw values (no multiplication)
    final minMonthlyPayment = _minMonthlyPaymentController.text.isEmpty
        ? null
        : double.tryParse(_minMonthlyPaymentController.text);
    final maxMonthlyPayment = _maxMonthlyPaymentController.text.isEmpty
        ? null
        : double.tryParse(_maxMonthlyPaymentController.text);

    final filter = SearchFilter(
      location: _selectedLocation,
      companyId: _selectedCompanyId,
      minPrice: minPriceInMillions != null ? minPriceInMillions * 1000000 : null,
      maxPrice: maxPriceInMillions != null ? maxPriceInMillions * 1000000 : null,
      propertyType: _selectedPropertyType,
      bedrooms: _selectedBedrooms,
      finishing: _selectedFinishing,
      deliveredAtFrom: deliveredAtFromStr,
      deliveredAtTo: deliveredAtToStr,
      hasBeenDelivered: _hasBeenDelivered,
      hasClub: _hasClub ? true : null,
      hasRoof: _hasRoof ? true : null,
      hasGarden: _hasGarden ? true : null,
      sortBy: null, // Sort removed from filter bottom sheet
      // Payment plan filters
      paymentPlanDuration: _selectedPaymentDuration,
      minMonthlyPayment: minMonthlyPayment,
      maxMonthlyPayment: maxMonthlyPayment,
    );

    widget.onApplyFilters(filter);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedCompanyId = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _deliveredAtFrom = null;
      _deliveredAtTo = null;
      _hasBeenDelivered = null;
      _selectedPropertyType = null;
      _selectedBedrooms = null;
      _selectedFinishing = null;
      _hasClub = false;
      _hasRoof = false;
      _hasGarden = false;
      _selectedSortBy = null;
      // Clear payment plan filters
      _selectedPaymentDuration = null;
      _minMonthlyPaymentController.clear();
      _maxMonthlyPaymentController.clear();
    });
    _applyFiltersWithDebounce();
  }

  void _applyFilters() {
    // Format deliveredAtFrom as yyyy-MM-dd string
    String? deliveredAtFromStr;
    if (_deliveredAtFrom != null) {
      deliveredAtFromStr = DateFormat('yyyy-MM-dd').format(_deliveredAtFrom!);
    }

    // Format deliveredAtTo as yyyy-MM-dd string
    String? deliveredAtToStr;
    if (_deliveredAtTo != null) {
      deliveredAtToStr = DateFormat('yyyy-MM-dd').format(_deliveredAtTo!);
    }

    // Convert millions to full price (multiply by 1,000,000)
    final minPriceInMillions = _minPriceController.text.isEmpty
        ? null
        : double.tryParse(_minPriceController.text);
    final maxPriceInMillions = _maxPriceController.text.isEmpty
        ? null
        : double.tryParse(_maxPriceController.text);

    // Monthly payment - use raw values (no multiplication)
    final minMonthlyPayment = _minMonthlyPaymentController.text.isEmpty
        ? null
        : double.tryParse(_minMonthlyPaymentController.text);
    final maxMonthlyPayment = _maxMonthlyPaymentController.text.isEmpty
        ? null
        : double.tryParse(_maxMonthlyPaymentController.text);

    final filter = SearchFilter(
      location: _selectedLocation,
      companyId: _selectedCompanyId,
      minPrice: minPriceInMillions != null ? minPriceInMillions * 1000000 : null,
      maxPrice: maxPriceInMillions != null ? maxPriceInMillions * 1000000 : null,
      propertyType: _selectedPropertyType,
      bedrooms: _selectedBedrooms,
      finishing: _selectedFinishing,
      deliveredAtFrom: deliveredAtFromStr,
      deliveredAtTo: deliveredAtToStr,
      hasBeenDelivered: _hasBeenDelivered,
      hasClub: _hasClub ? true : null,
      hasRoof: _hasRoof ? true : null,
      hasGarden: _hasGarden ? true : null,
      sortBy: _selectedSortBy,
      // Payment plan filters
      paymentPlanDuration: _selectedPaymentDuration,
      minMonthlyPayment: minMonthlyPayment,
      maxMonthlyPayment: maxMonthlyPayment,
    );

    print('═══════════════════════════════════════════════');
    print('[FILTER BOTTOM SHEET] Filter Applied:');
    print('[FILTER] Property Type: ${filter.propertyType}');
    print('[FILTER] Bedrooms: ${filter.bedrooms}');
    print('[FILTER] Min Price: ${filter.minPrice}');
    print('[FILTER] Max Price: ${filter.maxPrice}');
    print('[FILTER] Location: ${filter.location}');
    print('[FILTER] Finishing: ${filter.finishing}');
    print('[FILTER] Delivered At From: ${filter.deliveredAtFrom}');
    print('[FILTER] Delivered At To: ${filter.deliveredAtTo}');
    print('[FILTER] Has Been Delivered: ${filter.hasBeenDelivered}');
    print('[FILTER] Has Club: ${filter.hasClub}');
    print('[FILTER] Has Roof: ${filter.hasRoof}');
    print('[FILTER] Has Garden: ${filter.hasGarden}');
    print('[FILTER] Sort By: ${filter.sortBy}');
    print('[FILTER] Payment Duration: ${filter.paymentPlanDuration}');
    print('[FILTER] Min Monthly: ${filter.minMonthlyPayment}');
    print('[FILTER] Max Monthly: ${filter.maxMonthlyPayment}');
    print('[FILTER] isEmpty: ${filter.isEmpty}');
    print('[FILTER] activeFiltersCount: ${filter.activeFiltersCount}');
    print('[FILTER] Query Parameters: ${filter.toQueryParameters()}');
    print('═══════════════════════════════════════════════');

    widget.onApplyFilters(filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                CustomText20(l10n.filters, bold: true, color: AppColors.black),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: CustomText16(l10n.clearAll, color: Colors.red),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Selector with Search
                  _buildSectionTitle(l10n.company, context),
                  SizedBox(height: 8),
                  _isLoadingCompanies
                      ? Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomLoadingDots(size: 30),
                                SizedBox(width: 12),
                                Text(l10n.loadingCompanies),
                              ],
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final selectedCompany = _selectedCompanyId != null
                                ? _availableCompanies.where((c) => c.id == _selectedCompanyId).firstOrNull
                                : null;
                            final displayName = selectedCompany?.getLocalizedName(isArabic) ?? l10n.allCompanies;

                            return InkWell(
                              onTap: () => _showCompanySearchDialog(),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.business_outlined, color: Colors.grey.shade600),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedCompanyId != null
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    if (_selectedCompanyId != null)
                                      IconButton(
                                        icon: Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedCompanyId = null;
                                          });
                                          _applyFiltersWithDebounce();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      )
                                    else
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  SizedBox(height: 24),

                  // Location Selector with Search
                  _buildSectionTitle(l10n.location, context),
                  SizedBox(height: 8),
                  _isLoadingLocations
                      ? Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomLoadingDots(size: 30),
                                SizedBox(width: 12),
                                Text(l10n.loadingLocations),
                              ],
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final selectedLoc = _selectedLocation != null
                                ? _availableLocations.where((l) => l.location == _selectedLocation).firstOrNull
                                : null;
                            final displayName = selectedLoc?.getLocalizedName(isArabic) ?? l10n.allLocations;

                            return InkWell(
                              onTap: () => _showLocationSearchDialog(),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, color: Colors.grey.shade600),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedLocation != null
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    if (_selectedLocation != null)
                                      IconButton(
                                        icon: Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedLocation = null;
                                          });
                                          _applyFiltersWithDebounce();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      )
                                    else
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  SizedBox(height: 24),

                  // Price Range
                  _buildSectionTitle(l10n.priceRangeMillionEGP, context),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'مثال: 3' : 'e.g., 3',
                            labelText: l10n.min,
                            suffixText: 'M',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'مثال: 5' : 'e.g., 5',
                            labelText: l10n.max,
                            suffixText: 'M',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Property Type
                  _buildSectionTitle(l10n.propertyType, context),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: propertyTypes.map((type) {
                      final isSelected = _selectedPropertyType == type;
                      // Localize property type
                      String localizedType = type;
                      switch (type.toLowerCase()) {
                        case 'villa': localizedType = l10n.villa; break;
                        case 'apartment': localizedType = l10n.apartment; break;
                        case 'duplex': localizedType = l10n.duplex; break;
                        case 'studio': localizedType = l10n.studio; break;
                        case 'penthouse': localizedType = l10n.penthouse; break;
                        case 'townhouse': localizedType = l10n.townhouse; break;
                        case 'chalet': localizedType = l10n.chalet; break;
                        case 'twin house': localizedType = l10n.twinHouse; break;
                      }
                      return ChoiceChip(
                        label: Text(localizedType),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPropertyType = selected ? type : null;
                          });
                          _applyFiltersWithDebounce();
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: AppColors.mainColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24),

                  // Number of Bedrooms
                  _buildSectionTitle(l10n.numberOfBedrooms, context),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: bedroomOptions.map((beds) {
                      final isSelected = _selectedBedrooms == beds;
                      final bedsLabel = beds == 1
                          ? '1 ${l10n.bed}'
                          : '$beds ${isArabic ? 'غرف' : 'Beds'}';
                      return ChoiceChip(
                        label: Text(bedsLabel),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBedrooms = selected ? beds : null;
                          });
                          _applyFiltersWithDebounce();
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: AppColors.mainColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24),

                  // Finishing
                  _buildSectionTitle(l10n.finishing, context),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: finishingOptions.map((finishing) {
                      final isSelected = _selectedFinishing == finishing;
                      // Localize finishing type
                      String localizedFinishing = finishing;
                      switch (finishing.toLowerCase()) {
                        case 'finished': localizedFinishing = l10n.finished; break;
                        case 'semi finished': localizedFinishing = l10n.semiFinished; break;
                        case 'not finished': localizedFinishing = l10n.notFinished; break;
                        case 'core & shell': localizedFinishing = l10n.coreShell; break;
                      }
                      return ChoiceChip(
                        label: Text(localizedFinishing),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFinishing = selected ? finishing : null;
                          });
                          _applyFiltersWithDebounce();
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: AppColors.mainColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24),

                  // Payment Duration
                  _buildSectionTitle(l10n.paymentDuration, context),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // "All" option
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _selectedPaymentDuration == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPaymentDuration = null;
                          });
                          _applyFiltersWithDebounce();
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: AppColors.mainColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedPaymentDuration == null
                              ? AppColors.mainColor
                              : Colors.black,
                          fontWeight: _selectedPaymentDuration == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      // Duration options
                      ...paymentDurationOptions.map((duration) {
                        final isSelected = _selectedPaymentDuration == duration;
                        final label = duration == 0
                            ? l10n.cash
                            : '$duration ${l10n.years}';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPaymentDuration = selected ? duration : null;
                            });
                            _applyFiltersWithDebounce();
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: AppColors.mainColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.mainColor
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Monthly Payment Range
                  _buildSectionTitle(l10n.monthlyPaymentEGP, context),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minMonthlyPaymentController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'مثال: 10000' : 'e.g., 10000',
                            labelText: l10n.min,
                            suffixText: l10n.egp,
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxMonthlyPaymentController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'مثال: 100000' : 'e.g., 100000',
                            labelText: l10n.max,
                            suffixText: l10n.egp,
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Delivered From Date
                  _buildSectionTitle(l10n.deliveredFromDate, context),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _deliveredAtFrom ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2035),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.mainColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _deliveredAtFrom = picked;
                        });
                        _applyFiltersWithDebounce();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deliveredAtFrom != null
                                  ? DateFormat('yyyy-MM-dd').format(_deliveredAtFrom!)
                                  : l10n.selectDeliveredFromDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: _deliveredAtFrom != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (_deliveredAtFrom != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _deliveredAtFrom = null;
                                });
                                _applyFiltersWithDebounce();
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Delivered To Date
                  _buildSectionTitle(l10n.deliveredToDate, context),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _deliveredAtTo ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2035),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.mainColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _deliveredAtTo = picked;
                        });
                        _applyFiltersWithDebounce();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deliveredAtTo != null
                                  ? DateFormat('yyyy-MM-dd').format(_deliveredAtTo!)
                                  : l10n.selectDeliveredToDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: _deliveredAtTo != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (_deliveredAtTo != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _deliveredAtTo = null;
                                });
                                _applyFiltersWithDebounce();
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Has Been Delivered
                  _buildSectionTitle(l10n.deliveryStatus, context),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<bool?>(
                      value: _hasBeenDelivered,
                      decoration: InputDecoration(
                        hintText: l10n.selectDeliveryStatus,
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text(
                            l10n.all,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text(l10n.onlyDelivered),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text(l10n.notDelivered),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _hasBeenDelivered = value;
                        });
                        _applyFiltersWithDebounce();
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  // Amenities
                  _buildSectionTitle(l10n.amenities, context),
                  SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(l10n.hasClubAmenityFilter),
                    value: _hasClub,
                    onChanged: (value) {
                      setState(() {
                        _hasClub = value ?? false;
                      });
                      _applyFiltersWithDebounce();
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(l10n.hasRoofAmenityFilter),
                    value: _hasRoof,
                    onChanged: (value) {
                      setState(() {
                        _hasRoof = value ?? false;
                      });
                      _applyFiltersWithDebounce();
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(l10n.hasGardenAmenityFilter),
                    value: _hasGarden,
                    onChanged: (value) {
                      setState(() {
                        _hasGarden = value ?? false;
                      });
                      _applyFiltersWithDebounce();
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),

                  SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFiltersImmediately();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        l10n.applyFilters,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, [BuildContext? ctx]) {
    return CustomText18(title, bold: true, color: AppColors.black);
  }

  void _showLocationSearchDialog() {
    String searchQuery = '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter locations based on search (search in both languages)
            final filteredLocations = _availableLocations.where((loc) {
              if (searchQuery.isEmpty) return true;
              final query = searchQuery.toLowerCase();
              return loc.location.toLowerCase().contains(query) ||
                     loc.locationEn.toLowerCase().contains(query) ||
                     loc.locationAr.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CustomText18(isArabic ? 'اختر الموقع' : 'Select Location', bold: true, color: AppColors.black),
                            SizedBox(width: 48), // Balance the close button
                          ],
                        ),
                        SizedBox(height: 12),
                        // Search TextField
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: isArabic ? 'ابحث عن موقع...' : 'Search locations...',
                            prefixIcon: Icon(Icons.search),
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
                              borderSide: BorderSide(color: AppColors.mainColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Location List
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // "All Locations" option
                        ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: _selectedLocation == null ? AppColors.mainColor : Colors.grey,
                          ),
                          title: Text(
                            isArabic ? 'جميع المواقع' : 'All Locations',
                            style: TextStyle(
                              fontWeight: _selectedLocation == null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedLocation == null ? AppColors.mainColor : Colors.black87,
                            ),
                          ),
                          trailing: _selectedLocation == null
                              ? Icon(Icons.check, color: AppColors.mainColor)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedLocation = null;
                            });
                            _applyFiltersWithDebounce();
                            Navigator.pop(context);
                          },
                        ),
                        Divider(height: 1),
                        // Filtered locations with localized names
                        ...filteredLocations.map((loc) {
                          final isSelected = _selectedLocation == loc.location;
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected ? AppColors.mainColor : Colors.grey,
                            ),
                            title: Text(
                              loc.getLocalizedName(isArabic),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.mainColor : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check, color: AppColors.mainColor)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedLocation = loc.location;
                              });
                              _applyFiltersWithDebounce();
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        // No results
                        if (filteredLocations.isEmpty && searchQuery.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  isArabic
                                      ? 'لا توجد مواقع تطابق "$searchQuery"'
                                      : 'No locations found for "$searchQuery"',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCompanySearchDialog() {
    String searchQuery = '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter companies based on search (search in both languages)
            final filteredCompanies = _availableCompanies.where((company) {
              if (searchQuery.isEmpty) return true;
              final query = searchQuery.toLowerCase();
              return company.name.toLowerCase().contains(query) ||
                     company.nameEn.toLowerCase().contains(query) ||
                     company.nameAr.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CustomText18(isArabic ? 'اختر الشركة' : 'Select Company', bold: true, color: AppColors.black),
                            SizedBox(width: 48), // Balance the close button
                          ],
                        ),
                        SizedBox(height: 12),
                        // Search TextField
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: isArabic ? 'ابحث عن شركة...' : 'Search companies...',
                            prefixIcon: Icon(Icons.search),
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
                              borderSide: BorderSide(color: AppColors.mainColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Company List
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // "All Companies" option
                        ListTile(
                          leading: Icon(
                            Icons.business_outlined,
                            color: _selectedCompanyId == null ? AppColors.mainColor : Colors.grey,
                          ),
                          title: Text(
                            isArabic ? 'جميع الشركات' : 'All Companies',
                            style: TextStyle(
                              fontWeight: _selectedCompanyId == null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedCompanyId == null ? AppColors.mainColor : Colors.black87,
                            ),
                          ),
                          trailing: _selectedCompanyId == null
                              ? Icon(Icons.check, color: AppColors.mainColor)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCompanyId = null;
                            });
                            _applyFiltersWithDebounce();
                            Navigator.pop(context);
                          },
                        ),
                        Divider(height: 1),
                        // Filtered companies with localized names
                        ...filteredCompanies.map((company) {
                          final isSelected = _selectedCompanyId == company.id;
                          return ListTile(
                            leading: Icon(
                              Icons.business,
                              color: isSelected ? AppColors.mainColor : Colors.grey,
                            ),
                            title: Text(
                              company.getLocalizedName(isArabic),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.mainColor : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check, color: AppColors.mainColor)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCompanyId = company.id;
                              });
                              _applyFiltersWithDebounce();
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        // No results
                        if (filteredCompanies.isEmpty && searchQuery.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  isArabic
                                      ? 'لا توجد شركات تطابق "$searchQuery"'
                                      : 'No companies found for "$searchQuery"',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
