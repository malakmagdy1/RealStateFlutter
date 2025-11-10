import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

import '../../data/models/search_filter_model.dart';

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
  late TextEditingController _locationController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _deliveryDateController;

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
    _locationController = TextEditingController(
      text: widget.initialFilter.location,
    );
    _minPriceController = TextEditingController(
      text: widget.initialFilter.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilter.maxPrice?.toString() ?? '',
    );
    _deliveryDateController = TextEditingController(
      text: widget.initialFilter.deliveryDate ?? '',
    );
    _selectedPropertyType = widget.initialFilter.propertyType;
    _selectedBedrooms = widget.initialFilter.bedrooms;
    _selectedFinishing = widget.initialFilter.finishing;
    _hasClub = widget.initialFilter.hasClub ?? false;
    _hasRoof = widget.initialFilter.hasRoof ?? false;
    _hasGarden = widget.initialFilter.hasGarden ?? false;
    _selectedSortBy = widget.initialFilter.sortBy;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _deliveryDateController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _deliveryDateController.clear();
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
    final filter = SearchFilter(
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
      propertyType: _selectedPropertyType,
      bedrooms: _selectedBedrooms,
      finishing: _selectedFinishing,
      deliveryDate: _deliveryDateController.text.isEmpty
          ? null
          : _deliveryDateController.text,
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  _buildSectionTitle('Location'),
                  SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g., New Cairo, 6th October',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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

                  // Delivery Date
                  _buildSectionTitle('Delivery Date'),
                  SizedBox(height: 8),
                  TextField(
                    controller: _deliveryDateController,
                    decoration: InputDecoration(
                      hintText: 'e.g., 2025, Q1 2026',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
