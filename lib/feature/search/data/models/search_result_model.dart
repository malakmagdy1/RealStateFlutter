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
      resultsList = (resultsData as List)
          .map((result) => SearchResult.fromJson(result as Map<String, dynamic>))
          .toList();
    }

    return SearchResponse(
      status: json['status'] ?? json['success'] ?? true,
      searchQuery: json['search_query'] ?? json['query'] ?? json['search'] ?? '',
      totalResults: int.tryParse(json['total_results']?.toString() ?? json['total']?.toString() ?? '0') ?? resultsList.length,
      results: resultsList,
    );
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
  final CompoundInfo compound;
  final List<String> images;

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
    required this.compound,
    required this.images,
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
      totalPrice: json['total_price']?.toString() ?? '0',
      available: json['available'] == true || json['available']?.toString() == '1',
      isSold: json['is_sold'] == true || json['is_sold']?.toString() == '1',
      status: json['status']?.toString() ?? '',
      numberOfBeds: json['number_of_beds']?.toString(),
      compound: CompoundInfo.fromJson(json['compound'] ?? {}),
      images: imagesList,
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
        compound,
        images,
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

  CompoundInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.company,
  });

  factory CompoundInfo.fromJson(Map<String, dynamic> json) {
    return CompoundInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      company: CompanyInfo.fromJson(json['company'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, name, location, company];
}
