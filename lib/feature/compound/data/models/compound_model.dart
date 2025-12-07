import 'package:equatable/equatable.dart';

import '../../../../core/locale/language_service.dart';
import '../../../../core/utils/constant.dart';
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
  final String? masterPlan;
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

  // Favorite fields
  final int? favoriteId;
  final String? notes;
  final int? noteId; // ID of the note in the notes table

  // Update tracking fields
  final int updatedUnitsCount;
  final String? latestUpdateNote;
  final String? latestUpdateTitle;
  final String? latestUpdateDate;

  /// Get full company logo URL with base URL prepended if needed
  String? get fullCompanyLogoUrl {
    if (companyLogo == null || companyLogo!.isEmpty) return null;

    // If already a full URL, return as-is
    if (companyLogo!.startsWith('http://') || companyLogo!.startsWith('https://')) {
      return companyLogo;
    }

    // Prepend base URL for relative paths
    final cleanPath = companyLogo!.startsWith('/') ? companyLogo!.substring(1) : companyLogo;
    return '$API_BASE/storage/$cleanPath';
  }

  Compound({
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
    this.masterPlan,
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
    required this.sales ,
    // Favorite fields
    this.favoriteId,
    this.notes,
    this.noteId,
    // Update tracking fields
    this.updatedUnitsCount = 0,
    this.latestUpdateNote,
    this.latestUpdateTitle,
    this.latestUpdateDate,
  });

  factory Compound.fromJson(Map<String, dynamic> json) {
    // Parse images array - prefer images_urls (full URLs) if available, otherwise use images
    List<String> imagesList = [];
    final imagesSource = json['images_urls'] ?? json['images'];
    if (imagesSource != null && imagesSource is List) {
      imagesList = (imagesSource as List)
          .map((img) => img.toString())
          .toList();
    }

    // Use company_logo_url (full URL) if available, otherwise fall back to company_logo
    String? companyLogo = json['company_logo_url']?.toString() ?? json['company_logo']?.toString();

    // Parse sales array
    List<Sales> salesList = [];
    if (json['sales'] != null && json['sales'] is List) {
      salesList = (json['sales'] as List)
          .map((sale) => Sales.fromJson(sale as Map<String, dynamic>))
          .toList();
    }

    // Get current language from LanguageService
    final currentLang = LanguageService.currentLanguage;

    // Determine project name based on language
    String projectName;
    if (json['project_localized'] != null) {
      // If backend sends project_localized, use it
      projectName = json['project_localized']?.toString() ?? '';
    } else if (json['project_en'] != null && json['project_ar'] != null) {
      // If backend sends project_en and project_ar separately
      projectName = currentLang == 'ar'
          ? (json['project_ar']?.toString() ?? json['project']?.toString() ?? '')
          : (json['project_en']?.toString() ?? json['project']?.toString() ?? '');
    } else {
      // Fallback to project field
      projectName = json['project']?.toString() ?? '';
    }

    // Determine location name based on language
    String locationName;
    if (json['location_localized'] != null) {
      // If backend sends location_localized, use it
      locationName = json['location_localized']?.toString() ?? '';
    } else if (json['location_en'] != null && json['location_ar'] != null) {
      // If backend sends location_en and location_ar separately
      locationName = currentLang == 'ar'
          ? (json['location_ar']?.toString() ?? json['location']?.toString() ?? '')
          : (json['location_en']?.toString() ?? json['location']?.toString() ?? '');
    } else {
      // Fallback to location field
      locationName = json['location']?.toString() ?? '';
    }

    return Compound(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      project: projectName,
      location: locationName,
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
      // Prefer master_plan_url (full URL) if available, otherwise use master_plan
      masterPlan: json['master_plan_url']?.toString() ?? json['master_plan']?.toString(),
      club: json['club']?.toString() ?? '0',
      isSold: json['is_sold']?.toString() ?? '0',
      // Use localized status if available, fallback to original
      status: json['status_localized']?.toString() ?? json['status']?.toString() ?? 'in_progress',
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
      // Favorite fields
      favoriteId: json['favorite_id'] as int?,
      notes: json['notes']?.toString(),
      noteId: json['note_id'] as int?,
      // Update tracking fields
      updatedUnitsCount: json['updated_units_count'] as int? ?? 0,
      latestUpdateNote: json['latest_update_note']?.toString(),
      latestUpdateTitle: json['latest_update_title']?.toString(),
      latestUpdateDate: json['latest_update_date']?.toString(),
    );
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
      'master_plan': masterPlan,
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
      // Favorite fields
      'favorite_id': favoriteId,
      'notes': notes,
      // Update tracking fields
      'updated_units_count': updatedUnitsCount,
      'latest_update_note': latestUpdateNote,
      'latest_update_title': latestUpdateTitle,
      'latest_update_date': latestUpdateDate,
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
        masterPlan,
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
        // Favorite fields
        favoriteId,
        notes,
        noteId,
        // Update tracking fields
        updatedUnitsCount,
        latestUpdateNote,
        latestUpdateTitle,
        latestUpdateDate,
      ];

  @override
  String toString() {
    return 'Compound{id: $id, project: $project, location: $location, companyName: $companyName, availableUnits: $availableUnits}';
  }
}
