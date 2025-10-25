import 'package:equatable/equatable.dart';

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
    if (json['unit_total_with_finish_price'] != null) {
      price = json['unit_total_with_finish_price'].toString();
    } else if (json['total_pricing'] != null) {
      price = json['total_pricing'].toString();
    } else if (json['price'] != null) {
      price = json['price'].toString();
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
