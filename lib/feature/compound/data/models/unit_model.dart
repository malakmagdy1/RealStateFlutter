import 'package:equatable/equatable.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';

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

  // Sale fields
  final bool? hasActiveSale;
  final Sale? sale;

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
    // Sale fields
    this.hasActiveSale,
    this.sale,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
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
    if (json['total_area'] != null && json['total_area'].toString() != '0') {
      area = json['total_area'].toString();
    } else if (json['area'] != null) {
      area = json['area'].toString();
    }

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

    // TEMPORARY TEST: Force first 3 units to show update badges for testing
    bool isUpdated = json['is_updated'] == true || json['is_updated'] == 1;
    String? changeType = json['change_type']?.toString();
    String? lastChangedAt = json['last_changed_at']?.toString();
    List<String>? changedFields = json['changed_fields'] != null
        ? (json['changed_fields'] as List).map((e) => e.toString()).toList()
        : null;

    // TEST DATA - Remove this after testing
    final unitId = json['id']?.toString() ?? '';
    if (unitId.isNotEmpty) {
      final idNum = int.tryParse(unitId) ?? 0;
      if (idNum % 3 == 1) {
        // Every 3rd unit starting from 1: NEW
        isUpdated = true;
        changeType = 'new';
        lastChangedAt = DateTime.now().subtract(Duration(hours: 2)).toIso8601String();
        changedFields = ['price', 'status'];
      } else if (idNum % 3 == 2) {
        // Every 3rd unit starting from 2: UPDATED
        isUpdated = true;
        changeType = 'updated';
        lastChangedAt = DateTime.now().subtract(Duration(days: 1)).toIso8601String();
        changedFields = ['price'];
      }
    }
    // END TEST DATA

    // Parse sale data if available
    Sale? sale;
    bool hasActiveSale = json['has_active_sale'] == true || json['has_active_sale'] == 1;

    if (json['sale'] != null && json['sale'] is Map<String, dynamic>) {
      try {
        final saleJson = Map<String, dynamic>.from(json['sale'] as Map<String, dynamic>);

        // If old_price and new_price are not in the sale, calculate them from unit price
        if ((saleJson['old_price'] == null || saleJson['old_price'] == 0) &&
            (saleJson['new_price'] == null || saleJson['new_price'] == 0)) {
          final unitPrice = double.tryParse(price) ?? 0.0;
          final discountPercent = saleJson['discount_percentage'] is num
              ? (saleJson['discount_percentage'] as num).toDouble()
              : double.tryParse(saleJson['discount_percentage']?.toString() ?? '0') ?? 0.0;

          if (unitPrice > 0 && discountPercent > 0) {
            saleJson['old_price'] = unitPrice;
            saleJson['new_price'] = unitPrice * (1 - (discountPercent / 100));
            saleJson['savings'] = unitPrice * (discountPercent / 100);
          }
        }

        sale = Sale.fromJson(saleJson);
      } catch (e) {
        print('[UNIT MODEL] Error parsing sale: $e');
      }
    }

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
      bathrooms: json['bathrooms']?.toString() ?? '0',
      floor:
          json['floor_number']?.toString() ?? json['floor']?.toString() ?? '0',
      // Use localized status if available, fallback to original
      status: json['status_localized']?.toString() ?? json['status']?.toString() ?? 'available',
      unitNumber:
          json['unit_name_localized']?.toString() ??
          json['unit_name']?.toString() ??
          json['unit_number']?.toString() ??
          json['unit_code']?.toString(),
      deliveryDate:
          json['delivered_at']?.toString() ?? json['delivery_date']?.toString(),
      view: json['view']?.toString(),
      finishing: json['finishing']?.toString(),
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
      // Sale fields
      hasActiveSale: hasActiveSale,
      sale: sale,
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
      'code': code,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'discount_percentage': discountPercentage,
      'available': available,
      'is_sold': isSold,
      'total_price': totalPrice,
      'built_up_area': builtUpArea,
      'land_area': landArea,
      'favorite_id': favoriteId,
      'notes': notes,
      'has_active_sale': hasActiveSale,
      'sale': sale?.toJson(),
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
    hasActiveSale,
    sale,
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
      unitsList = (json['data'] as List)
          .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
          .toList();
    }

    return UnitResponse(
      success: json['success'] ?? false,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      data: unitsList,
    );
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
