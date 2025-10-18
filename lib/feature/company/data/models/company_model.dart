import 'dart:io' show Platform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sales_model.dart';

class CompanyCompound extends Equatable {
  final String id;
  final String name;
  final String project;
  final String location;
  final String status;
  final String? completionProgress;
  final List<String> images;

  const CompanyCompound({
    required this.id,
    required this.name,
    required this.project,
    required this.location,
    required this.status,
    this.completionProgress,
    this.images = const [],
  });

  factory CompanyCompound.fromJson(Map<String, dynamic> json) {
    // Parse images list
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => _fixImageUrl(img.toString()))
          .toList();
    }

    return CompanyCompound(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      completionProgress: json['completion_progress']?.toString(),
      images: imagesList,
    );
  }

  // Fix image URL to work on Android emulator
  static String _fixImageUrl(String url) {
    try {
      if (url.isEmpty) return url;

      // Check if it's a relative path (doesn't start with http:// or https://)
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Remove leading slash if present
        url = url.replaceFirst(RegExp(r'^/'), '');

        // Convert relative path to full URL
        // For Android emulator, use 10.0.2.2 to access host machine's localhost
        if (!kIsWeb && Platform.isAndroid) {
          url = 'http://10.0.2.2:8001/storage/$url';
        } else {
          url = 'http://127.0.0.1:8001/storage/$url';
        }
      }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project': project,
      'location': location,
      'status': status,
      'completion_progress': completionProgress,
      'images': images,
    };
  }

  @override
  List<Object?> get props => [id, name, project, location, status, completionProgress, images];
}

class Company extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String email;
  final String numberOfCompounds;
  final String numberOfAvailableUnits;
  final String createdAt;
  final List<Sales> sales;
  final int salesCount;
  final List<CompanyCompound> compounds;

  const Company({
    required this.id,
    required this.name,
    this.logo,
    required this.email,
    required this.numberOfCompounds,
    required this.numberOfAvailableUnits,
    required this.createdAt,
    this.sales = const [],
    this.salesCount = 0,
    this.compounds = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    String? logo = json['logo']?.toString();
    print('Company ${json['name']}: Original logo URL: $logo');

    // Fix logo URL for Android emulator (convert localhost to 10.0.2.2)
    if (logo != null && logo.isNotEmpty) {
      logo = _fixLogoUrl(logo);
      print('Company ${json['name']}: Fixed logo URL: $logo');
    }

    // Parse sales list
    List<Sales> salesList = [];
    if (json['sales'] != null && json['sales'] is List) {
      salesList = (json['sales'] as List)
          .map((salesJson) => Sales.fromJson(salesJson as Map<String, dynamic>))
          .toList();
    }

    // Parse compounds list
    List<CompanyCompound> compoundsList = [];
    if (json['compounds'] != null && json['compounds'] is List) {
      compoundsList = (json['compounds'] as List)
          .map((compoundJson) => CompanyCompound.fromJson(compoundJson as Map<String, dynamic>))
          .toList();
    }

    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: logo,
      email: json['email']?.toString() ?? '',
      numberOfCompounds: json['number_of_compounds']?.toString() ?? '0',
      numberOfAvailableUnits: json['number_of_available_units']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      sales: salesList,
      salesCount: int.tryParse(json['sales_count']?.toString() ?? '0') ?? 0,
      compounds: compoundsList,
    );
  }

  // Fix logo URL to work on Android emulator
  static String _fixLogoUrl(String url) {
    try {
      if (url.isEmpty) return url;

      // Check if it's a relative path (doesn't start with http:// or https://)
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Remove leading slash if present
        url = url.replaceFirst(RegExp(r'^/'), '');

        // Convert relative path to full URL
        // For Android emulator, use 10.0.2.2 to access host machine's localhost
        if (!kIsWeb && Platform.isAndroid) {
          url = 'http://10.0.2.2:8001/storage/$url';
        } else {
          url = 'http://127.0.0.1:8001/storage/$url';
        }
      }

      // First, fix Laravel storage path: remove /app/public from storage path
      // Laravel storage links point public/storage -> storage/app/public
      // So /storage/app/public/... should be /storage/...
      url = url.replaceAll('/storage/app/public/', '/storage/');

      final uri = Uri.parse(url);

      // If running on Android emulator, replace localhost or any IP with 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        // Replace localhost with 10.0.2.2 (preserve port)
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final port = uri.hasPort ? ':${uri.port}' : '';
          return url.replaceFirst(RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'), 'http://10.0.2.2$port');
        }
        // Replace any private IP address (192.168.x.x, 10.x.x.x) with 10.0.2.2 (preserve port)
        else if (uri.host.startsWith('192.168.') || uri.host.startsWith('10.')) {
          final port = uri.hasPort ? ':${uri.port}' : '';
          return url.replaceFirst(RegExp(r'https?://[0-9.]+(:\d+)?'), 'http://10.0.2.2$port');
        }
      }

      return url;
    } catch (e) {
      print('Error fixing logo URL: $e');
      return url;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'email': email,
      'number_of_compounds': numberOfCompounds,
      'number_of_available_units': numberOfAvailableUnits,
      'created_at': createdAt,
      'sales': sales.map((s) => s.toJson()).toList(),
      'sales_count': salesCount,
      'compounds': compounds.map((c) => c.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        logo,
        email,
        numberOfCompounds,
        numberOfAvailableUnits,
        createdAt,
        sales,
        salesCount,
        compounds,
      ];

  @override
  String toString() {
    return 'Company{id: $id, name: $name, logo: $logo, email: $email, numberOfCompounds: $numberOfCompounds, numberOfAvailableUnits: $numberOfAvailableUnits}';
  }
}
