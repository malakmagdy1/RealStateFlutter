class SearchFilter {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final String? propertyType; // 'villa', 'apartment', 'duplex', 'studio', etc.
  final int? bedrooms;
  final String? finishing; // 'finished', 'semi_finished', 'not_finished'
  final String? deliveredAtFrom; // Date format: YYYY-MM-DD - Units delivered on or after this date
  final String? deliveredAtTo; // Date format: YYYY-MM-DD - Units delivered on or before this date
  final bool? hasBeenDelivered; // true = only delivered units, false = only not delivered units
  final bool? hasClub;
  final bool? hasRoof;
  final bool? hasGarden;
  final String? sortBy; // 'price_asc', 'price_desc', 'date_asc', 'date_desc'

  // Advanced filter parameters
  final double? minArea;
  final double? maxArea;
  final double? minBuiltUpArea;
  final double? maxBuiltUpArea;
  final double? minLandArea;
  final double? maxLandArea;
  final double? minGardenArea;
  final double? maxGardenArea;
  final double? minRoofArea;
  final double? maxRoofArea;
  final bool? hasBasement;
  final bool? hasGarage;
  final bool? hasActiveSale;
  final String? status; // 'available', 'reserved', 'sold'
  final int? page;
  final int? limit;

  // Additional unit filter parameters
  final String? unitName;
  final String? unitType;
  final String? buildingName;
  final String? stageNumber;
  final int? floorNumber;
  final String? compoundId;
  final bool? available;
  final bool? isSold;
  final double? minTotalPricing;
  final double? maxTotalPricing;
  final double? minBasementArea;
  final double? maxBasementArea;
  final double? minGarageArea;
  final double? maxGarageArea;
  final String? companyId;
  final String? usageType;
  final String? search;

  SearchFilter({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.propertyType,
    this.bedrooms,
    this.finishing,
    this.deliveredAtFrom,
    this.deliveredAtTo,
    this.hasBeenDelivered,
    this.hasClub,
    this.hasRoof,
    this.hasGarden,
    this.sortBy,
    this.minArea,
    this.maxArea,
    this.minBuiltUpArea,
    this.maxBuiltUpArea,
    this.minLandArea,
    this.maxLandArea,
    this.minGardenArea,
    this.maxGardenArea,
    this.minRoofArea,
    this.maxRoofArea,
    this.hasBasement,
    this.hasGarage,
    this.hasActiveSale,
    this.status,
    this.page,
    this.limit,
    this.unitName,
    this.unitType,
    this.buildingName,
    this.stageNumber,
    this.floorNumber,
    this.compoundId,
    this.available,
    this.isSold,
    this.minTotalPricing,
    this.maxTotalPricing,
    this.minBasementArea,
    this.maxBasementArea,
    this.minGarageArea,
    this.maxGarageArea,
    this.companyId,
    this.usageType,
    this.search,
  });

  // Create an empty filter
  factory SearchFilter.empty() {
    return SearchFilter();
  }

  // Check if filter is empty
  bool get isEmpty =>
      location == null &&
      minPrice == null &&
      maxPrice == null &&
      propertyType == null &&
      bedrooms == null &&
      finishing == null &&
      deliveredAtFrom == null &&
      deliveredAtTo == null &&
      hasBeenDelivered == null &&
      hasClub == null &&
      hasRoof == null &&
      hasGarden == null &&
      sortBy == null &&
      minArea == null &&
      maxArea == null &&
      minBuiltUpArea == null &&
      maxBuiltUpArea == null &&
      minLandArea == null &&
      maxLandArea == null &&
      minGardenArea == null &&
      maxGardenArea == null &&
      minRoofArea == null &&
      maxRoofArea == null &&
      hasBasement == null &&
      hasGarage == null &&
      hasActiveSale == null &&
      status == null &&
      page == null &&
      limit == null &&
      unitName == null &&
      unitType == null &&
      buildingName == null &&
      stageNumber == null &&
      floorNumber == null &&
      compoundId == null &&
      available == null &&
      isSold == null &&
      minTotalPricing == null &&
      maxTotalPricing == null &&
      minBasementArea == null &&
      maxBasementArea == null &&
      minGarageArea == null &&
      maxGarageArea == null &&
      companyId == null &&
      usageType == null &&
      search == null;

  // Count active filters
  int get activeFiltersCount {
    int count = 0;
    if (location != null && location!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (propertyType != null && propertyType!.isNotEmpty) count++;
    if (bedrooms != null) count++;
    if (finishing != null && finishing!.isNotEmpty) count++;
    if (deliveredAtFrom != null && deliveredAtFrom!.isNotEmpty) count++;
    if (deliveredAtTo != null && deliveredAtTo!.isNotEmpty) count++;
    if (hasBeenDelivered != null) count++;
    if (hasClub == true) count++;
    if (hasRoof == true) count++;
    if (hasGarden == true) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    if (minArea != null || maxArea != null) count++;
    if (minBuiltUpArea != null || maxBuiltUpArea != null) count++;
    if (minLandArea != null || maxLandArea != null) count++;
    if (minGardenArea != null || maxGardenArea != null) count++;
    if (minRoofArea != null || maxRoofArea != null) count++;
    if (hasBasement == true) count++;
    if (hasGarage == true) count++;
    if (hasActiveSale == true) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (unitName != null && unitName!.isNotEmpty) count++;
    if (unitType != null && unitType!.isNotEmpty) count++;
    if (buildingName != null && buildingName!.isNotEmpty) count++;
    if (stageNumber != null && stageNumber!.isNotEmpty) count++;
    if (floorNumber != null) count++;
    if (compoundId != null && compoundId!.isNotEmpty) count++;
    if (available != null) count++;
    if (isSold != null) count++;
    if (minTotalPricing != null || maxTotalPricing != null) count++;
    if (minBasementArea != null || maxBasementArea != null) count++;
    if (minGarageArea != null || maxGarageArea != null) count++;
    if (companyId != null && companyId!.isNotEmpty) count++;
    if (usageType != null && usageType!.isNotEmpty) count++;
    if (search != null && search!.isNotEmpty) count++;
    return count;
  }

  // Convert to query parameters for API
  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    // Add search parameter if provided
    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    // Add usage_type - prefer explicit usageType over propertyType
    if (usageType != null && usageType!.isNotEmpty) {
      params['usage_type'] = usageType;
    } else if (propertyType != null && propertyType!.isNotEmpty) {
      params['usage_type'] = propertyType;
    }
    // Add company - use 'company' parameter (company name) instead of 'company_id'
    if (companyId != null && companyId!.isNotEmpty) {
      params['company'] = companyId;  // Backend expects 'company' parameter with company name
    }
    if (unitType != null && unitType!.isNotEmpty) {
      params['unit_type'] = unitType;
    }
    if (unitName != null && unitName!.isNotEmpty) {
      params['unit_name'] = unitName;
    }
    if (buildingName != null && buildingName!.isNotEmpty) {
      params['building_name'] = buildingName;
    }
    if (stageNumber != null && stageNumber!.isNotEmpty) {
      params['stage_number'] = stageNumber;
    }
    if (bedrooms != null) {
      params['number_of_beds'] = bedrooms;
    }
    if (floorNumber != null) {
      params['floor_number'] = floorNumber;
    }
    if (compoundId != null && compoundId!.isNotEmpty) {
      params['compound_id'] = compoundId;
    }
    if (available != null) {
      params['available'] = available;
    }
    if (isSold != null) {
      params['is_sold'] = isSold;
    }
    if (minPrice != null) {
      params['min_price'] = minPrice!.toInt();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice!.toInt();
    }
    if (minTotalPricing != null) {
      params['min_total_pricing'] = minTotalPricing!.toInt();
    }
    if (maxTotalPricing != null) {
      params['max_total_pricing'] = maxTotalPricing!.toInt();
    }
    if (minArea != null) {
      params['min_area'] = minArea!.toInt();
    }
    if (maxArea != null) {
      params['max_area'] = maxArea!.toInt();
    }
    if (minBuiltUpArea != null) {
      params['min_built_up_area'] = minBuiltUpArea!.toInt();
    }
    if (maxBuiltUpArea != null) {
      params['max_built_up_area'] = maxBuiltUpArea!.toInt();
    }
    if (minLandArea != null) {
      params['min_land_area'] = minLandArea!.toInt();
    }
    if (maxLandArea != null) {
      params['max_land_area'] = maxLandArea!.toInt();
    }
    if (minGardenArea != null) {
      params['min_garden_area'] = minGardenArea!.toInt();
    }
    if (maxGardenArea != null) {
      params['max_garden_area'] = maxGardenArea!.toInt();
    }
    if (minRoofArea != null) {
      params['min_roof_area'] = minRoofArea!.toInt();
    }
    if (maxRoofArea != null) {
      params['max_roof_area'] = maxRoofArea!.toInt();
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (minBasementArea != null) {
      params['min_basement_area'] = minBasementArea!.toInt();
    }
    if (maxBasementArea != null) {
      params['max_basement_area'] = maxBasementArea!.toInt();
    }
    if (minGarageArea != null) {
      params['min_garage_area'] = minGarageArea!.toInt();
    }
    if (maxGarageArea != null) {
      params['max_garage_area'] = maxGarageArea!.toInt();
    }
    if (hasBasement == true) {
      params['has_basement'] = true;
    }
    if (hasGarage == true) {
      params['has_garage'] = true;
    }
    if (hasActiveSale == true) {
      params['has_active_sale'] = true;
    }
    if (location != null && location!.isNotEmpty) {
      params['location'] = location;
    }
    if (finishing != null && finishing!.isNotEmpty) {
      params['finishing'] = finishing;
    }
    if (deliveredAtFrom != null && deliveredAtFrom!.isNotEmpty) {
      params['planned_delivery_from'] = deliveredAtFrom;
    }
    if (deliveredAtTo != null && deliveredAtTo!.isNotEmpty) {
      params['planned_delivery_to'] = deliveredAtTo;
    }
    if (hasBeenDelivered != null) {
      params['has_been_delivered'] = hasBeenDelivered;
    }
    if (hasClub == true) {
      params['has_club'] = true;
    }
    if (hasRoof == true) {
      params['has_roof'] = true;
    }
    if (hasGarden == true) {
      params['has_garden'] = true;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy;
    }
    if (page != null) {
      params['page'] = page;
    }
    if (limit != null) {
      params['limit'] = limit;
    }

    return params;
  }

  // Convert to JSON for saved searches
  Map<String, dynamic> toJson() {
    return toQueryParameters();
  }

  // Create from JSON for saved searches
  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      propertyType: json['usage_type']?.toString(),
      bedrooms: json['number_of_beds'] != null ? int.tryParse(json['number_of_beds'].toString()) : null,
      minPrice: json['min_price'] != null ? double.tryParse(json['min_price'].toString()) : null,
      maxPrice: json['max_price'] != null ? double.tryParse(json['max_price'].toString()) : null,
      minArea: json['min_area'] != null ? double.tryParse(json['min_area'].toString()) : null,
      maxArea: json['max_area'] != null ? double.tryParse(json['max_area'].toString()) : null,
      minBuiltUpArea: json['min_built_up_area'] != null ? double.tryParse(json['min_built_up_area'].toString()) : null,
      maxBuiltUpArea: json['max_built_up_area'] != null ? double.tryParse(json['max_built_up_area'].toString()) : null,
      minLandArea: json['min_land_area'] != null ? double.tryParse(json['min_land_area'].toString()) : null,
      maxLandArea: json['max_land_area'] != null ? double.tryParse(json['max_land_area'].toString()) : null,
      minGardenArea: json['min_garden_area'] != null ? double.tryParse(json['min_garden_area'].toString()) : null,
      maxGardenArea: json['max_garden_area'] != null ? double.tryParse(json['max_garden_area'].toString()) : null,
      minRoofArea: json['min_roof_area'] != null ? double.tryParse(json['min_roof_area'].toString()) : null,
      maxRoofArea: json['max_roof_area'] != null ? double.tryParse(json['max_roof_area'].toString()) : null,
      status: json['status']?.toString(),
      hasBasement: json['has_basement'] == true || json['has_basement'] == 1,
      hasGarage: json['has_garage'] == true || json['has_garage'] == 1,
      hasActiveSale: json['has_active_sale'] == true || json['has_active_sale'] == 1,
      location: json['location']?.toString(),
      finishing: json['finishing']?.toString(),
      deliveredAtFrom: json['delivered_at_from']?.toString(),
      deliveredAtTo: json['delivered_at_to']?.toString(),
      hasBeenDelivered: json['has_been_delivered'] == true || json['has_been_delivered'] == 1 ? true : (json['has_been_delivered'] == false || json['has_been_delivered'] == 0 ? false : null),
      hasClub: json['has_club'] == true || json['has_club'] == 1,
      hasRoof: json['has_roof'] == true || json['has_roof'] == 1,
      hasGarden: json['has_garden'] == true || json['has_garden'] == 1,
      sortBy: json['sort_by']?.toString(),
      page: json['page'] != null ? int.tryParse(json['page'].toString()) : null,
      limit: json['limit'] != null ? int.tryParse(json['limit'].toString()) : null,
      unitName: json['unit_name']?.toString(),
      unitType: json['unit_type']?.toString(),
      buildingName: json['building_name']?.toString(),
      stageNumber: json['stage_number']?.toString(),
      floorNumber: json['floor_number'] != null ? int.tryParse(json['floor_number'].toString()) : null,
      compoundId: json['compound_id']?.toString(),
      available: json['available'] == true || json['available'] == 1,
      isSold: json['is_sold'] == true || json['is_sold'] == 1,
      minTotalPricing: json['min_total_pricing'] != null ? double.tryParse(json['min_total_pricing'].toString()) : null,
      maxTotalPricing: json['max_total_pricing'] != null ? double.tryParse(json['max_total_pricing'].toString()) : null,
      minBasementArea: json['min_basement_area'] != null ? double.tryParse(json['min_basement_area'].toString()) : null,
      maxBasementArea: json['max_basement_area'] != null ? double.tryParse(json['max_basement_area'].toString()) : null,
      minGarageArea: json['min_garage_area'] != null ? double.tryParse(json['min_garage_area'].toString()) : null,
      maxGarageArea: json['max_garage_area'] != null ? double.tryParse(json['max_garage_area'].toString()) : null,
      companyId: json['company_id']?.toString(),
      usageType: json['usage_type']?.toString(),
      search: json['search']?.toString(),
    );
  }

  // Create a copy with modified fields
  SearchFilter copyWith({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    int? bedrooms,
    String? finishing,
    String? deliveredAtFrom,
    String? deliveredAtTo,
    bool? hasBeenDelivered,
    bool? hasClub,
    bool? hasRoof,
    bool? hasGarden,
    String? sortBy,
    double? minArea,
    double? maxArea,
    double? minBuiltUpArea,
    double? maxBuiltUpArea,
    double? minLandArea,
    double? maxLandArea,
    double? minGardenArea,
    double? maxGardenArea,
    double? minRoofArea,
    double? maxRoofArea,
    bool? hasBasement,
    bool? hasGarage,
    bool? hasActiveSale,
    String? status,
    int? page,
    int? limit,
    String? unitName,
    String? unitType,
    String? buildingName,
    String? stageNumber,
    int? floorNumber,
    String? compoundId,
    bool? available,
    bool? isSold,
    double? minTotalPricing,
    double? maxTotalPricing,
    double? minBasementArea,
    double? maxBasementArea,
    double? minGarageArea,
    double? maxGarageArea,
    String? companyId,
    String? usageType,
    String? search,
    bool clearLocation = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearPropertyType = false,
    bool clearBedrooms = false,
    bool clearFinishing = false,
    bool clearDeliveredAtFrom = false,
    bool clearDeliveredAtTo = false,
    bool clearHasBeenDelivered = false,
    bool clearHasClub = false,
    bool clearHasRoof = false,
    bool clearHasGarden = false,
    bool clearSortBy = false,
    bool clearMinArea = false,
    bool clearMaxArea = false,
    bool clearMinGardenArea = false,
    bool clearMaxGardenArea = false,
    bool clearMinRoofArea = false,
    bool clearMaxRoofArea = false,
    bool clearHasBasement = false,
    bool clearHasGarage = false,
    bool clearStatus = false,
    bool clearPage = false,
    bool clearLimit = false,
    bool clearUnitName = false,
    bool clearUnitType = false,
    bool clearBuildingName = false,
    bool clearStageNumber = false,
    bool clearFloorNumber = false,
    bool clearCompoundId = false,
    bool clearAvailable = false,
    bool clearIsSold = false,
    bool clearMinTotalPricing = false,
    bool clearMaxTotalPricing = false,
    bool clearMinBasementArea = false,
    bool clearMaxBasementArea = false,
    bool clearMinGarageArea = false,
    bool clearMaxGarageArea = false,
    bool clearCompanyId = false,
    bool clearUsageType = false,
    bool clearSearch = false,
  }) {
    return SearchFilter(
      location: clearLocation ? null : (location ?? this.location),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      bedrooms: clearBedrooms ? null : (bedrooms ?? this.bedrooms),
      finishing: clearFinishing ? null : (finishing ?? this.finishing),
      deliveredAtFrom: clearDeliveredAtFrom ? null : (deliveredAtFrom ?? this.deliveredAtFrom),
      deliveredAtTo: clearDeliveredAtTo ? null : (deliveredAtTo ?? this.deliveredAtTo),
      hasBeenDelivered: clearHasBeenDelivered ? null : (hasBeenDelivered ?? this.hasBeenDelivered),
      hasClub: clearHasClub ? null : (hasClub ?? this.hasClub),
      hasRoof: clearHasRoof ? null : (hasRoof ?? this.hasRoof),
      hasGarden: clearHasGarden ? null : (hasGarden ?? this.hasGarden),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      minArea: clearMinArea ? null : (minArea ?? this.minArea),
      maxArea: clearMaxArea ? null : (maxArea ?? this.maxArea),
      minBuiltUpArea: minBuiltUpArea ?? this.minBuiltUpArea,
      maxBuiltUpArea: maxBuiltUpArea ?? this.maxBuiltUpArea,
      minLandArea: minLandArea ?? this.minLandArea,
      maxLandArea: maxLandArea ?? this.maxLandArea,
      minGardenArea: clearMinGardenArea ? null : (minGardenArea ?? this.minGardenArea),
      maxGardenArea: clearMaxGardenArea ? null : (maxGardenArea ?? this.maxGardenArea),
      minRoofArea: clearMinRoofArea ? null : (minRoofArea ?? this.minRoofArea),
      maxRoofArea: clearMaxRoofArea ? null : (maxRoofArea ?? this.maxRoofArea),
      hasBasement: clearHasBasement ? null : (hasBasement ?? this.hasBasement),
      hasGarage: clearHasGarage ? null : (hasGarage ?? this.hasGarage),
      hasActiveSale: hasActiveSale ?? this.hasActiveSale,
      status: clearStatus ? null : (status ?? this.status),
      page: clearPage ? null : (page ?? this.page),
      limit: clearLimit ? null : (limit ?? this.limit),
      unitName: clearUnitName ? null : (unitName ?? this.unitName),
      unitType: clearUnitType ? null : (unitType ?? this.unitType),
      buildingName: clearBuildingName ? null : (buildingName ?? this.buildingName),
      stageNumber: clearStageNumber ? null : (stageNumber ?? this.stageNumber),
      floorNumber: clearFloorNumber ? null : (floorNumber ?? this.floorNumber),
      compoundId: clearCompoundId ? null : (compoundId ?? this.compoundId),
      available: clearAvailable ? null : (available ?? this.available),
      isSold: clearIsSold ? null : (isSold ?? this.isSold),
      minTotalPricing: clearMinTotalPricing ? null : (minTotalPricing ?? this.minTotalPricing),
      maxTotalPricing: clearMaxTotalPricing ? null : (maxTotalPricing ?? this.maxTotalPricing),
      minBasementArea: clearMinBasementArea ? null : (minBasementArea ?? this.minBasementArea),
      maxBasementArea: clearMaxBasementArea ? null : (maxBasementArea ?? this.maxBasementArea),
      minGarageArea: clearMinGarageArea ? null : (minGarageArea ?? this.minGarageArea),
      maxGarageArea: clearMaxGarageArea ? null : (maxGarageArea ?? this.maxGarageArea),
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      usageType: clearUsageType ? null : (usageType ?? this.usageType),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  String toString() {
    return 'SearchFilter(location: $location, minPrice: $minPrice, maxPrice: $maxPrice, '
        'propertyType: $propertyType, bedrooms: $bedrooms, finishing: $finishing, '
        'hasClub: $hasClub, hasRoof: $hasRoof, '
        'hasGarden: $hasGarden, sortBy: $sortBy, minArea: $minArea, maxArea: $maxArea, '
        'minGardenArea: $minGardenArea, maxGardenArea: $maxGardenArea, '
        'minRoofArea: $minRoofArea, maxRoofArea: $maxRoofArea, '
        'hasBasement: $hasBasement, hasGarage: $hasGarage, status: $status, '
        'page: $page, limit: $limit, unitName: $unitName, unitType: $unitType, '
        'buildingName: $buildingName, stageNumber: $stageNumber, floorNumber: $floorNumber, '
        'compoundId: $compoundId, available: $available, isSold: $isSold, '
        'minTotalPricing: $minTotalPricing, maxTotalPricing: $maxTotalPricing, '
        'minBasementArea: $minBasementArea, maxBasementArea: $maxBasementArea, '
        'minGarageArea: $minGarageArea, maxGarageArea: $maxGarageArea)';
  }
}
