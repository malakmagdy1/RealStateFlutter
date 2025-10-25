import 'package:equatable/equatable.dart';
import 'sales_model.dart';

class CompanyCompound extends Equatable {
  final String id;
  final String name;
  final String project;
  final String location;
  final String status;
  final String? completionProgress;
  final List<String> images;

  CompanyCompound({
    required this.id,
    required this.name,
    required this.project,
    required this.location,
    required this.status,
    this.completionProgress,
    required this.images,
  });

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
      location: json['location']?.toString() ?? '',
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

  Company({
    required this.id,
    required this.name,
    this.logo,
    required this.email,
    required this.numberOfCompounds,
    required this.numberOfAvailableUnits,
    required this.createdAt,
    required this.sales ,
    this.salesCount = 0,
    required this.compounds,
  });

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
