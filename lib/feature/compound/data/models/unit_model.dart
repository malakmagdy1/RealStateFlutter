import 'package:equatable/equatable.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';

/// Model for payment plan data from API
class PaymentPlan {
  final int? id;
  final String? planName;
  final String? price;
  final String? durationYears;
  final String? deliveryDate;
  final String? finishingType;
  final String? totalArea;
  final String? downPaymentPercentage;
  final String? downPaymentAmount;
  final String? monthlyInstallment;
  final String? quarterlyInstallment;
  final String? semiAnnualInstallment;
  final String? yearlyInstallment;
  final String? maintenanceDeposit;
  final String? clubMembership;
  final String? garagePrice;
  final String? storagePrice;
  final String? unitTotalPrice;
  final String? finishPrice;
  final String? unitTotalWithFinishPrice;
  final String? createdAt;
  final String? updatedAt;

  PaymentPlan({
    this.id,
    this.planName,
    this.price,
    this.durationYears,
    this.deliveryDate,
    this.finishingType,
    this.totalArea,
    this.downPaymentPercentage,
    this.downPaymentAmount,
    this.monthlyInstallment,
    this.quarterlyInstallment,
    this.semiAnnualInstallment,
    this.yearlyInstallment,
    this.maintenanceDeposit,
    this.clubMembership,
    this.garagePrice,
    this.storagePrice,
    this.unitTotalPrice,
    this.finishPrice,
    this.unitTotalWithFinishPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] as int?,
      planName: json['plan_name']?.toString(),
      price: json['price']?.toString(),
      durationYears: json['duration_years']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      finishingType: json['finishing_type']?.toString(),
      totalArea: json['total_area']?.toString(),
      downPaymentPercentage: json['down_payment_percentage']?.toString(),
      downPaymentAmount: json['down_payment_amount']?.toString(),
      monthlyInstallment: json['monthly_installment']?.toString(),
      quarterlyInstallment: json['quarterly_installment']?.toString(),
      semiAnnualInstallment: json['semi_annual_installment']?.toString(),
      yearlyInstallment: json['yearly_installment']?.toString(),
      maintenanceDeposit: json['maintenance_deposit']?.toString(),
      clubMembership: json['club_membership']?.toString(),
      garagePrice: json['garage_price']?.toString(),
      storagePrice: json['storage_price']?.toString(),
      unitTotalPrice: json['unit_total_price']?.toString(),
      finishPrice: json['finish_price']?.toString(),
      unitTotalWithFinishPrice: json['unit_total_with_finish_price']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'price': price,
      'duration_years': durationYears,
      'delivery_date': deliveryDate,
      'finishing_type': finishingType,
      'total_area': totalArea,
      'down_payment_percentage': downPaymentPercentage,
      'down_payment_amount': downPaymentAmount,
      'monthly_installment': monthlyInstallment,
      'quarterly_installment': quarterlyInstallment,
      'semi_annual_installment': semiAnnualInstallment,
      'yearly_installment': yearlyInstallment,
      'maintenance_deposit': maintenanceDeposit,
      'club_membership': clubMembership,
      'garage_price': garagePrice,
      'storage_price': storagePrice,
      'unit_total_price': unitTotalPrice,
      'finish_price': finishPrice,
      'unit_total_with_finish_price': unitTotalWithFinishPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Unit extends Equatable {
  final String id;
  final String compoundId;
  final String unitType;
  final String area;
  final String price;
  final String bedrooms;
  final String bathrooms;
  final String floor;
  final String status;
  final String? unitNumber;
  final String? deliveryDate;
  final String? view;
  final String? finishing;
  final String createdAt;
  final String updatedAt;
  final List<String> images;

  // New fields
  final String? buildingName;
  final String? gardenArea;
  final String? roofArea;
  final String? usageType;
  final String? salesNumber;
  final String? companyLogo;
  final String? companyName;
  final String? companyId;
  final String? compoundName;
  final String? compoundLocation;
  final String? compoundLocationEn;
  final String? compoundLocationAr;
  final String? compoundLocationUrl;

  /// Get localized compound location based on locale
  String? getLocalizedCompoundLocation(bool isArabic) {
    if (isArabic) {
      return (compoundLocationAr?.isNotEmpty == true) ? compoundLocationAr : compoundLocation;
    }
    return (compoundLocationEn?.isNotEmpty == true) ? compoundLocationEn : compoundLocation;
  }

  // Additional fields from search API
  final String? code;
  final String? originalPrice;
  final String? discountedPrice;
  final String? discountPercentage;
  final bool? available;
  final bool? isSold;
  final String? totalPrice;
  final String? normalPrice;
  final String? builtUpArea;
  final String? landArea;

  // Favorite fields
  final int? favoriteId;
  final String? notes;
  final int? noteId; // ID of the note in the notes table

  // Update tracking fields
  final bool? isUpdated;
  final String? lastChangedAt;
  final String? changeType; // 'new', 'updated', 'deleted'
  final List<String>? changedFields;
  final Map<String, dynamic>? changeProperties; // Contains 'changes' and 'original' from API

  // Sale fields
  final bool? hasActiveSale;
  final Sale? sale;

  // Payment plans
  final List<PaymentPlan>? paymentPlans;

  Unit({
    required this.id,
    required this.compoundId,
    required this.unitType,
    required this.area,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.floor,
    required this.status,
    this.unitNumber,
    this.deliveryDate,
    this.view,
    this.finishing,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    // New fields
    this.buildingName,
    this.gardenArea,
    this.roofArea,
    this.usageType,
    this.salesNumber,
    this.companyLogo,
    this.companyName,
    this.companyId,
    this.compoundName,
    this.compoundLocation,
    this.compoundLocationEn,
    this.compoundLocationAr,
    this.compoundLocationUrl,
    // Additional fields from search API
    this.code,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.available,
    this.isSold,
    this.totalPrice,
    this.normalPrice,
    this.builtUpArea,
    this.landArea,
    // Favorite fields
    this.favoriteId,
    this.notes,
    this.noteId,
    // Update tracking fields
    this.isUpdated,
    this.lastChangedAt,
    this.changeType,
    this.changedFields,
    this.changeProperties,
    // Sale fields
    this.hasActiveSale,
    this.sale,
    // Payment plans
    this.paymentPlans,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    // Helper function to get non-empty string from JSON field
    String? getNonEmptyString(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      return str.isNotEmpty && str != 'null' ? str : null;
    }

    // Parse images array
    List<String> imagesList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((img) => img.toString())
            .toList();

        print('================================');
        print('[UNIT MODEL] Unit ID: ${json['id']}');
        print('[UNIT MODEL] Total images from API: ${imagesList.length}');
        for (int i = 0; i < imagesList.length; i++) {
          print('[UNIT MODEL] Image $i: ${imagesList[i]}');
        }
        print('================================');
      }
    }

    // Handle area - use total_area or calculate from various area fields
    String area = '0';
    final totalArea = getNonEmptyString(json['total_area']);
    final builtUpArea = getNonEmptyString(json['built_up_area']);
    final regularArea = getNonEmptyString(json['area']);

    print('[UNIT MODEL] Unit ${json['id']} - Area parsing:');
    print('[UNIT MODEL]   total_area: ${json['total_area']} -> $totalArea');
    print('[UNIT MODEL]   built_up_area: ${json['built_up_area']} -> $builtUpArea');
    print('[UNIT MODEL]   area: ${json['area']} -> $regularArea');

    if (totalArea != null && totalArea != '0' && totalArea != '0.00') {
      area = totalArea;
    } else if (builtUpArea != null && builtUpArea != '0' && builtUpArea != '0.00') {
      area = builtUpArea;
    } else if (regularArea != null && regularArea != '0' && regularArea != '0.00') {
      area = regularArea;
    }
    print('[UNIT MODEL]   Final area: $area');

    // Handle price - use various pricing fields
    String price = '0';
    if (json['unit_total_with_finish_price'] != null && json['unit_total_with_finish_price'].toString() != '0') {
      price = json['unit_total_with_finish_price'].toString();
    } else if (json['total_pricing'] != null && json['total_pricing'].toString() != '0') {
      price = json['total_pricing'].toString();
    } else if (json['normal_price'] != null && json['normal_price'].toString() != '0') {
      price = json['normal_price'].toString();
    } else if (json['price'] != null) {
      price = json['price'].toString();
    }

    // Parse update tracking fields from API
    String? changeType = json['change_type']?.toString();
    // Check both variations: last_changed_at and last_change_at
    String? lastChangedAt = json['last_changed_at']?.toString() ?? json['last_change_at']?.toString();
    List<String>? changedFields = json['changed_fields'] != null
        ? (json['changed_fields'] as List).map((e) => e.toString()).toList()
        : null;
    Map<String, dynamic>? changeProperties = json['change_properties'] != null
        ? Map<String, dynamic>.from(json['change_properties'] as Map)
        : null;
    // Set isUpdated to true if API sends it OR if changeType exists
    bool isUpdated = json['is_updated'] == true || json['is_updated'] == 1 || changeType != null;

    if (changeType != null) {
      print('[UNIT MODEL] Parsing unit with changeType=$changeType, isUpdated=$isUpdated, changeProperties=$changeProperties');
    }

    // Parse sale data if available
    Sale? sale;
    bool hasActiveSale = json['has_active_sale'] == true || json['has_active_sale'] == 1;

    print('[UNIT MODEL] ========================================');
    print('[UNIT MODEL] Parsing unit ID: ${json['id']}');
    print('[UNIT MODEL] has_active_sale: $hasActiveSale');
    print('[UNIT MODEL] sale data present: ${json['sale'] != null}');

    if (json['sale'] != null && json['sale'] is Map<String, dynamic>) {
      try {
        final saleJson = Map<String, dynamic>.from(json['sale'] as Map<String, dynamic>);
        print('[UNIT MODEL] Sale JSON: $saleJson');
        print('[UNIT MODEL] Sale old_price: ${saleJson['old_price']}');
        print('[UNIT MODEL] Sale new_price: ${saleJson['new_price']}');
        print('[UNIT MODEL] Sale discount_percentage: ${saleJson['discount_percentage']}');

        // If old_price and new_price are not in the sale, calculate them from unit price
        if ((saleJson['old_price'] == null || saleJson['old_price'] == 0) &&
            (saleJson['new_price'] == null || saleJson['new_price'] == 0)) {

          print('[UNIT MODEL] Sale prices are missing/0, calculating from unit data...');
          print('[UNIT MODEL] Unit original_price: ${json['original_price']}');
          print('[UNIT MODEL] Unit normal_price: ${json['normal_price']}');
          print('[UNIT MODEL] Unit price (calculated): $price');

          // Try to get the best price from unit data
          double unitPrice = 0.0;

          // Priority: original_price > normal_price > price
          if (json['original_price'] != null) {
            unitPrice = double.tryParse(json['original_price'].toString()) ?? 0.0;
            print('[UNIT MODEL] Using original_price: $unitPrice');
          } else if (json['normal_price'] != null) {
            unitPrice = double.tryParse(json['normal_price'].toString()) ?? 0.0;
            print('[UNIT MODEL] Using normal_price: $unitPrice');
          } else if (price.isNotEmpty) {
            unitPrice = double.tryParse(price) ?? 0.0;
            print('[UNIT MODEL] Using price: $unitPrice');
          }

          final discountPercent = saleJson['discount_percentage'] is num
              ? (saleJson['discount_percentage'] as num).toDouble()
              : double.tryParse(saleJson['discount_percentage']?.toString() ?? '0') ?? 0.0;

          print('[UNIT MODEL] Unit price to use: $unitPrice');
          print('[UNIT MODEL] Discount percentage: $discountPercent');

          if (unitPrice > 0 && discountPercent > 0) {
            saleJson['old_price'] = unitPrice;
            saleJson['new_price'] = unitPrice * (1 - (discountPercent / 100));
            saleJson['savings'] = unitPrice * (discountPercent / 100);
            print('[UNIT MODEL] ✓ Calculated sale prices:');
            print('[UNIT MODEL]   Old: ${saleJson['old_price']}');
            print('[UNIT MODEL]   New: ${saleJson['new_price']}');
            print('[UNIT MODEL]   Savings: ${saleJson['savings']}');
          } else {
            print('[UNIT MODEL] ✗ Cannot calculate prices - unitPrice: $unitPrice, discount: $discountPercent');
          }
        } else {
          print('[UNIT MODEL] Sale already has prices - old: ${saleJson['old_price']}, new: ${saleJson['new_price']}');
        }

        sale = Sale.fromJson(saleJson);
        print('[UNIT MODEL] ✓ Sale object created successfully');
      } catch (e) {
        print('[UNIT MODEL] ✗ Error parsing sale: $e');
      }
    } else {
      print('[UNIT MODEL] No sale data in unit JSON');
    }
    print('[UNIT MODEL] ========================================');

    // Parse payment plans
    List<PaymentPlan>? paymentPlansList;
    if (json['payment_plans'] != null && json['payment_plans'] is List) {
      paymentPlansList = (json['payment_plans'] as List)
          .map((plan) => PaymentPlan.fromJson(plan as Map<String, dynamic>))
          .toList();
      print('[UNIT MODEL] Parsed ${paymentPlansList.length} payment plans');
    }

    // Parse delivery date - check multiple field names
    final deliveredAt = getNonEmptyString(json['delivered_at']);
    final deliveryDateField = getNonEmptyString(json['delivery_date']);
    final plannedDelivery = getNonEmptyString(json['planned_delivery_date']);
    final deliveryDate = deliveredAt ?? deliveryDateField ?? plannedDelivery;

    print('[UNIT MODEL] Unit ${json['id']} - Delivery date parsing:');
    print('[UNIT MODEL]   delivered_at: ${json['delivered_at']} -> $deliveredAt');
    print('[UNIT MODEL]   delivery_date: ${json['delivery_date']} -> $deliveryDateField');
    print('[UNIT MODEL]   planned_delivery_date: ${json['planned_delivery_date']} -> $plannedDelivery');
    print('[UNIT MODEL]   Final deliveryDate: $deliveryDate');

    // Parse finishing type
    final finishingType = getNonEmptyString(json['finishing_type']) ?? getNonEmptyString(json['finishing']);
    print('[UNIT MODEL] Unit ${json['id']} - Finishing: ${json['finishing_type']} -> $finishingType');

    return Unit(
      id: json['id']?.toString() ?? '',
      compoundId: json['compound_id']?.toString() ?? '',
      // Use localized unit type if available, fallback to original
      unitType:
          json['unit_type_localized']?.toString() ??
          json['unit_type']?.toString() ??
          json['usage_type_localized']?.toString() ??
          json['usage_type']?.toString() ?? '',
      area: area,
      price: price,
      bedrooms:
          json['number_of_beds']?.toString() ??
          json['bedrooms']?.toString() ??
          '0',
      bathrooms:
          json['number_of_bathrooms']?.toString() ??
          json['bathrooms']?.toString() ??
          '0',
      floor:
          json['floor_number']?.toString() ?? json['floor']?.toString() ?? '0',
      // Use localized status if available, fallback to original
      status: json['status_localized']?.toString() ?? json['status']?.toString() ?? 'available',
      unitNumber:
          json['unit_name_localized']?.toString() ??
          json['unit_name']?.toString() ??
          json['unit_number']?.toString() ??
          json['unit_code']?.toString(),
      deliveryDate: deliveryDate,
      view: getNonEmptyString(json['view']),
      finishing: finishingType,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      images: imagesList,
      // New fields
      buildingName: json['building_name']?.toString(),
      gardenArea: json['garden_area']?.toString(),
      roofArea: json['roof_area']?.toString(),
      // Use localized usage type if available
      usageType: json['usage_type_localized']?.toString() ?? json['usage_type']?.toString(),
      salesNumber:
          json['sales_number']?.toString() ?? json['sales_phone']?.toString(),
      companyLogo: json['company_logo']?.toString(),
      companyName: json['company_name']?.toString(),
      companyId: json['company_id']?.toString(),
      // Extract compound name from either direct field or nested compound object
      compoundName: json['compound_name']?.toString() ??
                    (json['compound'] != null ? json['compound']['name']?.toString() : null),
      // Extract compound location from either direct field or nested compound object
      compoundLocation: json['compound_location']?.toString() ??
                        (json['compound'] != null ? json['compound']['location']?.toString() : null),
      // Extract localized compound location from nested compound object
      compoundLocationEn: json['compound_location_en']?.toString() ??
                          (json['compound'] != null ? json['compound']['location_en']?.toString() : null),
      compoundLocationAr: json['compound_location_ar']?.toString() ??
                          (json['compound'] != null ? json['compound']['location_ar']?.toString() : null),
      // Extract compound location URL from either direct field or nested compound object
      compoundLocationUrl: json['compound_location_url']?.toString() ??
                           (json['compound'] != null ? json['compound']['location_url']?.toString() : null),
      // Additional fields from search API
      code: json['code']?.toString() ?? json['unit_code']?.toString(),
      originalPrice: json['original_price']?.toString(),
      discountedPrice: json['discounted_price']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      available: json['available'] is bool ? json['available'] as bool? : (json['available'] == 1 || json['available'] == true),
      isSold: json['is_sold'] is bool ? json['is_sold'] as bool? : (json['is_sold'] == 1 || json['is_sold'] == true),
      totalPrice: json['total_price']?.toString(),
      normalPrice: json['normal_price']?.toString(),
      builtUpArea: json['built_up_area']?.toString(),
      landArea: json['land_area']?.toString(),
      // Favorite fields
      favoriteId: json['favorite_id'] as int?,
      notes: json['notes'] as String?,
      noteId: json['note_id'] as int?,
      // Update tracking fields (using test data if available)
      isUpdated: isUpdated,
      lastChangedAt: lastChangedAt,
      changeType: changeType,
      changedFields: changedFields,
      changeProperties: changeProperties,
      // Sale fields
      hasActiveSale: hasActiveSale,
      sale: sale,
      // Payment plans
      paymentPlans: paymentPlansList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compound_id': compoundId,
      'unit_type': unitType,
      'area': area,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor': floor,
      'status': status,
      'unit_number': unitNumber,
      'delivery_date': deliveryDate,
      'view': view,
      'finishing': finishing,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'images': images,
      'building_name': buildingName,
      'garden_area': gardenArea,
      'roof_area': roofArea,
      'usage_type': usageType,
      'sales_number': salesNumber,
      'company_logo': companyLogo,
      'company_name': companyName,
      'company_id': companyId,
      'compound_name': compoundName,
      'compound_location': compoundLocation,
      'compound_location_en': compoundLocationEn,
      'compound_location_ar': compoundLocationAr,
      'compound_location_url': compoundLocationUrl,
      'code': code,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'discount_percentage': discountPercentage,
      'available': available,
      'is_sold': isSold,
      'total_price': totalPrice,
      'normal_price': normalPrice,
      'built_up_area': builtUpArea,
      'land_area': landArea,
      'favorite_id': favoriteId,
      'notes': notes,
      'note_id': noteId,
      // Update tracking fields
      'is_updated': isUpdated,
      'last_changed_at': lastChangedAt,
      'change_type': changeType,
      'changed_fields': changedFields,
      'change_properties': changeProperties,
      // Sale fields
      'has_active_sale': hasActiveSale,
      'sale': sale?.toJson(),
      // Payment plans
      'payment_plans': paymentPlans?.map((plan) => plan.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    compoundId,
    unitType,
    area,
    price,
    bedrooms,
    bathrooms,
    floor,
    status,
    unitNumber,
    deliveryDate,
    view,
    finishing,
    createdAt,
    updatedAt,
    images,
    buildingName,
    gardenArea,
    roofArea,
    usageType,
    salesNumber,
    companyLogo,
    companyName,
    companyId,
    compoundName,
    compoundLocation,
    compoundLocationUrl,
    code,
    originalPrice,
    discountedPrice,
    discountPercentage,
    available,
    isSold,
    totalPrice,
    normalPrice,
    builtUpArea,
    landArea,
    favoriteId,
    notes,
    noteId,
    isUpdated,
    lastChangedAt,
    changeType,
    changedFields,
    changeProperties,
    hasActiveSale,
    sale,
    paymentPlans,
  ];

  @override
  String toString() {
    return 'Unit{id: $id, unitType: $unitType, area: $area, price: $price, status: $status}';
  }
}

class UnitResponse {
  final bool success;
  final int count;
  final int total;
  final List<Unit> data;

  UnitResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.data,
  });

  factory UnitResponse.fromJson(Map<String, dynamic> json) {
    List<Unit> unitsList = [];
    if (json['data'] != null && json['data'] is List) {
      // Parse units and filter out invalid/unavailable/sold ones
      unitsList = (json['data'] as List)
          .map((unit) {
            try {
              return Unit.fromJson(unit as Map<String, dynamic>);
            } catch (e) {
              print('[UNIT RESPONSE] Error parsing unit: $e');
              return null;
            }
          })
          .whereType<Unit>() // Remove null values
          .where((unit) => _isValidUnit(unit)) // Filter out invalid units
          .toList();
    }

    return UnitResponse(
      success: json['success'] ?? false,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      data: unitsList,
    );
  }

  /// Validate that a unit has essential data and is available
  static bool _isValidUnit(Unit unit) {
    // Must have a valid ID (not empty, not '0', not 'null')
    if (unit.id.isEmpty || unit.id == '0' || unit.id.toLowerCase() == 'null') {
      print('[UNIT RESPONSE] ✗ Skipping unit with invalid ID: ${unit.id}');
      return false;
    }

    // Must have a valid compound ID
    if (unit.compoundId.isEmpty || unit.compoundId == '0') {
      print('[UNIT RESPONSE] ✗ Skipping unit ${unit.id} with invalid compound ID');
      return false;
    }

    // Must be available (if available field exists)
    if (unit.available != null && unit.available == false) {
      print('[UNIT RESPONSE] ✗ Skipping unit ${unit.id} - not available');
      return false;
    }

    // Must not be sold (if isSold field exists)
    if (unit.isSold != null && unit.isSold == true) {
      print('[UNIT RESPONSE] ✗ Skipping unit ${unit.id} - already sold');
      return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'total': total,
      'data': data.map((unit) => unit.toJson()).toList(),
    };
  }
}
