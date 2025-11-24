/// Model for items to compare (Unit, Compound, or Company)
class ComparisonItem {
  final String id;
  final String type; // 'unit', 'compound', 'company'
  final String name;
  final Map<String, dynamic> data;

  ComparisonItem({
    required this.id,
    required this.type,
    required this.name,
    required this.data,
  });

  factory ComparisonItem.fromUnit(dynamic unit) {
    return ComparisonItem(
      id: unit.id?.toString() ?? '',
      type: 'unit',
      name: unit.unitNumber ?? unit.unitName ?? unit.name ?? 'Unit ${unit.id}',
      data: {
        'id': unit.id,
        'name': unit.unitNumber ?? unit.unitName ?? unit.name,
        'type': unit.unitType,
        'area': unit.area ?? unit.builtUpArea,
        'price': unit.price ?? unit.totalPrice ?? unit.normalPrice,
        'bedrooms': unit.bedrooms ?? unit.numberOfBeds,
        'bathrooms': unit.bathrooms ?? unit.numberOfBaths,
        'compound_name': unit.compoundName,
        'company_name': unit.companyName,
        'location': unit.compoundLocation,
        'status': unit.status,
        'available': unit.available,
        'finishing': unit.finishing,
        'garden_area': unit.gardenArea,
        'roof_area': unit.roofArea,
        'floor': unit.floor ?? unit.floorNumber,
        'has_active_sale': unit.hasActiveSale,
        'discount_percentage': unit.discountPercentage,
        'original_price': unit.originalPrice,
        'discounted_price': unit.discountedPrice,
      },
    );
  }

  factory ComparisonItem.fromCompound(dynamic compound) {
    return ComparisonItem(
      id: compound.id?.toString() ?? '',
      type: 'compound',
      name: compound.project ?? 'Compound ${compound.id}',
      data: {
        'id': compound.id,
        'name': compound.project,
        'location': compound.location,
        'company_name': compound.companyName,
        'status': compound.status,
        'units_count': compound.totalUnits,
        'available_units': compound.availableUnits,
        'sold_units': compound.soldUnits,
        'completion_progress': compound.completionProgress,
        'has_sales': compound.sales?.isNotEmpty ?? false,
        'description': compound.finishSpecs,
        'built_up_area': compound.builtUpArea,
        'floors': compound.howManyFloors,
        'club': compound.club,
      },
    );
  }

  factory ComparisonItem.fromCompany(dynamic company) {
    return ComparisonItem(
      id: company.id?.toString() ?? '',
      type: 'company',
      name: company.name ?? 'Company ${company.id}',
      data: {
        'id': company.id,
        'name': company.name,
        'email': company.email,
        'phone': company.phone,
        'number_of_compounds': company.numberOfCompounds ?? company.compoundsCount,
        'number_of_units': company.numberOfAvailableUnits ?? company.unitsCount,
        'description': company.description,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'data': data,
    };
  }

  factory ComparisonItem.fromJson(Map<String, dynamic> json) {
    return ComparisonItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
}
