/// Model for items to be compared (units, compounds, companies)
class ComparisonItem {
  final String id;
  final String name;
  final String type; // 'unit', 'compound', 'company'
  final Map<String, dynamic> data;

  ComparisonItem({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
  });

  factory ComparisonItem.fromJson(Map<String, dynamic> json) {
    return ComparisonItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'unit',
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'data': data,
    };
  }

  /// Create from Unit model
  factory ComparisonItem.fromUnit(dynamic unit) {
    return ComparisonItem(
      id: unit.id?.toString() ?? '',
      name: unit.unitNumber ?? unit.code ?? 'Unit',
      type: 'unit',
      data: {
        'area': unit.area,
        'price': unit.price,
        'bedrooms': unit.bedrooms,
        'bathrooms': unit.bathrooms,
        'compound_name': unit.compoundName,
        'company_name': unit.companyName,
        'finishing': unit.finishing,
        'status': unit.status,
        'floor': unit.floor,
        'view': unit.view,
      },
    );
  }

  /// Create from Compound model
  factory ComparisonItem.fromCompound(dynamic compound) {
    return ComparisonItem(
      id: compound.id?.toString() ?? '',
      name: compound.project ?? 'Compound',
      type: 'compound',
      data: {
        'location': compound.location,
        'company_name': compound.companyName,
        'units_count': compound.totalUnits,
        'available_units': compound.availableUnits,
        'status': compound.status,
      },
    );
  }

  /// Create from Company model
  factory ComparisonItem.fromCompany(dynamic company) {
    return ComparisonItem(
      id: company.id?.toString() ?? '',
      name: company.name ?? 'Company',
      type: 'company',
      data: {
        'number_of_compounds': company.numberOfCompounds,
        'number_of_units': company.numberOfUnits,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComparisonItem && other.id == id && other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
