import 'package:equatable/equatable.dart';
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
  });

  factory Compound.fromJson(Map<String, dynamic> json) {
    // Parse images array - store URLs as-is from API
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => img.toString())
          .toList();

      print('================================');
      print('[COMPOUND MODEL] Compound: ${json['project']}');
      print('[COMPOUND MODEL] Total images from API: ${imagesList.length}');
      for (int i = 0; i < imagesList.length; i++) {
        print('[COMPOUND MODEL] Image $i: ${imagesList[i]}');
      }
      print('================================');
    }

    // Store company logo URL as-is from API
    String? companyLogo = json['company_logo']?.toString();

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
      // Use localized project name if available, fallback to original
      project: json['project_localized']?.toString() ?? json['project']?.toString() ?? '',
      // Use localized location if available, fallback to original
      location: json['location_localized']?.toString() ?? json['location']?.toString() ?? '',
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
      masterPlan: json['master_plan']?.toString(),
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
      ];

  @override
  String toString() {
    return 'Compound{id: $id, project: $project, location: $location, companyName: $companyName, availableUnits: $availableUnits}';
  }
}
