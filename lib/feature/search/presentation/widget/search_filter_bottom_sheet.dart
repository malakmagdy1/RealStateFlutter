import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:intl/intl.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

import '../../data/models/search_filter_model.dart';
import '../../data/services/location_service.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilter initialFilter;
  final Function(SearchFilter) onApplyFilters;

  SearchFilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  final LocationService _locationService = LocationService();
  List<String> _availableLocations = [];
  bool _isLoadingLocations = true;

  String? _selectedLocation;
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

    // Initialize controllers
    _minPriceController = TextEditingController(
      text: widget.initialFilter.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilter.maxPrice?.toString() ?? '',
    );

    // Set initial values
    _selectedLocation = widget.initialFilter.location;
    _selectedPropertyType = widget.initialFilter.propertyType;
    _selectedBedrooms = widget.initialFilter.bedrooms;
    _selectedFinishing = widget.initialFilter.finishing;
    _hasClub = widget.initialFilter.hasClub ?? false;
    _hasRoof = widget.initialFilter.hasRoof ?? false;
    _hasGarden = widget.initialFilter.hasGarden ?? false;
    _selectedSortBy = widget.initialFilter.sortBy;

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

    // Load locations from database
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    print('[FILTER BOTTOM SHEET] ========================================');
    print('[FILTER BOTTOM SHEET] Loading locations...');
    try {
      final locations = await _locationService.getLocations();
      print('[FILTER BOTTOM SHEET] ✓ Received ${locations.length} locations');
      print('[FILTER BOTTOM SHEET] Locations: ${locations.take(5).join(", ")}${locations.length > 5 ? "..." : ""}');

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

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLocation = null;
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
    });
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

    final filter = SearchFilter(
      location: _selectedLocation,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
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
    print('[FILTER] isEmpty: ${filter.isEmpty}');
    print('[FILTER] activeFiltersCount: ${filter.activeFiltersCount}');
    print('[FILTER] Query Parameters: ${filter.toQueryParameters()}');
    print('═══════════════════════════════════════════════');

    widget.onApplyFilters(filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                CustomText20('Filters', bold: true, color: AppColors.black),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: CustomText16('Clear All', color: Colors.red),
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
                  // Location Dropdown
                  _buildSectionTitle('Location'),
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
                                Text('Loading locations...'),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: InputDecoration(
                              hintText: 'Select location',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Locations',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ..._availableLocations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                          ),
                        ),

                  SizedBox(height: 24),

                  // Price Range
                  _buildSectionTitle('Price Range (EGP)'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min',
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
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
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
                  _buildSectionTitle('Property Type'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: propertyTypes.map((type) {
                      final isSelected = _selectedPropertyType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPropertyType = selected ? type : null;
                          });
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
                  _buildSectionTitle('Number of Bedrooms'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: bedroomOptions.map((beds) {
                      final isSelected = _selectedBedrooms == beds;
                      return ChoiceChip(
                        label: Text('$beds Bed${beds > 1 ? 's' : ''}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBedrooms = selected ? beds : null;
                          });
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
                  _buildSectionTitle('Finishing'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: finishingOptions.map((finishing) {
                      final isSelected = _selectedFinishing == finishing;
                      return ChoiceChip(
                        label: Text(finishing),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFinishing = selected ? finishing : null;
                          });
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

                  // Delivered From Date
                  _buildSectionTitle('Delivered From Date'),
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
                                  : 'Select delivered from date',
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
                  _buildSectionTitle('Delivered To Date'),
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
                                  : 'Select delivered to date',
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
                  _buildSectionTitle('Delivery Status'),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<bool?>(
                      value: _hasBeenDelivered,
                      decoration: InputDecoration(
                        hintText: 'Select delivery status',
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
                            'All',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Only Delivered'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Not Delivered'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _hasBeenDelivered = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  // Amenities
                  _buildSectionTitle('Amenities'),
                  SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text('Has Club'),
                    value: _hasClub,
                    onChanged: (value) {
                      setState(() {
                        _hasClub = value ?? false;
                      });
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text('Has Roof'),
                    value: _hasRoof,
                    onChanged: (value) {
                      setState(() {
                        _hasRoof = value ?? false;
                      });
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text('Has Garden'),
                    value: _hasGarden,
                    onChanged: (value) {
                      setState(() {
                        _hasGarden = value ?? false;
                      });
                    },
                    activeColor: AppColors.mainColor,
                    contentPadding: EdgeInsets.zero,
                  ),

                  SizedBox(height: 24),

                  // Sort By
                  _buildSectionTitle('Sort By'),
                  SizedBox(height: 8),
                  Column(
                    children: sortOptions.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: _selectedSortBy,
                        onChanged: (value) {
                          setState(() {
                            _selectedSortBy = value;
                          });
                        },
                        activeColor: AppColors.mainColor,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: CustomText18(
                  'Apply Filters',
                  color: Colors.white,
                  bold: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText18(title, bold: true, color: AppColors.black);
  }
}
