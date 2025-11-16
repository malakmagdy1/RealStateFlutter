import 'dart:io' show Platform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SearchResponse extends Equatable {
  final bool status;
  final String searchQuery;
  final int totalResults;
  final List<SearchResult> results;

  SearchResponse({
    required this.status,
    required this.searchQuery,
    required this.totalResults,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    List<SearchResult> resultsList = [];

    // Try 'results' or 'data' field for the results array
    final resultsData = json['results'] ?? json['data'];
    if (resultsData != null && resultsData is List) {
      // Parse results and filter out invalid ones
      resultsList = resultsData
          .map((result) {
            try {
              return SearchResult.fromJson(result as Map<String, dynamic>);
            } catch (e) {
              print('[SEARCH RESPONSE] Error parsing result: $e');
              return null;
            }
          })
          .whereType<SearchResult>() // Remove null values
          .where((result) => _isValidSearchResult(result)) // Filter out invalid results
          .toList();
    }

    return SearchResponse(
      status: json['status'] ?? json['success'] ?? true,
      searchQuery: json['search_query'] ?? json['query'] ?? json['search'] ?? '',
      totalResults: int.tryParse(json['total_results']?.toString() ?? json['total']?.toString() ?? '0') ?? resultsList.length,
      results: resultsList,
    );
  }

  /// Validate that a search result has essential data
  static bool _isValidSearchResult(SearchResult result) {
    // Must have a valid ID (not empty, not '0', not 'null')
    if (result.id.isEmpty || result.id == '0' || result.id.toLowerCase() == 'null') {
      print('[SEARCH RESPONSE] ✗ Skipping result with invalid ID: ${result.id}');
      return false;
    }

    // Must have a valid name
    if (result.name.isEmpty || result.name.toLowerCase() == 'null') {
      print('[SEARCH RESPONSE] ✗ Skipping result ${result.id} with no name');
      return false;
    }

    // Must have a valid type
    if (result.type.isEmpty || !['company', 'compound', 'unit'].contains(result.type)) {
      print('[SEARCH RESPONSE] ✗ Skipping result ${result.id} with invalid type: ${result.type}');
      return false;
    }

    // If it's a unit, check sold status
    if (result.type == 'unit' && result.data is UnitSearchData) {
      final unitData = result.data as UnitSearchData;

      // Skip only if explicitly sold
      if (unitData.status.toLowerCase() == 'sold' || unitData.isSold) {
        print('[SEARCH RESPONSE] ✗ Skipping unit ${result.id} (${result.name}) - already sold');
        return false;
      }

      // Note: We removed the 'available' check because backend may not set it correctly
      // Units should be shown unless explicitly sold
      print('[SEARCH RESPONSE] ✓ Including unit ${result.id} (${result.name}) - Status: ${unitData.status}');
    }

    return true;
  }

  @override
  List<Object?> get props => [status, searchQuery, totalResults, results];
}

class SearchResult extends Equatable {
  final String type; // company, compound, or unit
  final String id;
  final String name;
  final dynamic data; // CompanySearchData, CompoundSearchData, or UnitSearchData

  SearchResult({
    required this.type,
    required this.id,
    required this.name,
    required this.data,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    dynamic data;

    switch (type) {
      case 'company':
        data = CompanySearchData.fromJson(json);
        break;
      case 'compound':
        data = CompoundSearchData.fromJson(json);
        break;
      case 'unit':
        data = UnitSearchData.fromJson(json);
        break;
      default:
        data = null;
    }

    return SearchResult(
      type: type,
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      data: data,
    );
  }

  @override
  List<Object?> get props => [type, id, name, data];
}

class CompanySearchData extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? logo;
  final String numberOfCompounds;
  final String numberOfAvailableUnits;
  final String compoundsCount;
  final String? createdAt;

  CompanySearchData({
    required this.id,
    required this.name,
    required this.email,
    this.logo,
    required this.numberOfCompounds,
    required this.numberOfAvailableUnits,
    required this.compoundsCount,
    this.createdAt,
  });

  factory CompanySearchData.fromJson(Map<String, dynamic> json) {
    String? logo = json['logo']?.toString();
    if (logo != null && logo.isNotEmpty) {
      logo = _fixImageUrl(logo);
    }

    return CompanySearchData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      logo: logo,
      numberOfCompounds: json['number_of_compounds']?.toString() ?? '0',
      numberOfAvailableUnits: json['number_of_available_units']?.toString() ?? '0',
      compoundsCount: json['compounds_count']?.toString() ?? '0',
      createdAt: json['created_at']?.toString(),
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
        name,
        email,
        logo,
        numberOfCompounds,
        numberOfAvailableUnits,
        compoundsCount,
        createdAt,
      ];
}

class CompoundSearchData extends Equatable {
  final String id;
  final String name;
  final String location;
  final String status;
  final String completionProgress;
  final String unitsCount;
  final CompanyInfo company;
  final List<String> images;
  final String createdAt;

  CompoundSearchData({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.completionProgress,
    required this.unitsCount,
    required this.company,
    required this.images,
    required this.createdAt,
  });

  factory CompoundSearchData.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => _fixImageUrl(img.toString()))
          .toList();
    }

    return CompoundSearchData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      completionProgress: json['completion_progress']?.toString() ?? '0',
      unitsCount: json['units_count']?.toString() ?? '0',
      company: CompanyInfo.fromJson(json['company'] ?? {}),
      images: imagesList,
      createdAt: json['created_at']?.toString() ?? '',
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
        name,
        location,
        status,
        completionProgress,
        unitsCount,
        company,
        images,
        createdAt,
      ];
}

class UnitSearchData extends Equatable {
  final String id;
  final String name;
  final String code;
  final String unitType;
  final String usageType;
  final String? price;
  final String totalPrice;
  final bool available;
  final bool isSold;
  final String status;
  final String? numberOfBeds;
  final String? numberOfBaths;
  final String? area;
  final String? floor;
  final CompoundInfo compound;
  final List<String> images;
  // New fields from updated API
  final String? unitName;
  final String? unitCode;
  final String? originalPrice;
  final String? normalPrice;
  final String? discountedPrice;
  final String? discountPercentage;
  final bool hasActiveSale;
  final dynamic sale;

  UnitSearchData({
    required this.id,
    required this.name,
    required this.code,
    required this.unitType,
    required this.usageType,
    this.price,
    required this.totalPrice,
    required this.available,
    required this.isSold,
    required this.status,
    this.numberOfBeds,
    this.numberOfBaths,
    this.area,
    this.floor,
    required this.compound,
    required this.images,
    this.unitName,
    this.unitCode,
    this.originalPrice,
    this.normalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.hasActiveSale = false,
    this.sale,
  });

  factory UnitSearchData.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => _fixImageUrl(img.toString()))
          .toList();
    }

    return UnitSearchData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      unitType: json['unit_type']?.toString() ?? '',
      usageType: json['usage_type']?.toString() ?? '',
      price: json['price']?.toString(),
      totalPrice: json['total_price']?.toString() ?? json['total_pricing']?.toString() ?? json['price']?.toString() ?? '0',
      available: json['available'] == true || json['available']?.toString() == '1',
      isSold: json['is_sold'] == true || json['is_sold']?.toString() == '1',
      status: json['status']?.toString() ?? '',
      numberOfBeds: json['number_of_beds']?.toString() ?? json['bedrooms']?.toString(),
      numberOfBaths: json['number_of_baths']?.toString() ?? json['bathrooms']?.toString(),
      area: json['area']?.toString() ?? json['total_area']?.toString() ?? json['built_up_area']?.toString(),
      floor: json['floor']?.toString() ?? json['floor_number']?.toString(),
      compound: CompoundInfo.fromJson(json['compound'] ?? {}),
      images: imagesList,
      unitName: json['unit_name']?.toString(),
      unitCode: json['unit_code']?.toString(),
      originalPrice: json['original_price']?.toString(),
      normalPrice: json['normal_price']?.toString(),
      discountedPrice: json['discounted_price']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      hasActiveSale: json['has_active_sale'] == true || json['has_active_sale']?.toString() == '1' || json['has_active_sale']?.toString() == 'true',
      sale: json['sale'],
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
        name,
        code,
        unitType,
        usageType,
        price,
        totalPrice,
        available,
        isSold,
        status,
        numberOfBeds,
        numberOfBaths,
        area,
        floor,
        compound,
        images,
        unitName,
        unitCode,
        originalPrice,
        normalPrice,
        discountedPrice,
        discountPercentage,
        hasActiveSale,
        sale,
      ];
}

class CompanyInfo extends Equatable {
  final String id;
  final String name;
  final String? logo;

  CompanyInfo({
    required this.id,
    required this.name,
    this.logo,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    String? logo = json['logo']?.toString();
    if (logo != null && logo.isNotEmpty) {
      logo = _fixImageUrl(logo);
    }

    return CompanyInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: logo,
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
  List<Object?> get props => [id, name, logo];
}

class CompoundInfo extends Equatable {
  final String id;
  final String name;
  final String location;
  final CompanyInfo company;
  final List<String> images;

  CompoundInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.company,
    this.images = const [],
  });

  factory CompoundInfo.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => CompoundSearchData._fixImageUrl(img.toString()))
          .toList();
    }

    return CompoundInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      company: CompanyInfo.fromJson(json['company'] ?? {}),
      images: imagesList,
    );
  }

  @override
  List<Object?> get props => [id, name, location, company, images];
}
