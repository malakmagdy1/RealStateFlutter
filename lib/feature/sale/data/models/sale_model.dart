import 'package:equatable/equatable.dart';

class SalesPerson extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? image;

  const SalesPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.image,
  });

  factory SalesPerson.fromJson(Map<String, dynamic> json) {
    return SalesPerson(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
    };
  }

  @override
  List<Object?> get props => [id, name, email, phone, image];
}

class Sale extends Equatable {
  final String id;
  final String companyId;
  final String companyName;
  final String? companyLogo;
  final SalesPerson? salesPerson;
  final String saleType;
  final String? unitId;
  final String? compoundId;
  final String itemName;
  final String compoundName;
  final String saleName;
  final String description;
  final double discountPercentage;
  final double oldPrice;
  final double newPrice;
  final double savings;
  final String startDate;
  final String endDate;
  final bool isActive;
  final bool isCurrentlyActive;
  final double daysRemaining;
  final List<String> images;
  final String createdAt;
  final String updatedAt;

  const Sale({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    this.salesPerson,
    required this.saleType,
    this.unitId,
    this.compoundId,
    required this.itemName,
    required this.compoundName,
    required this.saleName,
    required this.description,
    required this.discountPercentage,
    required this.oldPrice,
    required this.newPrice,
    required this.savings,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isCurrentlyActive,
    required this.daysRemaining,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Parse images
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) => img.toString())
          .toList();
    }

    // Parse sales person
    SalesPerson? salesPerson;
    if (json['sales_person'] != null && json['sales_person'] is Map) {
      salesPerson = SalesPerson.fromJson(json['sales_person'] as Map<String, dynamic>);
    }

    return Sale(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      companyLogo: json['company_logo']?.toString(),
      salesPerson: salesPerson,
      saleType: json['sale_type']?.toString() ?? '',
      unitId: json['unit_id']?.toString(),
      compoundId: json['compound_id']?.toString(),
      itemName: json['item_name']?.toString() ?? '',
      compoundName: json['compound_name']?.toString() ?? '',
      saleName: json['sale_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountPercentage: (json['discount_percentage'] is num)
          ? (json['discount_percentage'] as num).toDouble()
          : double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0.0,
      oldPrice: (json['old_price'] is num)
          ? (json['old_price'] as num).toDouble()
          : double.tryParse(json['old_price']?.toString() ?? '0') ?? 0.0,
      newPrice: (json['new_price'] is num)
          ? (json['new_price'] as num).toDouble()
          : double.tryParse(json['new_price']?.toString() ?? '0') ?? 0.0,
      savings: (json['savings'] is num)
          ? (json['savings'] as num).toDouble()
          : double.tryParse(json['savings']?.toString() ?? '0') ?? 0.0,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isCurrentlyActive: json['is_currently_active'] == true || json['is_currently_active'] == 1,
      daysRemaining: (json['days_remaining'] is num)
          ? (json['days_remaining'] as num).toDouble()
          : double.tryParse(json['days_remaining']?.toString() ?? '0') ?? 0.0,
      images: imagesList,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'sales_person': salesPerson?.toJson(),
      'sale_type': saleType,
      'unit_id': unitId,
      'compound_id': compoundId,
      'item_name': itemName,
      'compound_name': compoundName,
      'sale_name': saleName,
      'description': description,
      'discount_percentage': discountPercentage,
      'old_price': oldPrice,
      'new_price': newPrice,
      'savings': savings,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'is_currently_active': isCurrentlyActive,
      'days_remaining': daysRemaining,
      'images': images,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        companyLogo,
        salesPerson,
        saleType,
        unitId,
        compoundId,
        itemName,
        compoundName,
        saleName,
        description,
        discountPercentage,
        oldPrice,
        newPrice,
        savings,
        startDate,
        endDate,
        isActive,
        isCurrentlyActive,
        daysRemaining,
        images,
        createdAt,
        updatedAt,
      ];
}

class SaleResponse extends Equatable {
  final bool success;
  final int totalSales;
  final int page;
  final int limit;
  final int totalPages;
  final List<Sale> sales;

  const SaleResponse({
    required this.success,
    required this.totalSales,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.sales,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) {
    List<Sale> salesList = [];
    if (json['sales'] != null && json['sales'] is List) {
      salesList = (json['sales'] as List)
          .map((sale) => Sale.fromJson(sale as Map<String, dynamic>))
          .toList();
    }

    return SaleResponse(
      success: json['success'] == true,
      totalSales: json['total_sales'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      sales: salesList,
    );
  }

  @override
  List<Object?> get props => [success, totalSales, page, limit, totalPages, sales];
}
