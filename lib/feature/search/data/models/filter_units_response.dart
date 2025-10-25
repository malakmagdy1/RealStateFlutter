import 'dart:io' show Platform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FilterUnitsResponse extends Equatable {
  final bool success;
  final int totalUnits;
  final int page;
  final int limit;
  final int totalPages;
  final List<String> filtersApplied;
  final List<FilteredUnit> units;

  FilterUnitsResponse({
    required this.success,
    required this.totalUnits,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.filtersApplied,
    required this.units,
  });

  factory FilterUnitsResponse.fromJson(Map<String, dynamic> json) {
    List<FilteredUnit> unitsList = [];

    // Try 'units' or 'data' field for the units array
    final unitsData = json['units'] ?? json['data'];
    if (unitsData != null && unitsData is List) {
      unitsList = (unitsData as List)
          .map((unit) => FilteredUnit.fromJson(unit as Map<String, dynamic>))
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
      totalUnits: json['total_units'] ?? json['total'] ?? unitsList.length,
      page: json['page'] ?? json['current_page'] ?? 1,
      limit: json['limit'] ?? json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? json['last_page'] ?? 1,
      filtersApplied: filtersList,
      units: unitsList,
    );
  }

  @override
  List<Object?> get props => [success, totalUnits, page, limit, totalPages, filtersApplied, units];
}

class FilteredUnit extends Equatable {
  final String id;
  final String compoundId;
  final String compoundName;
  final String compoundLocation;
  final String companyId;
  final String companyName;
  final String? companyLogo;
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

  FilteredUnit({
    required this.id,
    required this.compoundId,
    required this.compoundName,
    required this.compoundLocation,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
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
  });

  factory FilteredUnit.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => _fixImageUrl(img.toString()))
          .toList();
    }

    String? companyLogo = json['company_logo']?.toString();
    if (companyLogo != null && companyLogo.isNotEmpty) {
      companyLogo = _fixImageUrl(companyLogo);
    }

    return FilteredUnit(
      id: json['id']?.toString() ?? '',
      compoundId: json['compound_id']?.toString() ?? '',
      compoundName: json['compound_name']?.toString() ?? '',
      compoundLocation: json['compound_location']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      companyLogo: companyLogo,
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
      normalPrice: json['normal_price']?.toString() ?? '0',
      totalPricing: json['total_pricing']?.toString() ?? '0',
      totalArea: double.tryParse(json['total_area']?.toString() ?? '0') ?? 0.0,
      available: json['available'] == true || json['available']?.toString() == '1',
      isSold: json['is_sold'] == true || json['is_sold']?.toString() == '1',
      deliveredAt: json['delivered_at']?.toString(),
      images: imagesList,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
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
      ];
}
