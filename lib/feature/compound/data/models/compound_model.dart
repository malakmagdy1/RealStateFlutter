import 'dart:io' show Platform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../company/data/models/sales_model.dart';

class Compound extends Equatable {
  final String id;
  final String companyId;
  final String project;
  final String location;
  final String? locationUrl;
  final List<String> images;
  final String builtUpArea;
  final String howManyFloors;
  final String? plannedDeliveryDate;
  final String? actualDeliveryDate;
  final String? completionProgress;
  final String? landArea;
  final String? builtArea;
  final String? finishSpecs;
  final String club;
  final String isSold;
  final String status;
  final String? deliveredAt;
  final String totalUnits;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String companyName;
  final String? companyLogo;
  final String soldUnits;
  final String availableUnits;
  final List<Sales> sales;

  const Compound({
    required this.id,
    required this.companyId,
    required this.project,
    required this.location,
    this.locationUrl,
    required this.images,
    required this.builtUpArea,
    required this.howManyFloors,
    this.plannedDeliveryDate,
    this.actualDeliveryDate,
    this.completionProgress,
    this.landArea,
    this.builtArea,
    this.finishSpecs,
    required this.club,
    required this.isSold,
    required this.status,
    this.deliveredAt,
    required this.totalUnits,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.companyName,
    this.companyLogo,
    required this.soldUnits,
    required this.availableUnits,
    this.sales = const [],
  });

  factory Compound.fromJson(Map<String, dynamic> json) {
    // Parse images array
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) {
            final originalUrl = img.toString();
            final fixedUrl = _fixImageUrl(originalUrl);
            print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
            print('[IMAGE URL] Original: $originalUrl');
            print('[IMAGE URL] Fixed: $fixedUrl');
            print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
            return fixedUrl;
          })
          .toList();
    }

    // Fix company logo URL
    String? companyLogo = json['company_logo']?.toString();
    if (companyLogo != null && companyLogo.isNotEmpty) {
      companyLogo = _fixImageUrl(companyLogo);
    }

    // Parse sales array
    List<Sales> salesList = [];
    if (json['sales'] != null && json['sales'] is List) {
      salesList = (json['sales'] as List)
          .map((sale) => Sales.fromJson(sale as Map<String, dynamic>))
          .toList();
    }

    return Compound(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      locationUrl: json['location_url']?.toString(),
      images: imagesList,
      builtUpArea: json['built_up_area']?.toString() ?? '0.00',
      howManyFloors: json['how_many_floors']?.toString() ?? '0',
      plannedDeliveryDate: json['planned_delivery_date']?.toString(),
      actualDeliveryDate: json['actual_delivery_date']?.toString(),
      completionProgress: json['completion_progress']?.toString(),
      landArea: json['land_area']?.toString(),
      builtArea: json['built_area']?.toString(),
      finishSpecs: json['finish_specs']?.toString(),
      club: json['club']?.toString() ?? '0',
      isSold: json['is_sold']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'in_progress',
      deliveredAt: json['delivered_at']?.toString(),
      totalUnits: json['total_units']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      companyName: json['company_name']?.toString() ?? '',
      companyLogo: companyLogo,
      soldUnits: json['sold_units']?.toString() ?? '0',
      availableUnits: json['available_units']?.toString() ?? '0',
      sales: salesList,
    );
  }

  // Fix image URL to work on Android emulator
  static String _fixImageUrl(String url) {
    try {
      // If URL is empty or null, return as is
      if (url.isEmpty) return url;

      // Check if it's a relative path (doesn't start with http:// or https://)
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Remove leading slash if present
        url = url.replaceFirst(RegExp(r'^/'), '');

        // Convert relative path to full URL
        // Base URL for images on your server
        const String baseUrl = 'http://192.168.1.225/larvel2';
        url = '$baseUrl/$url';
      }

      // First, fix Laravel storage path: remove /app/public from storage path
      url = url.replaceAll('/storage/app/public/', '/storage/');

      final uri = Uri.parse(url);

      // If running on Android emulator, replace localhost or any IP with 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        // Replace localhost with 10.0.2.2
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return url.replaceFirst(RegExp(r'https?://localhost'), 'http://10.0.2.2')
                    .replaceFirst(RegExp(r'https?://127\.0\.0\.1'), 'http://10.0.2.2');
        }
        // Replace any private IP address (192.168.x.x, 10.x.x.x) with 10.0.2.2
        else if (uri.host.startsWith('192.168.') || uri.host.startsWith('10.')) {
          return url.replaceFirst(RegExp(r'https?://[0-9.]+'), 'http://10.0.2.2');
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
      'company_id': companyId,
      'project': project,
      'location': location,
      'location_url': locationUrl,
      'images': images,
      'built_up_area': builtUpArea,
      'how_many_floors': howManyFloors,
      'planned_delivery_date': plannedDeliveryDate,
      'actual_delivery_date': actualDeliveryDate,
      'completion_progress': completionProgress,
      'land_area': landArea,
      'built_area': builtArea,
      'finish_specs': finishSpecs,
      'club': club,
      'is_sold': isSold,
      'status': status,
      'delivered_at': deliveredAt,
      'total_units': totalUnits,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'company_name': companyName,
      'company_logo': companyLogo,
      'sold_units': soldUnits,
      'available_units': availableUnits,
      'sales': sales.map((sale) => sale.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        project,
        location,
        locationUrl,
        images,
        builtUpArea,
        howManyFloors,
        plannedDeliveryDate,
        actualDeliveryDate,
        completionProgress,
        landArea,
        builtArea,
        finishSpecs,
        club,
        isSold,
        status,
        deliveredAt,
        totalUnits,
        createdAt,
        updatedAt,
        deletedAt,
        companyName,
        companyLogo,
        soldUnits,
        availableUnits,
        sales,
      ];

  @override
  String toString() {
    return 'Compound{id: $id, project: $project, location: $location, companyName: $companyName, availableUnits: $availableUnits}';
  }
}
