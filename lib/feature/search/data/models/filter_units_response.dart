import 'dart:io' show Platform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';

class FilterUnitsResponse extends Equatable {
  final bool success;
  final String? searchQuery;
  final int totalUnits;
  final int page;
  final int limit;
  final int totalPages;
  final List<String> filtersApplied;
  final List<FilteredUnit> units;
  final List<Company> companies;
  final List<Compound> compounds;
  final Map<String, dynamic>? subscription;

  FilterUnitsResponse({
    required this.success,
    this.searchQuery,
    required this.totalUnits,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.filtersApplied,
    required this.units,
    this.companies = const [],
    this.compounds = const [],
    this.subscription,
  });

  factory FilterUnitsResponse.fromJson(Map<String, dynamic> json) {
    List<FilteredUnit> unitsList = [];

    // Try 'units' or 'data' field for the units array
    final unitsData = json['units'] ?? json['data'];
    if (unitsData != null && unitsData is List) {
      // Parse units and filter out invalid ones
      unitsList = unitsData
          .map((unit) {
            try {
              return FilteredUnit.fromJson(unit as Map<String, dynamic>);
            } catch (e) {
              print('[FILTER RESPONSE] Error parsing unit: $e');
              return null;
            }
          })
          .whereType<FilteredUnit>() // Remove null values
          .where((unit) => _isValidUnit(unit)) // Filter out invalid units
          .toList();
    }

    // Parse companies array
    List<Company> companiesList = [];
    final companiesData = json['companies'];
    if (companiesData != null && companiesData is List) {
      companiesList = companiesData
          .map((company) {
            try {
              return Company.fromJson(company as Map<String, dynamic>);
            } catch (e) {
              print('[FILTER RESPONSE] Error parsing company: $e');
              return null;
            }
          })
          .whereType<Company>()
          .toList();
    }

    // Parse compounds array
    List<Compound> compoundsList = [];
    final compoundsData = json['compounds'];
    if (compoundsData != null && compoundsData is List) {
      compoundsList = compoundsData
          .map((compound) {
            try {
              return Compound.fromJson(compound as Map<String, dynamic>);
            } catch (e) {
              print('[FILTER RESPONSE] Error parsing compound: $e');
              return null;
            }
          })
          .whereType<Compound>()
          .toList();
    }

    List<String> filtersList = [];
    if (json['filters_applied'] != null && json['filters_applied'] is List) {
      filtersList = (json['filters_applied'] as List)
          .map((filter) => filter.toString())
          .toList();
    }

    return FilterUnitsResponse(
      success: json['success'] ?? true,
      searchQuery: json['search_query']?.toString(),
      totalUnits: json['total_units'] ?? json['total'] ?? unitsList.length,
      page: json['page'] ?? json['current_page'] ?? 1,
      limit: json['limit'] ?? json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? json['last_page'] ?? 1,
      filtersApplied: filtersList,
      units: unitsList,
      companies: companiesList,
      compounds: compoundsList,
      subscription: json['subscription'] as Map<String, dynamic>?,
    );
  }

  /// Validate that a unit has essential data
  /// Returns false if unit has no valid ID or is clearly invalid/empty
  static bool _isValidUnit(FilteredUnit unit) {
    // Must have a valid ID (not empty, not '0', not 'null')
    if (unit.id.isEmpty || unit.id == '0' || unit.id.toLowerCase() == 'null') {
      print('[FILTER RESPONSE] ✗ Skipping unit with invalid ID: ${unit.id}');
      return false;
    }

    // Must have a valid unit name or compound name
    if (unit.unitName.isEmpty && unit.compoundName.isEmpty) {
      print('[FILTER RESPONSE] ✗ Skipping unit ${unit.id} with no name');
      return false;
    }

    // Must have a valid compound ID
    if (unit.compoundId.isEmpty || unit.compoundId == '0') {
      print('[FILTER RESPONSE] ✗ Skipping unit ${unit.id} with invalid compound ID');
      return false;
    }

    // Skip only if explicitly sold (status is "sold")
    if (unit.status.toLowerCase() == 'sold' || unit.isSold) {
      print('[FILTER RESPONSE] ✗ Skipping unit ${unit.id} (${unit.unitName}) - already sold');
      return false;
    }

    // Note: We removed the 'available' check because backend may not set it correctly
    // Units should be shown unless explicitly sold
    print('[FILTER RESPONSE] ✓ Including unit ${unit.id} (${unit.unitName}) - Status: ${unit.status}, Available: ${unit.available}');
    return true;
  }

  /// Creates a copy of this response with optionally updated fields
  FilterUnitsResponse copyWith({
    bool? success,
    String? searchQuery,
    int? totalUnits,
    int? page,
    int? limit,
    int? totalPages,
    List<String>? filtersApplied,
    List<FilteredUnit>? units,
    List<Company>? companies,
    List<Compound>? compounds,
    Map<String, dynamic>? subscription,
  }) {
    return FilterUnitsResponse(
      success: success ?? this.success,
      searchQuery: searchQuery ?? this.searchQuery,
      totalUnits: totalUnits ?? this.totalUnits,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      filtersApplied: filtersApplied ?? this.filtersApplied,
      units: units ?? this.units,
      companies: companies ?? this.companies,
      compounds: compounds ?? this.compounds,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  List<Object?> get props => [success, searchQuery, totalUnits, page, limit, totalPages, filtersApplied, units, companies, compounds, subscription];
}

class FilteredUnit extends Equatable {
  final String id;
  final String compoundId;
  final String compoundName;
  final String compoundLocation;
  final String companyId;
  final String companyName;
  final String? companyLogo;
  final String? companyEmail;
  final String unitName;
  final String buildingName;
  final String unitNumber;
  final String code;
  final String unitCode;
  final String usageType;
  final String? unitType;
  final String status;
  final String? stageNumber;
  final int numberOfBeds;
  final int floorNumber;
  final String normalPrice;
  final String totalPricing;
  final double totalArea;
  final bool available;
  final bool isSold;
  final String? deliveredAt;
  final List<String> images;
  final String createdAt;
  final String updatedAt;
  // New fields from unified API
  final String? unitNameLocalized;
  final String? unitTypeLocalized;
  final String? usageTypeLocalized;
  final String? statusLocalized;
  final String? originalPrice;
  final String? discountedPrice;
  final String? discountPercentage;
  final bool hasActiveSale;
  final Map<String, dynamic>? sale;
  final Map<String, dynamic>? compound;
  final Map<String, dynamic>? company;
  final String? builtUpArea;
  final String? landArea;
  final String? gardenArea;
  final String? roofArea;
  final String? finishingType;

  FilteredUnit({
    required this.id,
    required this.compoundId,
    required this.compoundName,
    required this.compoundLocation,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    this.companyEmail,
    required this.unitName,
    required this.buildingName,
    required this.unitNumber,
    required this.code,
    required this.unitCode,
    required this.usageType,
    this.unitType,
    required this.status,
    this.stageNumber,
    required this.numberOfBeds,
    required this.floorNumber,
    required this.normalPrice,
    required this.totalPricing,
    required this.totalArea,
    required this.available,
    required this.isSold,
    this.deliveredAt,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.unitNameLocalized,
    this.unitTypeLocalized,
    this.usageTypeLocalized,
    this.statusLocalized,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.hasActiveSale = false,
    this.sale,
    this.compound,
    this.company,
    this.builtUpArea,
    this.landArea,
    this.gardenArea,
    this.roofArea,
    this.finishingType,
  });

  factory FilteredUnit.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => _fixImageUrl(img.toString()))
          .toList();
    }

    // Handle company data - can be nested object or flat fields
    String? companyLogo;
    String? companyEmail;
    String companyId = '';
    String companyName = '';

    if (json['company'] != null && json['company'] is Map) {
      final companyData = json['company'] as Map<String, dynamic>;
      companyId = companyData['id']?.toString() ?? '';
      companyName = companyData['name']?.toString() ?? '';
      companyLogo = companyData['logo']?.toString();
      companyEmail = companyData['email']?.toString();
    } else {
      companyId = json['company_id']?.toString() ?? '';
      companyName = json['company_name']?.toString() ?? '';
      companyLogo = json['company_logo']?.toString();
      companyEmail = json['company_email']?.toString();
    }

    if (companyLogo != null && companyLogo.isNotEmpty) {
      companyLogo = _fixImageUrl(companyLogo);
    }

    // Handle compound data - can be nested object or flat fields
    String compoundId = '';
    String compoundName = '';
    String compoundLocation = '';

    if (json['compound'] != null && json['compound'] is Map) {
      final compoundData = json['compound'] as Map<String, dynamic>;
      compoundId = compoundData['id']?.toString() ?? '';
      compoundName = compoundData['name']?.toString() ?? '';
      compoundLocation = compoundData['location']?.toString() ?? '';
    } else {
      compoundId = json['compound_id']?.toString() ?? '';
      compoundName = json['compound_name']?.toString() ?? '';
      compoundLocation = json['compound_location']?.toString() ?? '';
    }

    // Calculate total area from various area fields
    double totalArea = 0.0;
    if (json['total_area'] != null) {
      totalArea = double.tryParse(json['total_area']?.toString() ?? '0') ?? 0.0;
    } else {
      // Calculate from built_up_area + garden_area + roof_area
      final builtUp = double.tryParse(json['built_up_area']?.toString() ?? '0') ?? 0.0;
      final garden = double.tryParse(json['garden_area']?.toString() ?? '0') ?? 0.0;
      final roof = double.tryParse(json['roof_area']?.toString() ?? '0') ?? 0.0;
      totalArea = builtUp + garden + roof;
    }

    // Debug logging for search API data
    print('[FILTERED UNIT] Parsing unit ${json['id']}:');
    print('[FILTERED UNIT]   delivery_date: ${json['delivery_date']}');
    print('[FILTERED UNIT]   delivered_at: ${json['delivered_at']}');
    print('[FILTERED UNIT]   total_area: ${json['total_area']}');
    print('[FILTERED UNIT]   finishing_type: ${json['finishing_type']}');

    return FilteredUnit(
      id: json['id']?.toString() ?? '',
      compoundId: compoundId,
      compoundName: compoundName,
      compoundLocation: compoundLocation,
      companyId: companyId,
      companyName: companyName,
      companyLogo: companyLogo,
      companyEmail: companyEmail,
      unitName: json['unit_name']?.toString() ?? '',
      buildingName: json['building_name']?.toString() ?? '',
      unitNumber: json['unit_number']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      unitCode: json['unit_code']?.toString() ?? '',
      usageType: json['usage_type']?.toString() ?? '',
      unitType: json['unit_type']?.toString(),
      status: json['status']?.toString() ?? '',
      stageNumber: json['stage_number']?.toString(),
      numberOfBeds: int.tryParse(json['number_of_beds']?.toString() ?? '0') ?? 0,
      floorNumber: int.tryParse(json['floor_number']?.toString() ?? '0') ?? 0,
      normalPrice: json['normal_price']?.toString() ?? json['discounted_price']?.toString() ?? '0',
      totalPricing: json['total_pricing']?.toString() ?? json['normal_price']?.toString() ?? '0',
      totalArea: totalArea,
      available: json['available'] == true || json['available']?.toString() == '1',
      isSold: json['is_sold'] == true || json['is_sold']?.toString() == '1',
      deliveredAt: json['delivered_at']?.toString() ??
                   json['delivery_date']?.toString() ??
                   json['planned_delivery_date']?.toString(),
      images: imagesList,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      unitNameLocalized: json['unit_name_localized']?.toString(),
      unitTypeLocalized: json['unit_type_localized']?.toString(),
      usageTypeLocalized: json['usage_type_localized']?.toString(),
      statusLocalized: json['status_localized']?.toString(),
      originalPrice: json['original_price']?.toString(),
      discountedPrice: json['discounted_price']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      hasActiveSale: json['has_active_sale'] == true || json['has_active_sale']?.toString() == '1' || json['has_active_sale']?.toString() == 'true',
      sale: json['sale'] as Map<String, dynamic>?,
      compound: json['compound'] as Map<String, dynamic>?,
      company: json['company'] as Map<String, dynamic>?,
      builtUpArea: json['built_up_area']?.toString(),
      landArea: json['land_area']?.toString(),
      gardenArea: json['garden_area']?.toString(),
      roofArea: json['roof_area']?.toString(),
      finishingType: json['finishing_type']?.toString() ?? json['finishing']?.toString(),
    );
  }

  // Fix image URL to work on Android emulator
  static String _fixImageUrl(String url) {
    try {
      if (url.isEmpty) return url;

      // Fix Laravel storage path
      url = url.replaceAll('/storage/app/public/', '/storage/');

      final uri = Uri.parse(url);

      // If running on Android emulator, replace localhost or any IP with 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final port = uri.hasPort ? ':${uri.port}' : '';
          return url.replaceFirst(RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'), 'http://10.0.2.2$port');
        }
        else if (uri.host.startsWith('192.168.') || uri.host.startsWith('10.')) {
          final port = uri.hasPort ? ':${uri.port}' : '';
          return url.replaceFirst(RegExp(r'https?://[0-9.]+(:\d+)?'), 'http://10.0.2.2$port');
        }
      }

      return url;
    } catch (e) {
      return url;
    }
  }

  @override
  List<Object?> get props => [
        id,
        compoundId,
        compoundName,
        compoundLocation,
        companyId,
        companyName,
        companyLogo,
        companyEmail,
        unitName,
        buildingName,
        unitNumber,
        code,
        unitCode,
        usageType,
        unitType,
        status,
        stageNumber,
        numberOfBeds,
        floorNumber,
        normalPrice,
        totalPricing,
        totalArea,
        available,
        isSold,
        deliveredAt,
        images,
        createdAt,
        updatedAt,
        unitNameLocalized,
        unitTypeLocalized,
        usageTypeLocalized,
        statusLocalized,
        originalPrice,
        discountedPrice,
        discountPercentage,
        hasActiveSale,
        sale,
        compound,
        company,
        builtUpArea,
        landArea,
        gardenArea,
        roofArea,
        finishingType,
      ];
}
