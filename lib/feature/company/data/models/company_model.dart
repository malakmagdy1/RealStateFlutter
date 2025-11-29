import 'package:equatable/equatable.dart';
import 'sales_model.dart';

class CompanyCompound extends Equatable {
  final String id;
  final String name;
  final String project;
  final String projectEn;
  final String projectAr;
  final String location;
  final String locationEn;
  final String locationAr;
  final String status;
  final String? completionProgress;
  final List<String> images;

  CompanyCompound({
    required this.id,
    required this.name,
    required this.project,
    required this.projectEn,
    required this.projectAr,
    required this.location,
    required this.locationEn,
    required this.locationAr,
    required this.status,
    this.completionProgress,
    required this.images,
  });

  /// Get localized project name based on locale
  String getLocalizedProject(bool isArabic) {
    if (isArabic) {
      return projectAr.isNotEmpty ? projectAr : project;
    }
    return projectEn.isNotEmpty ? projectEn : project;
  }

  /// Get localized location based on locale
  String getLocalizedLocation(bool isArabic) {
    if (isArabic) {
      return locationAr.isNotEmpty ? locationAr : location;
    }
    return locationEn.isNotEmpty ? locationEn : location;
  }

  factory CompanyCompound.fromJson(Map<String, dynamic> json) {
    // Parse images list - store URLs as-is from API
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => img.toString())
          .toList();
    }

    return CompanyCompound(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      projectEn: json['project_en']?.toString() ?? json['project']?.toString() ?? '',
      projectAr: json['project_ar']?.toString() ?? json['project']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      locationEn: json['location_en']?.toString() ?? json['location']?.toString() ?? '',
      locationAr: json['location_ar']?.toString() ?? json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      completionProgress: json['completion_progress']?.toString(),
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project': project,
      'project_en': projectEn,
      'project_ar': projectAr,
      'location': location,
      'location_en': locationEn,
      'location_ar': locationAr,
      'status': status,
      'completion_progress': completionProgress,
      'images': images,
    };
  }

  @override
  List<Object?> get props => [id, name, project, projectEn, projectAr, location, locationEn, locationAr, status, completionProgress, images];
}

class Company extends Equatable {
  final String id;
  final String name;
  final String nameEn;
  final String nameAr;
  final String? logo;
  final String email;
  final String numberOfCompounds;
  final String numberOfAvailableUnits;
  final String createdAt;
  final List<Sales> sales;
  final int salesCount;
  final List<CompanyCompound> compounds;

  // Update tracking fields
  final int updatedUnitsCount;
  final String? latestUpdateNote;
  final String? latestUpdateTitle;
  final String? latestUpdateDate;

  Company({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameAr,
    this.logo,
    required this.email,
    required this.numberOfCompounds,
    required this.numberOfAvailableUnits,
    required this.createdAt,
    required this.sales,
    this.salesCount = 0,
    required this.compounds,
    // Update tracking fields
    this.updatedUnitsCount = 0,
    this.latestUpdateNote,
    this.latestUpdateTitle,
    this.latestUpdateDate,
  });

  /// Get localized company name based on locale
  String getLocalizedName(bool isArabic) {
    if (isArabic) {
      return nameAr.isNotEmpty ? nameAr : name;
    }
    return nameEn.isNotEmpty ? nameEn : name;
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    // Store logo URL as-is from API
    String? logo = json['logo']?.toString();

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
      // Use original name field as base
      name: json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      logo: logo,
      email: json['email']?.toString() ?? '',
      numberOfCompounds: json['number_of_compounds']?.toString() ?? '0',
      numberOfAvailableUnits: json['number_of_available_units']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      sales: salesList,
      salesCount: int.tryParse(json['sales_count']?.toString() ?? '0') ?? 0,
      compounds: compoundsList,
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
      'name': name,
      'name_en': nameEn,
      'name_ar': nameAr,
      'logo': logo,
      'email': email,
      'number_of_compounds': numberOfCompounds,
      'number_of_available_units': numberOfAvailableUnits,
      'created_at': createdAt,
      'sales': sales.map((s) => s.toJson()).toList(),
      'sales_count': salesCount,
      'compounds': compounds.map((c) => c.toJson()).toList(),
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
        name,
        nameEn,
        nameAr,
        logo,
        email,
        numberOfCompounds,
        numberOfAvailableUnits,
        createdAt,
        sales,
        salesCount,
        compounds,
        // Update tracking fields
        updatedUnitsCount,
        latestUpdateNote,
        latestUpdateTitle,
        latestUpdateDate,
      ];

  @override
  String toString() {
    return 'Company{id: $id, name: $name, nameEn: $nameEn, nameAr: $nameAr, logo: $logo, email: $email, numberOfCompounds: $numberOfCompounds, numberOfAvailableUnits: $numberOfAvailableUnits}';
  }
}
